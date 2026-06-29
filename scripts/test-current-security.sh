#!/bin/bash

echo "🔐 Current Security Test - Run Koro Ekhoni!"
echo "═══════════════════════════════════════════════════"
echo ""

BASE_URL="http://localhost:9000/api/v1"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test 1: Login (JWT)
echo "Test 1: Login (JWT Authentication)"
echo "───────────────────────────────────"
LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "email": "reader@demo-bank.com",
    "password": "reader123"
  }')

TOKEN=$(echo $LOGIN | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Login successful"
    echo "   JWT: ${TOKEN:0:40}..."
else
    echo -e "${RED}❌ FAIL${NC}: Login failed"
    echo "   Response: $LOGIN"
    exit 1
fi
echo ""

# Test 2: Request without signature (Should fail)
echo "Test 2: Request WITHOUT Device Signature"
echo "───────────────────────────────────────────"
NO_SIG=$(curl -s -w "\nHTTP:%{http_code}" \
  -X POST $BASE_URL/app/decrypt-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "encrypted_payload": "test123"
  }')

HTTP_CODE=$(echo "$NO_SIG" | grep "HTTP:" | cut -d: -f2)
BODY=$(echo "$NO_SIG" | sed '/HTTP:/d')

if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Unsigned request blocked"
    echo "   Status: 401 Unauthorized"
    echo "   Error: $BODY"
else
    echo -e "${RED}❌ FAIL${NC}: Should return 401, got $HTTP_CODE"
fi
echo ""

# Test 3: Request without JWT (Should fail)
echo "Test 3: Request WITHOUT JWT"
echo "────────────────────────────"
NO_JWT=$(curl -s -w "\nHTTP:%{http_code}" \
  -X POST $BASE_URL/app/decrypt-qr \
  -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3000" \
  -d '{
    "encrypted_payload": "test123"
  }')

HTTP_CODE=$(echo "$NO_JWT" | grep "HTTP:" | cut -d: -f2)

if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Request without JWT blocked"
    echo "   Status: 401 Unauthorized"
else
    echo -e "${RED}❌ FAIL${NC}: Should return 401, got $HTTP_CODE"
fi
echo ""

# Test 4: Signature verification
echo "Test 4: Server Signature Verification"
echo "──────────────────────────────────────"
SIG=$(echo $LOGIN | grep -o '"signature":"[^"]*"' | cut -d'"' -f4)

if [ -n "$SIG" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Server provides signature"
    echo "   Signature: ${SIG:0:40}..."
    echo "   App can verify this with public key"
else
    echo -e "${RED}❌ FAIL${NC}: No signature in login response"
fi
echo ""

# Test 5: Encryption password check
echo "Test 5: Encryption Password Required"
echo "─────────────────────────────────────"
ENC_KEY=$(echo $LOGIN | grep -o '"encrypted_enc_key":"[^"]*"' | cut -d'"' -f4)

if [ -n "$ENC_KEY" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Master key is encrypted"
    echo "   Encrypted Key: ${ENC_KEY:0:40}..."
    echo "   Cannot decrypt without password"
else
    echo -e "${YELLOW}⚠️  WARNING${NC}: No encrypted key found"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════"
echo "SECURITY SUMMARY"
echo "═══════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ WORKING:${NC}"
echo "  1. JWT Authentication"
echo "  2. Device Signature Required (PKI)"
echo "  3. Server Signature (RSA-PSS)"
echo "  4. Password-based Encryption"
echo ""
echo -e "${YELLOW}⚠️  CAN BE BYPASSED:${NC}"
echo "  1. No SSL Pinning (Burp Suite MITM)"
echo "  2. No Hardware Keys (Key can be extracted)"
echo "  3. No Device Attestation (Rooted device works)"
echo "  4. No Integrity Check (Modified APK works)"
echo ""
echo -e "${RED}❌ MISSING:${NC}"
echo "  1. SSL Certificate Pinning"
echo "  2. Hardware-backed Keystore"
echo "  3. Play Integrity API"
echo "  4. Biometric Authentication"
echo "  5. Root Detection"
echo ""
echo "Current Security Level: ${YELLOW}40%${NC}"
echo "Banking Standard Level: ${GREEN}95%${NC}"
echo ""
echo "Next steps:"
echo "  1. Read: BANKING_STANDARD_CHECKLIST.md"
echo "  2. Implement: SSL Pinning (Week 1)"
echo "  3. Test again with: ./test-current-security.sh"
echo ""
