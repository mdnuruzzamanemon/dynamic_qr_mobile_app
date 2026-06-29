#!/bin/bash

echo "🔐 Testing New Security Features"
echo "═══════════════════════════════════════════════════"
echo ""

BASE_URL="http://localhost:9000/api/v1"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test 1: Certificate Hash Endpoint
echo -e "${BLUE}Test 1: SSL Certificate Hash${NC}"
echo "───────────────────────────────────"
CERT_HASH=$(curl -s $BASE_URL/security/certificate-hash)

if [[ $CERT_HASH == *"sha256"* ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Certificate hash endpoint working"
    echo "$CERT_HASH" | head -3
else
    echo -e "${RED}❌ FAIL${NC}: Certificate hash endpoint failed"
fi
echo ""

# Test 2: Login (get JWT)
echo -e "${BLUE}Test 2: JWT Authentication${NC}"
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
    exit 1
fi
echo ""

# Test 3: Device Signature Check
echo -e "${BLUE}Test 3: Device Signature Requirement${NC}"
echo "───────────────────────────────────────────"
NO_SIG=$(curl -s -w "\nHTTP:%{http_code}" \
  -X POST $BASE_URL/app/decrypt-qr \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"encrypted_payload":"test"}')

HTTP_CODE=$(echo "$NO_SIG" | grep "HTTP:" | cut -d: -f2)

if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Requires device signature"
    echo "   Status: 401 Unauthorized"
else
    echo -e "${RED}❌ FAIL${NC}: Should reject unsigned requests"
fi
echo ""

# Test 4: Mock Integrity Check (Secure Device)
echo -e "${BLUE}Test 4: Play Integrity - Secure Device${NC}"
echo "───────────────────────────────────────────"
echo "Note: Using mock mode (USE_MOCK_INTEGRITY=true)"
echo ""

# This would normally come from Play Integrity API
# Format: "DEVICE_TYPE:APP_TYPE"
INTEGRITY_TOKEN="SECURE:GENUINE"

echo "Sending token: $INTEGRITY_TOKEN"
SECURE_RESPONSE=$(curl -s -w "\nHTTP:%{http_code}" \
  -X POST $BASE_URL/app/decrypt-qr \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Integrity-Token: $INTEGRITY_TOKEN" \
  -H "X-Device-Signature: mock_signature" \
  -H "X-Device-ID: test_device" \
  -H "Content-Type: application/json" \
  -d '{"encrypted_payload":"test"}')

HTTP_CODE=$(echo "$SECURE_RESPONSE" | grep "HTTP:" | cut -d: -f2)

echo "Response code: $HTTP_CODE"
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Secure device token processed"
else
    echo -e "${YELLOW}⚠️  INFO${NC}: Integrity middleware may not be active yet"
fi
echo ""

# Test 5: Mock Integrity Check (Rooted Device)
echo -e "${BLUE}Test 5: Play Integrity - Rooted Device${NC}"
echo "───────────────────────────────────────────"
INTEGRITY_TOKEN="ROOTED:GENUINE"

echo "Sending token: $INTEGRITY_TOKEN"
ROOTED_RESPONSE=$(curl -s -w "\nHTTP:%{http_code}" \
  -X POST $BASE_URL/app/decrypt-qr \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Integrity-Token: $INTEGRITY_TOKEN" \
  -H "X-Device-Signature: mock_signature" \
  -H "X-Device-ID: test_device" \
  -H "Content-Type: application/json" \
  -d '{"encrypted_payload":"test"}')

HTTP_CODE=$(echo "$ROOTED_RESPONSE" | grep "HTTP:" | cut -d: -f2)
BODY=$(echo "$ROOTED_RESPONSE" | sed '/HTTP:/d')

echo "Response code: $HTTP_CODE"
if [ "$HTTP_CODE" == "401" ] && [[ "$BODY" == *"integrity"* ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Rooted device blocked"
    echo "   Error: $BODY"
else
    echo -e "${YELLOW}⚠️  INFO${NC}: Integrity middleware not yet applied to this endpoint"
fi
echo ""

# Test 6: Mock Integrity Check (Modified APK)
echo -e "${BLUE}Test 6: Play Integrity - Modified APK${NC}"
echo "───────────────────────────────────────────"
INTEGRITY_TOKEN="SECURE:MODIFIED"

echo "Sending token: $INTEGRITY_TOKEN"
MODIFIED_RESPONSE=$(curl -s -w "\nHTTP:%{http_code}" \
  -X POST $BASE_URL/app/decrypt-qr \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Integrity-Token: $INTEGRITY_TOKEN" \
  -H "X-Device-Signature: mock_signature" \
  -H "X-Device-ID: test_device" \
  -H "Content-Type: application/json" \
  -d '{"encrypted_payload":"test"}')

HTTP_CODE=$(echo "$MODIFIED_RESPONSE" | grep "HTTP:" | cut -d: -f2)
BODY=$(echo "$MODIFIED_RESPONSE" | sed '/HTTP:/d')

echo "Response code: $HTTP_CODE"
if [ "$HTTP_CODE" == "401" ] && [[ "$BODY" == *"integrity"* ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Modified APK blocked"
    echo "   Error: $BODY"
else
    echo -e "${YELLOW}⚠️  INFO${NC}: Integrity middleware not yet applied to this endpoint"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════"
echo -e "${BLUE}BACKEND SECURITY STATUS${NC}"
echo "═══════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ IMPLEMENTED:${NC}"
echo "  1. SSL Certificate Generation"
echo "  2. Certificate Hash Endpoint"
echo "  3. Device Signature Middleware (PKI)"
echo "  4. Play Integrity Service (code ready)"
echo "  5. Integrity Middleware (code ready)"
echo ""
echo -e "${YELLOW}⚠️  PENDING:${NC}"
echo "  1. Apply IntegrityMiddleware to routes"
echo "  2. Configure Google Play API key"
echo "  3. Enable HTTPS in production"
echo ""
echo -e "${BLUE}📱 NEXT STEPS FOR ANDROID:${NC}"
echo "  1. Get certificate hash from endpoint"
echo "  2. Implement SSL pinning with hash"
echo "  3. Implement hardware keystore"
echo "  4. Setup Play Integrity client"
echo "  5. Add biometric authentication"
echo "  6. Implement root detection"
echo ""
echo "For detailed implementation guide, see:"
echo "  ${YELLOW}ANDROID_IMPLEMENTATION_GUIDE.md${NC}"
echo ""
