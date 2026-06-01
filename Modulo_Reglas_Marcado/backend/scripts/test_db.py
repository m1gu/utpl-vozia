import asyncio
from app.db.client import select

async def test():
    rows = await select("dialing_campaigns", order="name.asc")
    print(f"Campaigns: {len(rows)}")
    for r in rows:
        print(f'  - {r["name"]} ({r["slug"]})')

    cid = rows[0]["id"]
    rules = await select("dialing_motive_rules", filters={"campaign_id": f"eq.{cid}"}, order="sort_order.asc")
    print(f"Rules: {len(rules)}")
    for r in rules:
        print(f'  - {r["motive"]}: {r["action"]}/{r["phone_strategy"]}/{r["wait_minutes"]}min')

    windows = await select("dialing_windows", filters={"campaign_id": f"eq.{cid}"}, order="sort_order.asc")
    print(f"Windows: {len(windows)}")
    for w in windows:
        print(f'  - {w["name"]}: {w["days_csv"]} {w["start_time"]}-{w["end_time"]}')

    holidays = await select("dialing_holidays", filters={"campaign_id": f"eq.{cid}"})
    print(f"Holidays: {len(holidays)}")
    for h in holidays:
        print(f'  - {h["holiday_date"]}: {h.get("description","")}')

asyncio.run(test())
