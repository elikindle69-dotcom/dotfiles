#!/usr/bin/env python3
"""
Quickshell Password Manager — Crypto Helper

All cryptographic operations isolated in this subprocess.
Communicates via stdin/stdout JSON with the QML CryptoService.

Primitives:
  - Argon2id (cryptography lib) — password hashing + key derivation
  - HKDF-SHA256 (cryptography lib) — domain-separated subkey derivation
  - XChaCha20-Poly1305 (libsodium/nacl) — AEAD vault encryption
"""

import sys
import os
import json
import base64
import hmac
import hashlib
import secrets

DEBUG = True


def log(msg):
    if DEBUG:
        print(f"[PM:py:debug] {msg}", file=sys.stderr)
        sys.stderr.flush()

from cryptography.hazmat.primitives.kdf.argon2 import Argon2id
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives import hashes
from nacl.bindings import (
    crypto_aead_xchacha20poly1305_ietf_encrypt,
    crypto_aead_xchacha20poly1305_ietf_decrypt,
    crypto_aead_xchacha20poly1305_ietf_KEYBYTES,
    crypto_aead_xchacha20poly1305_ietf_NPUBBYTES,
)

# Argon2id parameters (consistent across all operations)
ARGON2_ITERATIONS = 3
ARGON2_MEMORY = 65536  # KiB (64 MB)
ARGON2_LANES = 4
ARGON2_SALT_BYTES = 16
ARGON2_OUTPUT_LEN = 32

# HKDF info strings for domain separation
HKDF_VERIFY_INFO = b"quickshell-pm-verify-v1"
HKDF_ENCRYPT_INFO = b"quickshell-pm-encrypt-v1"

# AAD prefix for vault encryption
AAD_PREFIX = b"vault-v1:"


def b64e(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def b64d(s: str) -> bytes:
    return base64.b64decode(s.encode("ascii"))


def secure_zero(buf: bytearray):
    """Best-effort memory zeroing for mutable buffers."""
    for i in range(len(buf)):
        buf[i] = 0


def derive_master_key(password: bytes, salt: bytes) -> bytearray:
    """Argon2id: password + salt → 32-byte master key."""
    kdf = Argon2id(
        salt=salt,
        length=ARGON2_OUTPUT_LEN,
        iterations=ARGON2_ITERATIONS,
        memory_cost=ARGON2_MEMORY,
        lanes=ARGON2_LANES,
    )
    key = bytearray(kdf.derive(password))
    return key


def derive_subkey(master_key: bytearray, salt: bytes, info: bytes) -> bytearray:
    """HKDF-SHA256: master key → domain-separated subkey."""
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=ARGON2_OUTPUT_LEN,
        salt=salt,
        info=info,
    )
    return bytearray(hkdf.derive(bytes(master_key)))


def compute_verifier(master_key: bytearray, salt: bytes) -> bytes:
    """Derive verify subkey, return SHA-256 hash for storage."""
    verify_key = derive_subkey(master_key, salt, HKDF_VERIFY_INFO)
    verifier = hashlib.sha256(bytes(verify_key)).digest()
    secure_zero(verify_key)
    return verifier


def cmd_hash_password():
    """Hash a master password. Returns salt + verifier for storage."""
    data = json.loads(read_input())
    password = data["password"].encode("utf-8")

    salt = os.urandom(ARGON2_SALT_BYTES)
    master_key = derive_master_key(password, salt)
    verifier = compute_verifier(master_key, salt)

    secure_zero(master_key)
    secure_zero(bytearray(password))

    print(json.dumps({
        "salt": b64e(salt),
        "verifier": b64e(verifier),
    }))
    sys.stdout.flush()


def cmd_verify_password():
    """Verify a master password against stored hash."""
    data = json.loads(read_input())
    password = data["password"].encode("utf-8")
    salt = b64d(data["salt"])
    stored_verifier = b64d(data["verifier"])

    log("verify_password: password_len=%d salt=%s stored_verifier=%s" % (len(password), data["salt"], data["verifier"][:20]))

    master_key = derive_master_key(password, salt)
    verifier = compute_verifier(master_key, salt)

    valid = hmac.compare_digest(verifier, stored_verifier)

    log("verify_password: computed_verifier=%s valid=%s" % (b64e(verifier)[:20], valid))

    secure_zero(master_key)
    secure_zero(bytearray(password))
    secure_zero(bytearray(verifier))

    if not valid:
        log("verify_password: FAILED")
        print(json.dumps({"valid": False}))
        sys.stdout.flush()
        sys.exit(1)

    log("verify_password: OK")
    print(json.dumps({"valid": True}))
    sys.stdout.flush()


