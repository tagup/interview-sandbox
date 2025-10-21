-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW()
);

-- Trigger to auto-update "updated" column
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_users_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();


-- Create transactions table
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DOUBLE PRECISION,
    currency VARCHAR(3),
    subid VARCHAR(50),
    pending BOOLEAN DEFAULT TRUE,
    paid BOOLEAN DEFAULT FALSE,
    created TIMESTAMP DEFAULT NOW(),
    updated TIMESTAMP DEFAULT NOW()
);

CREATE TRIGGER trg_update_transactions_timestamp
BEFORE UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();


-- Function to generate transaction IDs
CREATE OR REPLACE FUNCTION generate_transaction_id()
RETURNS TEXT AS $$
BEGIN
    RETURN CONCAT(EXTRACT(EPOCH FROM NOW())::BIGINT, '-', gen_random_uuid()::TEXT);
END;
$$ LANGUAGE plpgsql;


-- BEFORE INSERT trigger to populate transaction ID if not provided
CREATE OR REPLACE FUNCTION before_insert_transactions()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IS NULL THEN
        NEW.id := generate_transaction_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_before_insert_transactions
BEFORE INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION before_insert_transactions();


-- Insert 15 random users (ignore duplicates)
INSERT INTO users (email)
SELECT CONCAT('user', n, '@example.com')
FROM generate_series(1, 15) AS s(n)
ON CONFLICT (email) DO NOTHING;


-- Randomize created dates
UPDATE users
SET created = NOW() - ((FLOOR(RANDOM() * 90) + 390) * INTERVAL '1 day');


-- Stored procedure to generate random transactions
CREATE OR REPLACE PROCEDURE generate_random_transactions(
    start_date TIMESTAMP,
    end_date TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    days_range INT;
    total_transactions INT;
    i INT := 0;
    random_date TIMESTAMP;
BEGIN
    SELECT EXTRACT(DAY FROM (end_date - start_date)) INTO days_range;
    total_transactions := days_range * 50;

    WHILE i < total_transactions LOOP
        random_date := start_date + (RANDOM() * (end_date - start_date));

        INSERT INTO transactions (id, user_id, amount, currency, subid, pending, paid, created)
        VALUES (
            generate_transaction_id(),
            (SELECT id FROM users ORDER BY RANDOM() LIMIT 1),
            ROUND((RANDOM() * 1000)::DECIMAL, 2),
            'USD',
            gen_random_uuid()::TEXT,
            FALSE,
            (RANDOM() < 0.9),
            random_date
        );

        i := i + 1;
    END LOOP;
END;
$$;


-- Equivalent of MySQL events (requires pg_cron or external scheduling)
-- You can schedule these using pg_cron like:
-- SELECT cron.schedule('*/2 * * * *', 'CALL create_random_transactions();');

-- Create procedure to randomly create new transactions
CREATE OR REPLACE PROCEDURE create_random_transactions()
LANGUAGE plpgsql
AS $$
DECLARE
    i INT := 0;
    num_transactions INT;
BEGIN
    num_transactions := FLOOR(1 + RANDOM() * 30);

    WHILE i < num_transactions LOOP
        INSERT INTO transactions (id, user_id, amount, currency, subid, pending, paid, created)
        VALUES (
            generate_transaction_id(),
            (SELECT id FROM users ORDER BY RANDOM() LIMIT 1),
            ROUND((RANDOM() * 1000)::DECIMAL, 2),
            'USD',
            gen_random_uuid()::TEXT,
            TRUE,
            FALSE,
            NOW()
        );
        i := i + 1;
    END LOOP;
END;
$$;


-- Create procedure to confirm or pay random transactions
CREATE OR REPLACE PROCEDURE confirm_or_pay_transactions()
LANGUAGE plpgsql
AS $$
DECLARE
    num_updates INT;
    rand_days INT;
BEGIN
    num_updates := FLOOR(1 + RANDOM() * 25);
    rand_days := CASE WHEN RANDOM() < 0.5 THEN 30 ELSE FLOOR(RANDOM() * 100 + 31) END;

    UPDATE transactions
    SET pending = FALSE,
        paid = (RANDOM() < 0.5)
    WHERE id IN (
        SELECT id FROM transactions
        WHERE created >= NOW() - (rand_days * INTERVAL '1 day')
        ORDER BY RANDOM()
        LIMIT num_updates
    );
END;
$$;


CALL generate_random_transactions(CURRENT_DATE - INTERVAL '365 days', CURRENT_DATE);

SELECT cron.schedule_in_database(
    'create_random_transactions',
    '*/2 * * * *',
    $$CALL create_random_transactions();$$,
    'sandbox'
);

SELECT cron.schedule_in_database(
    'confirm_or_pay_transactions',
    '*/2 * * * *',
    $$CALL confirm_or_pay_transactions();$$,
    'sandbox'
)
