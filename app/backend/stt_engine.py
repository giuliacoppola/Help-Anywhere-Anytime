import io
import time
import wave
import numpy as np
from collections import deque
from scipy.signal import resample_poly
from faster_whisper import WhisperModel


class StreamingSTT:
    def __init__(
            self,
            input_sample_rate=48000,
            target_sample_rate=16000,
            silence_sec=0.4,
            preroll_sec=0.4,
            voice_rms_threshold=160.0,
            model_size="small",
            device="cpu",
            compute_type="int8",
            debug=True,
    ):
        self.input_sr = input_sample_rate
        self.target_sr = target_sample_rate
        self.silence_sec = silence_sec
        self.voice_rms_threshold = voice_rms_threshold
        self.debug = debug

        self.preroll = deque(maxlen=int(preroll_sec * input_sample_rate))
        self.buffer = np.zeros(0, dtype=np.int16)

        self.in_speech = False
        self.last_voice_ts = None

        self._last_debug_ts = time.time()

        self.model = WhisperModel(
            model_size,
            device=device,
            compute_type=compute_type,
        )

    # -------------------------------------------------------------

    def start_listening(self):
        """Chiamata esplicita dal frontend a ogni riapertura micro."""
        now = time.time()
        self.in_speech = False
        self.last_voice_ts = now
        self.buffer = np.zeros(0, dtype=np.int16)
        self.preroll.clear()

        if self.debug:
            print("🎧 BACKEND start_listening()")

    # -------------------------------------------------------------

    def push_audio(self, pcm_bytes: bytes):
        now = time.time()
        events = []

        pcm = np.frombuffer(pcm_bytes, dtype=np.int16)
        self.preroll.extend(pcm)

        rms = float(np.sqrt(np.mean(pcm.astype(np.float32) ** 2)))

        if self.debug and (now - self._last_debug_ts) > 1.0:
            self._last_debug_ts = now
            print(
                f"🎧 rms={rms:.1f} in_speech={self.in_speech} buf={len(self.buffer)}"
            )

        # ---------------- VOCE ----------------
        if rms >= self.voice_rms_threshold:
            if not self.in_speech:
                self.in_speech = True
                self.buffer = np.array(self.preroll, dtype=np.int16)

            self.buffer = np.concatenate([self.buffer, pcm])
            self.last_voice_ts = now
            return events

        # ---------------- SILENZIO ----------------
        if self.last_voice_ts is None:
            self.last_voice_ts = now
            return events

        silence_time = now - self.last_voice_ts

        if silence_time >= self.silence_sec:
            if self.in_speech:
                text = self._finalize()
                if text:
                    events.append(("final", {"text": text}))
                self._reset()
            else:
                # silenzio senza aver parlato
                self._reset()
                events.append(("idle_timeout", {}))


        return events

    # -------------------------------------------------------------

    def _finalize(self):
        pcm16 = self._resample(self.buffer)
        wav = self._to_wav(pcm16)

        segments, _ = self.model.transcribe(
            io.BytesIO(wav),
            language="it",
            vad_filter=True,
            beam_size=5,
            best_of=5,
            temperature=0.0,
        )

        return " ".join(s.text.strip() for s in segments if s.text).strip()

    def _reset(self):
        self.buffer = np.zeros(0, dtype=np.int16)
        self.preroll.clear()
        self.in_speech = False
        self.last_voice_ts = None

    def _resample(self, pcm):
        if self.input_sr == self.target_sr:
            return pcm
        g = np.gcd(self.input_sr, self.target_sr)
        return resample_poly(
            pcm,
            self.target_sr // g,
            self.input_sr // g
        ).astype(np.int16)

    def _to_wav(self, pcm):
        bio = io.BytesIO()
        with wave.open(bio, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(self.target_sr)
            wf.writeframes(pcm.tobytes())
        return bio.getvalue()

