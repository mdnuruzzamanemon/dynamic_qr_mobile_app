#!/usr/bin/env node
/**
 * 🏦 Bank Kemon App ke Verify Kore?
 * 
 * Dekhabe: Bank kemon bujbe je authorized app theke request ashche
 */

const crypto = require('crypto');

console.log('🏦 Bank Verifies App Demo');
console.log('═══════════════════════════════════════════════════\n');

// =====================================================
// SCENARIO: App first time register korche
// =====================================================
console.log('SCENARIO 1: Device Registration (One-time)');
console.log('═══════════════════════════════════════════════════\n');

function deviceRegistration() {
  console.log('STEP 1: App RSA key pair generate kore');
  console.log('─────────────────────────────────────────────────');
  
  // App nijei generate kore (server na!)
  const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
  });
  
  console.log('✅ App e generate hoiche:');
  console.log('   📱 Private Key: (device e save, NEVER share)');
  console.log('   🔓 Public Key: (bank e pathabe)\n');
  
  console.log('STEP 2: App bank e register kore');
  console.log('─────────────────────────────────────────────────');
  console.log('POST /api/v1/app/register-certificate');
  console.log('Body:');
  console.log(JSON.stringify({
    device_id: 'samsung-s24-xyz123',
    public_key_pem: publicKey.substring(0, 60) + '...',
    device_name: 'Samsung Galaxy S24',
    platform: 'android'
  }, null, 2));
  console.log('');
  
  console.log('STEP 3: Bank save kore');
  console.log('─────────────────────────────────────────────────');
  console.log('Database:');
  console.log('  device_id: samsung-s24-xyz123');
  console.log('  public_key: -----BEGIN PUBLIC KEY-----...');
  console.log('  status: registered ✅\n');
  
  console.log('✅ Registration complete!\n');
  console.log('═══════════════════════════════════════════════════\n');
  
  return { publicKey, privateKey };
}

// =====================================================
// SCENARIO: App request korche
// =====================================================
console.log('SCENARIO 2: App Request Kore (Every Time)');
console.log('═══════════════════════════════════════════════════\n');

function appMakesRequest(privateKey) {
  console.log('STEP 1: App request body banay');
  console.log('─────────────────────────────────────────────────');
  
  const requestBody = {
    encrypted_payload: 'ZT-qd7Fc6BRd-CvBT7di...'
  };
  
  const requestString = JSON.stringify(requestBody);
  console.log('Request:', requestString, '\n');
  
  console.log('STEP 2: App private key diye sign kore');
  console.log('─────────────────────────────────────────────────');
  
  // Sign the request
  const sign = crypto.createSign('SHA256');
  sign.update(requestString);
  sign.end();
  
  const signature = sign.sign({
    key: privateKey,
    padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
    saltLength: 32
  });
  
  const signatureHex = signature.toString('hex');
  
  console.log('✅ Signature create hoiche');
  console.log('   Signature:', signatureHex.substring(0, 40) + '...\n');
  
  console.log('STEP 3: App bank e pathay');
  console.log('─────────────────────────────────────────────────');
  console.log('POST /api/v1/app/decrypt-qr');
  console.log('Headers:');
  console.log('  Authorization: Bearer <JWT>');
  console.log('  X-Device-Signature:', signatureHex.substring(0, 40) + '...');
  console.log('  X-Device-ID: samsung-s24-xyz123');
  console.log('Body:', requestString, '\n');
  
  return { requestString, signatureHex };
}

