"""TD TRADER - MODULE 2: TD AI Voice Assistant & Institutional Voice Synthesis Engine
Modular Text-to-Speech (TTS), speech parameters, real-time alert announcer,
and interactive conversational dialogue manager.
"""

from typing import Dict, Any, List, Optional
import io
import wave
import math
import struct
import base64
from datetime import datetime
from td_trader.backend.app.schemas.schemas import VoiceQueryRequest, VoiceQueryResponse, VoiceAnnouncement
from td_trader.ai_engine.ai_explainer.explainer import ai_explainer

# Voice Personalities Catalog
VOICE_PERSONALITIES = {
    "Aria_Fintech_Pro": {
        "gender": "Female",
        "style": "Authoritative Fintech Executive",
        "pitch_shift": 1.05,
        "default_rate": 1.0
    },
    "Sophia_Macro_Strategist": {
        "gender": "Female",
        "style": "Analytical Global Macro Economist",
        "pitch_shift": 0.98,
        "default_rate": 0.95
    },
    "Marcus_Quant_Lead": {
        "gender": "Male",
        "style": "Direct Quantitative Analyst",
        "pitch_shift": 0.85,
        "default_rate": 1.10
    },
    "Alexander_Institutional": {
        "gender": "Male",
        "style": "Disciplined Risk Arbiter",
        "pitch_shift": 0.80,
        "default_rate": 0.98
    }
}

class AudioWaveSynthesizer:
    """Generates high-fidelity audio tone waveforms encoded in RFC 2045 Base64 WAV format.
    Serves as an immediate zero-dependency audio carrier that renders natively on Flutter & Web browsers.
    """
    @staticmethod
    def generate_speech_earcon(frequency: float = 440.0, duration_sec: float = 0.35) -> str:
        sample_rate = 22050
        num_samples = int(sample_rate * duration_sec)
        buf = io.BytesIO()
        
        with wave.open(buf, 'wb') as wav_file:
            wav_file.setnchannels(1)        # Mono
            wav_file.setsampwidth(2)        # 16-bit
            wav_file.setframerate(sample_rate)
            
            for i in range(num_samples):
                # Envelope: attack, sustain, decay
                t = float(i) / sample_rate
                envelope = math.sin(math.pi * (i / num_samples))
                # Smooth sine wave with mild overtone harmonics
                val = 0.7 * math.sin(2 * math.pi * frequency * t) + 0.3 * math.sin(4 * math.pi * frequency * t)
                sample = int(val * envelope * 30000.0)
                wav_file.writeframesraw(struct.pack('<h', max(min(sample, 32767), -32768)))
                
        return base64.b64encode(buf.getvalue()).decode('ascii')

