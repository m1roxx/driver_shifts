import psycopg


async def test_connects_to_postgres_18(database_url: str) -> None:
    async with await psycopg.AsyncConnection.connect(database_url) as connection:
        cursor = await connection.execute("SELECT current_setting('server_version_num')::int")
        row = await cursor.fetchone()

    assert row is not None
    assert row[0] // 10_000 == 18
