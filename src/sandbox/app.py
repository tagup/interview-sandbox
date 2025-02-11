import sqlalchemy
import uvicorn
from fastapi import FastAPI
from starlette.requests import Request

from sandbox.settings import DatabaseSettings

app = FastAPI()

@app.middleware("http")
async def open_connection(request: Request, call_next):
    s = DatabaseSettings()
    uri = (
        f"mysql+pymysql://"
        f"{s.user.get_secret_value()}:"
        f"{s.password.get_secret_value()}@"
        f"{s.host.get_secret_value()}:"
        f"{s.port.get_secret_value()}/{s.database_name}"
    )
    with sqlalchemy.create_engine(uri).connect() as connection:
        request.state.connection = connection
        return await call_next(request)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