// =====================================================
// SCENARIO: Bank verify kore
// =====================================================
function bankVerifiesRequest(publicKey, requestString, signatureHex) {
  console.log('═══════════════════════════════════════════════════');
  console.log('🏦 BANK SIDE: Request Verify');
  console.log('═══════════════════════════════════════════════════\n');
  
  console.log('STEP 1: Bank headers check kore');
  console.log('─────────────────────────────────────────────────');
  console.log('✓ X-Device-ID ache? → Yes');
  console.log('✓ X-Device-Signature ache? → Yes');
  console.log('✓ JWT valid? → Yes\n');
  
  console.log('STEP 2: Bank database theke device er public key load kore');
  console.log('─────────────────────────────────────────────────');
  console.log('SELECT public_key FROM app_certificates');
  console.log('WHERE device_id = "samsung-s24-xyz123"');
  console.log('');
  console.log('✅ Device registered ache\n');
  
  console.log('STEP 3: Bank signature verify kore');
  console.log('─────────────────────────────────────────────────');
  
  // Verify
  const verify = crypto.createVerify('SHA256');
  verify.update(requestString);
  verify.end();
  
  const signatureBuffer = Buffer.from(signatureHex, 'hex');
  
  const isValid = verify.verify({
    key: publicKey,
    padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
    saltLength: 32
  }, signatureBuffer);
  
  console.log('Line 1: Verifier create');
  console.log('Line 2: Request body add');
  console.log('Line 3: Device er public key use');
  console.log('Line 4: Signature check\n');
  
  if (isValid) {
    console.log('✅ SIGNATURE VALID!\n');
    console.log('Bank bujhe gelo:');
    console.log('  → Registered device theke request');
    console.log('  → Private key ta oi device e ache');
    console.log('  → Request tampered hoy nai');
    console.log('  → Safe to process ✅\n');
    console.log('Bank response pathay: {"document": {...}}\n');
  } else {
    console.log('❌ SIGNATURE INVALID!\n');
    console.log('Bank bujhe gelo:');
    console.log('  → Fake app ba');
    console.log('  → Unregistered device ba');
    console.log('  → Request tampered hoyeche');
    console.log('  → REJECT immediately ❌\n');
    console.log('Bank response: 401 Unauthorized\n');
  }
  
  return isValid;
}

// =====================================================
// SCENARIO: Third-party app try kore
// =====================================================
function thirdPartyTry() {
  console.log('═══════════════════════════════════════════════════');
  console.log('❌ THIRD-PARTY APP: Try korche');
  console.log('═══════════════════════════════════════════════════\n');
  
  console.log('Scenario A: Registered na');
  console.log('─────────────────────────────────────────────────');
  console.log('Third-party request kore:');
  console.log('  X-Device-ID: fake-device-123\n');
  console.log('Bank check kore database:');
  console.log('  SELECT * WHERE device_id = "fake-device-123"');
  console.log('  → Not found ❌\n');
  console.log('Bank response: 401 Unauthorized\n');
  
  console.log('Scenario B: Signature fake');
  console.log('─────────────────────────────────────────────────');
  console.log('Third-party nijei signature banay (without private key)\n');
  console.log('Bank verify kore:');
  console.log('  → Signature match kore na');
  console.log('  → Invalid ❌\n');
  console.log('Bank response: 401 Unauthorized\n');
}

// =====================================================
// FULL COMPARISON
// =====================================================
function showComparison() {
  console.log('═══════════════════════════════════════════════════');
  console.log('📊 COMPARISON: Authorized vs Third-Party');
  console.log('═══════════════════════════════════════════════════\n');
  
  console.log('✅ AUTHORIZED APP (Your Bank App):');
  console.log('  Step 1: Registered → Device ID ache');
  console.log('  Step 2: Private key ache → Valid signature');
  console.log('  Step 3: JWT ache → Authenticated');
  console.log('  Step 4: Bank verify → All pass ✅');
  console.log('  Result: Request accepted!\n');
  
  console.log('❌ THIRD-PARTY APP (Fake Scanner):');
  console.log('  Step 1: NOT registered → No device ID');
  console.log('  Step 2: No private key → Invalid signature');
  console.log('  Step 3: No JWT → Unauthenticated');
  console.log('  Step 4: Bank verify → Failed ❌');
  console.log('  Result: Request rejected!\n');
  
  console.log('═══════════════════════════════════════════════════');
  console.log('🔒 WHY THIS IS SECURE?');
  console.log('═══════════════════════════════════════════════════\n');
  
  console.log('1. TWO-WAY TRUST:');
  console.log('   Bank → App: RSA signature (bank signs)');
  console.log('   App → Bank: Device signature (app signs)\n');
  
  console.log('2. UNIQUE KEYS:');
  console.log('   Every device = Different key pair');
  console.log('   Copy korleo, private key nai → Useless\n');
  console.log('3. DEVICE BINDING:');
  console.log('   Key stored in Android Keystore / iOS Keychain');
  console.log('   Extract kora nearly impossible\n');
  
  console.log('4. REVOCABLE:');
  console.log('   Device lost? Bank revoke kore');
  console.log('   Database e status = "revoked"');
  console.log('   Oi device ar request korte parbe na\n');
}

// =====================================================
// MAIN
// =====================================================
function main() {
  // Scenario 1: Registration
  const { publicKey, privateKey } = deviceRegistration();
  
  // Scenario 2: App request
  const { requestString, signatureHex } = appMakesRequest(privateKey);
  
  // Scenario 3: Bank verify
  bankVerifiesRequest(publicKey, requestString, signatureHex);
  
  // Scenario 4: Third-party
  thirdPartyTry();
  
  // Comparison
  showComparison();
}

main();
