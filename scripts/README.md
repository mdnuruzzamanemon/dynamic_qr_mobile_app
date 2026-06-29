# 🔐 HDFC-Style Security Demo Scripts

## Scripts Overview

### `01-verify-signature.js` - App Verifies Server
Shows how mobile app verifies login response (Server → App trust)

### `02-bank-verifies-app.js` - Server Verifies App  
Shows how bank verifies mobile app requests (App → Server trust)

### `hdfc-demo.js` - Complete Flow
Full 6-step working demo with real API calls

---

## 1. `01-verify-signature.js`

**Purpose**: App verifies server is authentic bank

**Process**:
1. Login to bank server
2. Extract encrypted_enc_key, signature, public_key
3. Verify RSA-PSS signature
4. Show if bank is real or fake

**Output**: Step-by-step Bangla explanation

**Run**:
```bash
node 01-verify-signature.js
```

---

## 2. `02-bank-verifies-app.js`

**Purpose**: Bank verifies app is authorized

**Process**:
1. **Device Registration**: App generates RSA keys, registers with bank
2. **Request Signing**: App signs every request with private key  
3. **Bank Verification**: Bank verifies signature with stored public key
4. **Third-party Rejection**: Shows why fake apps fail

**Output**: Complete two-way trust demonstration

**Run**:
```bash
node 02-bank-verifies-app.js
```

**Key Points**:
- Every device = Unique key pair
- Private key stored in Android Keystore / iOS Keychain
- Bank maintains whitelist of authorized devices
- Device can be revoked if lost/stolen

---

## 3. `hdfc-demo.js`

**Purpose**: Complete working example with real API calls

**Process**:
1. Login (get JWT + encrypted keys)
2. Verify RSA signature (app verifies server)
3. Decrypt master key (client-side)
4. Scan QR code (get encrypted payload)
5. Decrypt QR payload (client-side)
6. Show document (WebView)

**Output**: 6 complete steps + security analysis

**Run**:
```bash
node hdfc-demo.js
```

**Shows**:
- Server signature verification
- Client-side decryption
- Why third-party apps can't decrypt

---

## Security Flow Summary

```
┌─────────────────────────────────────────────────────────┐
│                 TWO-WAY VERIFICATION                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Bank → App (Server Authentication):                   │
│    ✓ Bank signs with private key                       │
│    ✓ App verifies with public key                      │
│    ✓ Proves: Real bank, not fake server                │
│                                                         │
│  App → Bank (Device Authentication):                   │
│    ✓ App signs request with device private key         │
│    ✓ Bank verifies with stored device public key       │
│    ✓ Proves: Authorized app, not third-party           │
│                                                         │
│  Data Protection:                                       │
│    ✓ Master key encrypted with password                │
│    ✓ All decryption client-side only                   │
│    ✓ Server never sees password or decrypted keys      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Requirements

- Node.js 18+
- Backend server running on http://localhost:9000

## For Client Demo

1. Start with `01-verify-signature.js` - Simple, shows app verification
2. Then `02-bank-verifies-app.js` - Shows bank verification  
3. Finally `hdfc-demo.js` - Complete working flow

**Perfect for Bangladesh Bank compliance demonstration!** 🏦
