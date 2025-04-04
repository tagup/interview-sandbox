-- Create users table
CREATE TABLE users (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create transactions table
CREATE TABLE transactions (
    id VARCHAR(255) NOT NULL PRIMARY KEY,
    user_id INT NOT NULL,
    amount DOUBLE,
    currency VARCHAR(3),
    subid VARCHAR(50),
    pending BOOLEAN DEFAULT 1,
    paid BOOLEAN DEFAULT 0,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create trigger to generate id in transactions
DELIMITER //
CREATE TRIGGER before_insert_transactions
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    SET NEW.id = CONCAT(UNIX_TIMESTAMP(NOW()), '-', UUID());
END;
//
DELIMITER ;

-- Enable event scheduler
SET GLOBAL event_scheduler = ON;

-- Insert 15 random users (use INSERT IGNORE to avoid errors on duplicate emails)
INSERT IGNORE INTO users (email)
SELECT CONCAT('user', n, '@example.com')
FROM (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
) AS numbers;

-- Change the created date
UPDATE users
SET created = DATE_SUB(
NOW(),
INTERVAL FLOOR(RAND() * (90) + 390) DAY
);

DELIMITER //

DELIMITER //

CREATE PROCEDURE generate_random_transactions(
    IN start_date DATETIME,
    IN end_date DATETIME
)
BEGIN
    DECLARE days_range INT;
    DECLARE total_transactions INT;
    DECLARE i INT DEFAULT 0;
    DECLARE random_date DATETIME;

    -- Calculate the total number of days
    SET days_range = DATEDIFF(end_date, start_date);

    -- Total transactions = 50 transactions per day * number of days
    SET total_transactions = days_range * 50;

    WHILE i < total_transactions DO
        -- Generate a random timestamp within the given date range
        SET random_date = DATE_ADD(start_date, INTERVAL FLOOR(RAND() * days_range * 24 * 60 * 60) SECOND);

        -- Insert transaction with a random user ID
        INSERT INTO transactions (id, user_id, amount, currency, subid, pending, paid, created)
        VALUES (
            CONCAT(UNIX_TIMESTAMP(random_date), '-', UUID()), -- Generate time-based UUID
            (SELECT id FROM users ORDER BY RAND() LIMIT 1), -- Assign to a random user
            ROUND(RAND() * 1000, 2), -- Random amount between 0 and 1000
            'USD', -- Currency
            UUID(), -- Random subid
            0, -- Not pending
            IF(RAND() < 0.9, 1, 0), -- 90% paid, 10% unpaid
            random_date -- Randomized timestamp
        );

        SET i = i + 1;
    END WHILE;
END;
//

DELIMITER ;

-- Create event to generate random transactions every 2 minutes
DELIMITER //
CREATE EVENT create_random_transactions
ON SCHEDULE EVERY 2 MINUTE
DO
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE num_transactions INT;
    
    -- Generate a random number of transactions (between 1 and 30)
    SET num_transactions = FLOOR(1 + RAND() * 30);

    WHILE i < num_transactions DO
        INSERT INTO transactions (id, user_id, amount, currency, subid, pending, paid, created)
        VALUES (
            CONCAT(UNIX_TIMESTAMP(NOW()), '-', UUID()), -- Generate time-based UUID
            (SELECT id FROM users ORDER BY RAND() LIMIT 1), -- Ensure a valid random user
            ROUND(RAND() * 1000, 2), -- Random amount between 0 and 1000
            'USD', -- Currency
            UUID(), -- Unique subid
            1, -- Pending
            0, -- Not paid
            NOW()
        );
        SET i = i + 1;
    END WHILE;
END;
//
DELIMITER ;

-- Create event to confirm or pay random transactions every 2 minutes
DELIMITER //
CREATE EVENT confirm_or_pay_transactions
ON SCHEDULE EVERY 2 MINUTE
DO
BEGIN
    DECLARE num_updates INT;
    DECLARE rand_days INT;

    -- Generate a random number of transactions to update (between 1 and 25)
    SET num_updates = FLOOR(1 + RAND() * 25);

    -- Randomly pick transactions from either within the last 30 days or older
    SET rand_days = IF(RAND() < 0.5, 30, FLOOR(RAND() * 100 + 31)); 

    -- Update selected transactions
    UPDATE transactions
    SET pending = 0, paid = IF(RAND() < 0.5, 1, 0)
    WHERE id IN (
        SELECT id FROM transactions
        WHERE created >= NOW() - INTERVAL rand_days DAY
        ORDER BY RAND()
        LIMIT num_updates
    );
END;
//
DELIMITER ;