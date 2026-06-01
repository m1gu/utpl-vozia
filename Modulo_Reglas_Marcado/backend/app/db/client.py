import httpx

from app.config import settings


class PostgrestError(Exception):
    pass


def _headers() -> dict[str, str]:
    return {
        "apikey": settings.supabase_anon_key,
        "Authorization": f"Bearer {settings.supabase_anon_key}",
        "Content-Type": "application/json",
    }


def _table_url(table: str) -> str:
    return f"{settings.supabase_url}/rest/v1/{table}"


async def _request(
    method: str,
    table: str,
    *,
    params: dict | None = None,
    json: dict | list[dict] | None = None,
    headers_extra: dict | None = None,
) -> dict | list[dict]:
    url = _table_url(table)
    h = _headers()
    if headers_extra:
        h.update(headers_extra)

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.request(method, url, headers=h, params=params, json=json)

    if not resp.is_success:
        detail = resp.text[:500]
        raise PostgrestError(f"{resp.status_code} {resp.reason_phrase}: {detail}")

    return resp.json() if resp.text else {}


async def select(
    table: str,
    *,
    columns: str = "*",
    filters: dict | None = None,
    order: str | None = None,
    limit: int | None = None,
    offset: int | None = None,
) -> list[dict]:
    params: dict = {"select": columns}
    if order:
        params["order"] = order
    if limit is not None:
        params["limit"] = str(limit)
    if offset is not None:
        params["offset"] = str(offset)
    if filters:
        for key, value in filters.items():
            params[key] = value

    return await _request("GET", table, params=params)


async def select_one(
    table: str,
    filters: dict,
    *,
    columns: str = "*",
) -> dict | None:
    rows = await select(table, columns=columns, filters=filters, limit=1)
    return rows[0] if rows else None


async def insert(table: str, data: dict) -> dict:
    headers = {"Prefer": "return=representation"}
    result = await _request("POST", table, json=data, headers_extra=headers)
    return result if isinstance(result, dict) else result[0] if result else {}


async def update(table: str, filters: dict, data: dict) -> dict | None:
    params: dict = dict(filters)
    headers = {"Prefer": "return=representation"}
    result = await _request("PATCH", table, json=data, params=params, headers_extra=headers)
    if isinstance(result, list) and result:
        return result[0]
    return result if isinstance(result, dict) else None


async def upsert(table: str, data: list[dict], on_conflict: str) -> list[dict]:
    headers = {
        "Prefer": "return=representation,resolution=merge-duplicates",
    }
    params = {"on_conflict": on_conflict}
    result = await _request("POST", table, json=data, params=params, headers_extra=headers)
    return result if isinstance(result, list) else [result] if result else []


async def delete(table: str, filters: dict) -> None:
    params: dict = dict(filters)
    await _request("DELETE", table, params=params)