class TDAIVoiceEngine:
    """TD AI Voice - Personal Trading Analyst Engine."""
    
    def __init__(self):
        self.is_voice_enabled: bool = True
        self.current_personality: str = "Aria_Fintech_Pro"
        self.speech_speed: float = 1.05
        self.speech_volume: float = 1.0
        self.is_speaking: bool = False
        self.conversation_history: List[Dict[str, str]] = []

    def set_personality(self, personality: str):
        if personality in VOICE_PERSONALITIES:
            self.current_personality = personality

    def configure_voice(self, speed: float, volume: float, enabled: bool):
        self.speech_speed = min(max(speed, 0.5), 2.0)
        self.speech_volume = min(max(volume, 0.0), 1.0)
        self.is_voice_enabled = enabled

    def interrupt_speech(self):
        """Immediately halts active audio output."""
        self.is_speaking = False

    def build_ssml(self, text: str, personality: Optional[str] = None) -> str:
        """Construct standard W3C SSML for speech synthesis engines."""
        p_name = personality or self.current_personality
        meta = VOICE_PERSONALITIES.get(p_name, VOICE_PERSONALITIES["Aria_Fintech_Pro"])
        pitch = f"{int((meta['pitch_shift'] - 1.0) * 100):+d}%"
        rate = f"{int((self.speech_speed - 1.0) * 100):+d}%"
        
        return (
            f'<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">\n'
            f'  <voice name="{p_name}">\n'
            f'    <prosody rate="{rate}" pitch="{pitch}" volume="{int(self.speech_volume * 100)}%">\n'
            f'      {text}\n'
            f'    </prosody>\n'
            f'  </voice>\n'
            f'</speak>'
        )

    # --- Pre-Configured Mandatory Announcements ---

    def create_new_signal_announcement(
        self, instrument: str = "XAUUSD", direction: str = "BUY", structure: str = "bullish"
    ) -> VoiceAnnouncement:
        msg = (
            f"TD Trader alert. A potential {direction} opportunity has been identified on {instrument}. "
            f"The market structure is {structure}, with supporting momentum confirmation. "
            f"The proposed entry, stop loss and take profit are available on your dashboard."
        )
        audio = AudioWaveSynthesizer.generate_speech_earcon(520.0, 0.4)
        return VoiceAnnouncement(
            announcement_type="NEW_SIGNAL",
            message=msg,
            timestamp=datetime.utcnow(),
            audio_base64=audio
        )

    def create_trade_execution_announcement(self, instrument: str = "EURUSD", direction: str = "buy") -> VoiceAnnouncement:
        msg = f"Your {instrument} {direction} order has been confirmed by your broker. Your position is now being monitored."
        audio = AudioWaveSynthesizer.generate_speech_earcon(650.0, 0.35)
        return VoiceAnnouncement(
            announcement_type="TRADE_EXECUTION",
            message=msg,
            timestamp=datetime.utcnow(),
            audio_base64=audio
        )

    def create_trade_closure_announcement(self) -> VoiceAnnouncement:
        msg = "Your position has been closed. Your final result, including trading costs, is now available."
        audio = AudioWaveSynthesizer.generate_speech_earcon(480.0, 0.35)
        return VoiceAnnouncement(
            announcement_type="TRADE_CLOSURE",
            message=msg,
            timestamp=datetime.utcnow(),
            audio_base64=audio
        )

    def create_market_alert_announcement(self, instrument: str = "Gold") -> VoiceAnnouncement:
        msg = f"Attention. {instrument} is experiencing increased volatility. Review your open positions and current risk exposure."
        audio = AudioWaveSynthesizer.generate_speech_earcon(740.0, 0.45)
        return VoiceAnnouncement(
            announcement_type="MARKET_ALERT",
            message=msg,
            timestamp=datetime.utcnow(),
            audio_base64=audio
        )

    def create_risk_alert_announcement(self) -> VoiceAnnouncement:
        msg = "Risk Guardian activated. Your configured daily loss threshold has been reached. New automated entries have been suspended."
        audio = AudioWaveSynthesizer.generate_speech_earcon(350.0, 0.5)
        return VoiceAnnouncement(
            announcement_type="RISK_ALERT",
            message=msg,
            timestamp=datetime.utcnow(),
            audio_base64=audio
        )

    # --- Conversational Dialogue ---

    def process_conversation(self, req: VoiceQueryRequest, context: Optional[Dict[str, Any]] = None) -> VoiceQueryResponse:
        """Processes conversational speech query, generating verified facts, analysis, and speech audio."""
        ctx = context or {}
        analysis = ai_explainer.process_query(
            query=req.query,
            account_data=ctx.get("account"),
            risk_data=ctx.get("risk"),
            positions=ctx.get("positions"),
            recent_signals=ctx.get("signals")
        )
        
        personality = req.voice_personality or self.current_personality
        ssml = self.build_ssml(analysis["response_text"], personality)
        
        # Audio cue generation
        audio_b64 = AudioWaveSynthesizer.generate_speech_earcon(440.0, 0.3)
        
        # Log to conversation history
        self.conversation_history.append({"role": "user", "text": req.query, "timestamp": datetime.utcnow().isoformat()})
        self.conversation_history.append({"role": "assistant", "text": analysis["response_text"], "timestamp": datetime.utcnow().isoformat()})
        
        return VoiceQueryResponse(
            query=req.query,
            response_text=analysis["response_text"],
            audio_base64=audio_b64,
            ssml_markup=ssml,
            intent=analysis["intent"],
            verified_facts=analysis["verified_facts"],
            ai_interpretation=analysis["ai_interpretation"],
            voice_personality=personality
        )

td_ai_voice_engine = TDAIVoiceEngine()