def cmd_derive_key():
    """Derive encryption key from password + salt."""
    data = json.loads(read_input())
    password = data["password"].encode("utf-8")
    salt = b64d(data["salt"])

    log("derive_key: password_len=%d salt=%s" % (len(password), data["salt"]))

    master_key = derive_master_key(password, salt)
    enc_key = derive_subkey(master_key, salt, HKDF_ENCRYPT_INFO)

    log("derive_key: derived key=%s" % b64e(bytes(enc_key))[:20])

    secure_zero(master_key)
    secure_zero(bytearray(password))

    print(json.dumps({"key": b64e(bytes(enc_key))}))
    sys.stdout.flush()
    secure_zero(enc_key)


def cmd_encrypt_vault():
    """Encrypt vault data with XChaCha20-Poly1305."""
    data = json.loads(read_input())
    key = bytearray(b64d(data["key"]))
    salt = b64d(data["salt"])
    plaintext = data["plaintext"].encode("utf-8")

    aad = AAD_PREFIX + base64.b64encode(salt)
    log("encrypt_vault: plaintext_len=%d salt=%s aad=%s" % (len(plaintext), data["salt"], aad[:30]))
    nonce = os.urandom(crypto_aead_xchacha20poly1305_ietf_NPUBBYTES)

    ciphertext = crypto_aead_xchacha20poly1305_ietf_encrypt(
        plaintext, aad, nonce, bytes(key)
    )

    secure_zero(key)

    print(json.dumps({
        "nonce": b64e(nonce),
        "ciphertext": b64e(ciphertext),
        "blob": b64e(json.dumps({"nonce": b64e(nonce), "ciphertext": b64e(ciphertext)}).encode("utf-8")),
    }))
    sys.stdout.flush()


def cmd_decrypt_vault():
    """Decrypt vault data with XChaCha20-Poly1305."""
    data = json.loads(read_input())
    key = bytearray(b64d(data["key"]))
    salt = b64d(data["salt"])
    nonce = b64d(data["nonce"])
    ciphertext = b64d(data["ciphertext"])

    aad = AAD_PREFIX + base64.b64encode(salt)
    log("decrypt_vault: salt=%s nonce=%s ct_len=%d aad=%s" % (data["salt"], data["nonce"], len(ciphertext), aad[:30]))

    try:
        plaintext = crypto_aead_xchacha20poly1305_ietf_decrypt(
            ciphertext, aad, nonce, bytes(key)
        )
    except Exception as e:
        log("decrypt_vault: FAILED: %s" % e)
        secure_zero(key)
        print(json.dumps({"error": "decryption failed — invalid key or tampered data"}))
        sys.stdout.flush()
        sys.exit(1)

    secure_zero(key)

    print(json.dumps({"plaintext": plaintext.decode("utf-8")}))
    sys.stdout.flush()


def cmd_generate_password():
    """Generate a cryptographically random password."""
    data = json.loads(read_input())
    length = data.get("length", 20)
    charset = data.get("charset", "alphanumeric")

    if charset == "alphanumeric":
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    elif charset == "printable":
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
    else:
        chars = charset

    password = "".join(secrets.choice(chars) for _ in range(length))

    print(json.dumps({"password": password}))
    sys.stdout.flush()


COMMANDS = {
    "hash_password": cmd_hash_password,
    "verify_password": cmd_verify_password,
    "derive_key": cmd_derive_key,
    "encrypt_vault": cmd_encrypt_vault,
    "decrypt_vault": cmd_decrypt_vault,
    "generate_password": cmd_generate_password,
}


def read_input():
    """Read JSON from file arg (argv[2]) or stdin."""
    if len(sys.argv) >= 3:
        with open(sys.argv[2], "r") as f:
            return f.read()
    return sys.stdin.read()


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        log("ERROR: invalid command: %s" % sys.argv)
        print(json.dumps({"error": f"usage: {sys.argv[0]} <command> [input_file]"}))
        print("available: " + ", ".join(COMMANDS.keys()))
        sys.exit(1)

    log("command=%s args=%s" % (sys.argv[1], sys.argv[2] if len(sys.argv) >= 3 else "stdin"))
    COMMANDS[sys.argv[1]]()


if __name__ == "__main__":
    main()
