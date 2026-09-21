import asyncio
import os
import azure.cognitiveservices.speech as speechsdk


class AzureStreamingSTT:
    """
    Streaming STT con PushAudioInputStream.
    Input atteso: PCM 16-bit little-endian, 16kHz, mono (raw bytes).
    Output: eventi di testo (parziali/finali) su una asyncio.Queue.
    """

    def __init__(self, key: str, region: str, language: str = "it-IT"):
        self.key = key
        self.region = region
        self.language = language

        self._loop = asyncio.get_event_loop()
        self.queue: asyncio.Queue[dict] = asyncio.Queue()

        self._push_stream = None
        self._recognizer = None

    def start(self) -> None:
        speech_config = speechsdk.SpeechConfig(subscription=self.key, region=self.region)
        speech_config.speech_recognition_language = self.language

        # Definisci il formato audio: PCM 16kHz mono 16-bit
        audio_format = speechsdk.audio.AudioStreamFormat(samples_per_second=16000, bits_per_sample=16, channels=1)

        self._push_stream = speechsdk.audio.PushAudioInputStream(stream_format=audio_format)
        audio_config = speechsdk.audio.AudioConfig(stream=self._push_stream)

        self._recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)

        # Eventi: parziale (recognizing) e finale (recognized)
        self._recognizer.recognizing.connect(self._on_recognizing)
        self._recognizer.recognized.connect(self._on_recognized)
        self._recognizer.canceled.connect(self._on_canceled)
        self._recognizer.session_stopped.connect(self._on_session_stopped)

        self._recognizer.start_continuous_recognition()

    def push_audio(self, data: bytes) -> None:
        if self._push_stream is not None:
            self._push_stream.write(data)

    def stop(self) -> None:
        try:
            if self._push_stream is not None:
                self._push_stream.close()
        except Exception:
            pass

        try:
            if self._recognizer is not None:
                self._recognizer.stop_continuous_recognition()
        except Exception:
            pass

    # --------- callbacks Azure -> queue async ---------

    def _enqueue_threadsafe(self, payload: dict) -> None:
        # I callback di Azure arrivano su thread diversi: inseriamo in coda in modo thread-safe
        asyncio.run_coroutine_threadsafe(self.queue.put(payload), self._loop)

    def _on_recognizing(self, evt: speechsdk.SpeechRecognitionEventArgs) -> None:
        text = (evt.result.text or "").strip()
        if text:
            self._enqueue_threadsafe({"type": "partial", "text": text})

    def _on_recognized(self, evt: speechsdk.SpeechRecognitionEventArgs) -> None:
        # Solo se c'è testo finale
        text = (evt.result.text or "").strip()
        if text:
            self._enqueue_threadsafe({"type": "final", "text": text})

    def _on_canceled(self, evt: speechsdk.SpeechRecognitionCanceledEventArgs) -> None:
        self._enqueue_threadsafe({"type": "error", "text": str(evt)})

    def _on_session_stopped(self, evt) -> None:
        self._enqueue_threadsafe({"type": "stopped", "text": "session_stopped"})
