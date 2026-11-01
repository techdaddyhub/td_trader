"""TD TRADER - Security Subsystem
Handles credential hashing, AES-256 Fernet broker password encryption, and JWT token lifecycle.
Never stores broker credentials or user passwords in plaintext.
"""

import hmac
import hashlib
import base64
import json
import time
import os
from typing import Dict, Any, Optional
from cryptography.fernet import Fernet
from td_trader.backend.app.core.config import settings

# --- Password Hashing (PBKDF2-HMAC-SHA256 with 600,000 rounds) ---

def hash_password(password: str) -> str:
    """Hash password using cryptographic salt and PBKDF2-HMAC-SHA256."""
    salt = os.urandom(16)
    key = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 600000)
    return f"{base64.b64encode(salt).decode('ascii')}${base64.b64encode(key).decode('ascii')}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against salt and stored PBKDF2 hash using constant-time comparison."""
    try:
        salt_b64, key_b64 = hashed_password.split("$")
        salt = base64.b64decode(salt_b64.encode('ascii'))
        expected_key = base64.b64decode(key_b64.encode('ascii'))
        computed_key = hashlib.pbkdf2_hmac('sha256', plain_password.encode('utf-8'), salt, 600000)
        return hmac.compare_digest(computed_key, expected_key)
    except Exception:
        return False

# --- Broker Credential AES-256 Encryption ---

def encrypt_broker_credential(plaintext: str) -> str:
    """Encrypt broker password using AES-256 Fernet. Never store plaintext credentials."""
    cipher = Fernet(settings.CREDENTIAL_ENCRYPTION_KEY)
    encrypted_bytes = cipher.encrypt(plaintext.encode('utf-8'))
    return encrypted_bytes.decode('utf-8')

def decrypt_broker_credential(ciphertext: str) -> str:
    """Decrypt broker password in-memory only during authenticated execution."""
    cipher = Fernet(settings.CREDENTIAL_ENCRYPTION_KEY)
    decrypted_bytes = cipher.decrypt(ciphertext.encode('utf-8'))
    return decrypted_bytes.decode('utf-8')

# --- RFC 7519 JWT Token Generation & Verification (HMAC-SHA256) ---

def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode('utf-8').rstrip('=')

def _b64url_decode(s: str) -> bytes:
    padding = '=' * (4 - (len(s) % 4)) if len(s) % 4 != 0 else ''
    return base64.urlsafe_b64decode(s + padding)

def create_access_token(data: Dict[str, Any], expires_delta_sec: Optional[int] = None) -> str:
    """Create signed RFC 7519 JWT access token with payload and expiration."""
    header = {"alg": "HS256", "typ": "JWT"}
    payload = data.copy()
    now = int(time.time())
    exp = now + (expires_delta_sec if expires_delta_sec is not None else settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    payload["iat"] = now
    payload["exp"] = exp
    
    header_json = json.dumps(header, separators=(',', ':')).encode('utf-8')
    payload_json = json.dumps(payload, separators=(',', ':')).encode('utf-8')
    
    header_b64 = _b64url_encode(header_json)
    payload_b64 = _b64url_encode(payload_json)
    
    unsigned_token = f"{header_b64}.{payload_b64}"
    signature = hmac.new(settings.SECRET_KEY.encode('utf-8'), unsigned_token.encode('utf-8'), hashlib.sha256).digest()
    sig_b64 = _b64url_encode(signature)
    
    return f"{unsigned_token}.{sig_b64}"

def verify_access_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify JWT token signature and expiration, returning payload if valid."""
    try:
        parts = token.split('.')
        if len(parts) != 3:
            return None
        header_b64, payload_b64, sig_b64 = parts
        
        unsigned_token = f"{header_b64}.{payload_b64}"
        expected_sig = hmac.new(settings.SECRET_KEY.encode('utf-8'), unsigned_token.encode('utf-8'), hashlib.sha256).digest()
        actual_sig = _b64url_decode(sig_b64)
        
        if not hmac.compare_digest(expected_sig, actual_sig):
            return None
            
        payload_bytes = _b64url_decode(payload_b64)
        payload = json.loads(payload_bytes.decode('utf-8'))
        
        # Check expiry
        if payload.get("exp", 0) < time.time():
            return None
            
        return payload
    except Exception:
        return None

