from fastapi import WebSocket, WebSocketDisconnect, APIRouter
import asyncio
import json
from stt_engine import StreamingSTT
router=APIRouter()
@router.websocket("/ws/stt")
async def ws_stt(ws: WebSocket):
    await ws.accept()
    stt = StreamingSTT(input_sample_rate=48000, debug=True)

    await ws.send_text(json.dumps({"type": "ready"}))
    print("🟢 WS connected")

    try:
        while True:
            msg = await ws.receive()
            if msg["type"] == "websocket.disconnect":
                print("🔴 Client disconnected")
                break
            if msg["type"] == "websocket.receive":
                if "bytes" in msg and msg["bytes"]:
                    for etype, payload in stt.push_audio(msg["bytes"]):
                        print("➡️ emit", etype, payload)
                        await ws.send_text(json.dumps({"type": etype, **payload}))

    except WebSocketDisconnect:
        print("🔴 WS client disconnected")

    except Exception as e:
        print("🔴 WS error:", e)

    finally:
        print("🔴 WS closed")
