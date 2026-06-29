#!/usr/bin/env node
/**
 * 🔐 Signature Verify - Login Response Check Kora
 * 
 * Eta dekhabe: Login response theke signature verify kora
 */

const crypto = require('crypto');

console.log('🔐 Signature Verification Demo');
console.log('═══════════════════════════════════════════════════\n');

// =====================================================
// STEP 1: Login API call koro
// =====================================================
async function loginToServer() {
  console.log('STEP 1: Login API call');
  console.log('─────────────────────────────────────────────────');
  
  const response = await fetch('http://localhost:9000/api/v1/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Origin': 'http://localhost:3000'
    },
    body: JSON.stringify({
      email: 'reader@demo-bank.com',
      password: 'reader123'
    })
  });
  
  const data = await response.json();
  
  console.log('✅ Response pelam!\n');
  return data;
}

// =====================================================
// STEP 2: Response theke 3 ta jinish ber koro
// =====================================================
function extractData(response) {
  console.log('STEP 2: Response theke data extract');
  console.log('─────────────────────────────────────────────────');
  
  // 1. Encrypted data (je data sign kora hoyeche)
  const encryptedKey = response.encrypted_enc_key;
  console.log('1. Encrypted Key:');
  console.log('   ', encryptedKey.substring(0, 50) + '...\n');
  
  // 2. Signature (bank er signature)
  const signature = response.signature;
  console.log('2. Signature:');
  console.log('   ', signature.substring(0, 50) + '...\n');
  
  // 3. Public Key (bank er public key)
  const publicKeyPem = response.bank_public_key_pem;
  console.log('3. Bank Public Key:');
  console.log('   ', publicKeyPem.substring(0, 60) + '...\n');
  
  return { encryptedKey, signature, publicKeyPem };
}

// =====================================================
// STEP 3: Bank er public key load koro
// =====================================================
function loadPublicKey(publicKeyPem) {
  console.log('STEP 3: Public Key load korchi');
  console.log('─────────────────────────────────────────────────');
  
  // PEM format theke public key create
  const publicKey = crypto.createPublicKey({
    key: publicKeyPem,
    format: 'pem'
  });
  
  console.log('✅ Public key loaded!\n');
  return publicKey;
}

// =====================================================
// STEP 4: Signature verify koro
// =====================================================
function verifySignature(encryptedKey, signature, publicKey) {
  console.log('STEP 4: Signature verify korchi');
  console.log('─────────────────────────────────────────────────');
  console.log('Checking: Bank theke ashche ki na?\n');
  
  // Line 1: Verifier object banao
  const verify = crypto.createVerify('SHA256');
  console.log('✓ Line 1: Verifier create korsi (SHA256 algorithm)');
  
  // Line 2: Je data sign kora hoyeche, seta diye daw
  verify.update(encryptedKey);
  console.log('✓ Line 2: Encrypted key add korsi');
  
  // Line 3: Verify preparation complete
  verify.end();
  console.log('✓ Line 3: Verify preparation complete');
  
  // Line 4: Signature ke hex theke buffer e convert
  const signatureBuffer = Buffer.from(signature, 'hex');
  console.log('✓ Line 4: Signature buffer e convert korsi');
  
  // Line 5: MAIN CHECK - Signature valid ki na?
  const isValid = verify.verify(
    {
      key: publicKey,                                // Bank er public key
      padding: crypto.constants.RSA_PKCS1_PSS_PADDING,  // RSA-PSS method
      saltLength: 32                                 // Security parameter
    },
    signatureBuffer                                  // Je signature check korbo
  );
  console.log('✓ Line 5: Verification complete!\n');
  
  return isValid;
}

// =====================================================
// STEP 5: Result dekhao
// =====================================================
function showResult(isValid) {
  console.log('STEP 5: Result');
  console.log('─────────────────────────────────────────────────');
  
  if (isValid) {
    console.log('✅ SIGNATURE VALID!\n');
    console.log('Mane:');
    console.log('  → Bank er private key diye sign kora');
    console.log('  → Public key diye match hocche');
    console.log('  → Ei data REAL BANK theke ashche');
    console.log('  → Data tampered hoy nai');
    console.log('  → Safe to proceed!\n');
  } else {
    console.log('❌ SIGNATURE INVALID!\n');
    console.log('Mane:');
    console.log('  → Fake server response');
    console.log('  → Data tampered hoyeche');
    console.log('  → App immediately reject korbe');
    console.log('  → User ke warning dekhabe\n');
  }
}

// =====================================================
// EXPLANATION: Ki hocche?
// =====================================================
function showExplanation() {
  console.log('═══════════════════════════════════════════════════');
  console.log('💡 KI HOCCHE? (Simple Bangla)');
  console.log('═══════════════════════════════════════════════════\n');
  
  console.log('Bank Server e ki ache:');
  console.log('  📝 Private Key (guppo key, keu jane na)\n');
  
  console.log('Bank ki kore:');
  console.log('  1. Data nao: "Hri5VT8qaGYT..."');
  console.log('  2. Private key diye sign koro');
  console.log('  3. Signature create hoy: "5b9008b877a8..."');
  console.log('  4. Data + Signature pathay app ke\n');
  
  console.log('App e ki ache:');
  console.log('  🔓 Public Key (shobai pabe, public)\n');
  
  console.log('App ki kore:');
  console.log('  1. Data nao: "Hri5VT8qaGYT..."');
  console.log('  2. Signature nao: "5b9008b877a8..."');
  console.log('  3. Public key diye check koro');
  console.log('  4. Match korle ✅ Real bank');
  console.log('  5. Na match korle ❌ Fake server\n');
  
  console.log('═══════════════════════════════════════════════════');
  console.log('🔒 WHY SECURE?');
  console.log('═══════════════════════════════════════════════════\n');
  
  console.log('❌ Fake server:');
  console.log('   - Private key nai');
  console.log('   - Valid signature create korte parbe na');
  console.log('   - App er public key diye check korle fail\n');
  
  console.log('✅ Real bank:');
  console.log('   - Private key ache');
  console.log('   - Valid signature create kore');
  console.log('   - App er public key diye check korle pass\n');
  
  console.log('💡 Simple Logic:');
  console.log('   Private key + Data = Signature');
  console.log('   Public key + Data + Signature = Verify');
  console.log('   Only real bank can create matching signature!\n');
}

// =====================================================
// MAIN - Shob kichu run koro
// =====================================================
async function main() {
  try {
    // Step 1: Login
    const response = await loginToServer();
    
    // Step 2: Extract data
    const { encryptedKey, signature, publicKeyPem } = extractData(response);
    
    // Step 3: Load public key
    const publicKey = loadPublicKey(publicKeyPem);
    
    // Step 4: Verify signature
    const isValid = verifySignature(encryptedKey, signature, publicKey);
    
    // Step 5: Show result
    showResult(isValid);
    
    // Explanation
    showExplanation();
    
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    console.log('\nMake sure backend server running: http://localhost:9000\n');
  }
}

// Run
main();
