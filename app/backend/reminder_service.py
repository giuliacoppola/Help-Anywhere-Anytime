import asyncio
from supabase import create_client
from datetime import datetime
import os
from dotenv import load_dotenv
from pathlib import Path

load_dotenv(dotenv_path=Path(__file__).parent / ".env")

supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

async def start_reminder_loop():
    print("🟢 Reminder Worker started")

    while True:
        try:
            await asyncio.to_thread(_check_reminders)
            await asyncio.sleep(60)
        except Exception as e:
            print("⚠️ Reminder error:", e)
            await asyncio.sleep(60)

def _check_reminders():
    now = datetime.now()
    now_str = now.strftime("%H:%M")

    response = supabase.table("medications").select("*").execute()
    meds = response.data

    for med in meds:
        hour = med.get("hour")
        if not hour:
            continue

        if hour[:5] != now_str:
            continue

        handled = med.get("handled")

        if handled:
            handled_date = datetime.fromisoformat(handled)
            if handled_date.date() == now.date():
                continue  # già fatto oggi

        text = f"Devi prendere {med.get('quantity','una')} dose di {med['name']}"

        # 1️⃣ crea alert
        supabase.table("alerts").insert({
            "patient_id": med["patient_id"],
            "intent": "REMINDER",
            "ai_response": text,
            "is_read": False
        }).execute()

        # 2️⃣ aggiorna handled
        supabase.table("medications").update({
            "handled": now.isoformat()
        }).eq("id", med["id"]).execute()

        print("⏰ Reminder creato:", text)
