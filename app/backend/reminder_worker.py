import asyncio
from reminder_service import start_reminder_loop

if __name__ == "__main__":
    asyncio.run(start_reminder_loop())
