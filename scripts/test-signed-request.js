#!/usr/bin/env node
/**
 * Test Signed API Request
 * Run: node test-signed-request.js
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');

console.log('🔐 Testing Signed API Request');
console.log('════════════════════════════════════════════════════\n');

// Step 1: Load device info
console.log('STEP 1: Loading Device Info');
console.log('─────────────────────────────────\n');

const files = fs.readdirSync('.').filter(f => f.startsWith('device-device_'));
if (files.length === 0) {
  console.log('❌ No device file found!');
  console.log('   Run: node register-device.js first\n');
  process.exit(1);
}

const deviceFile = files[0];
const deviceInfo = JSON.parse(fs.readFileSync(deviceFile, 'utf8'));

console.log('✅ Device info loaded');
console.log(`   File: ${deviceFile}`);
console.log(`   Device ID: ${deviceInfo.device_id}\n`);

// Step 2: Login to get fresh JWT
console.log('STEP 2: Login to Get JWT');
console.log('─────────────────────────────────\n');

function login() {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      email: 'reader@demo-bank.com',
      password: 'reader123'
    });
    
    const options = {
      hostname: 'localhost',
      port: 9000,
      path: '/api/v1/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        'Origin': 'http://localhost:3000'
      }
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const result = JSON.parse(data);
        console.log('✅ Login successful');
        console.log(`   JWT: ${result.token.substring(0, 40)}...\n`);
        resolve(result.token);
      });
    });
    
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Step 3: Make signed request
function makeSignedRequest(jwt, deviceId, privateKey) {
  return new Promise((resolve, reject) => {
    console.log('STEP 3: Creating Signed Request');
    console.log('──────────────────────────────────\n');
    
    // Request body - Valid encrypted QR
    const requestBody = {
      token: "63240e64-e192-446d-95d5-656fff03d911",
      password: "test123"  // Demo encryption password
    };
    
    const requestString = JSON.stringify(requestBody);
    console.log('Request body:', requestString);
    console.log('');
    
    // Create timestamp
    const timestamp = Date.now().toString();
    const method = 'POST';
    const path = '/api/v1/app/decrypt-qr';
    
    // Construct signed data: METHOD|PATH|TIMESTAMP|BODY
    const signedData = `${method}|${path}|${timestamp}|${requestString}`;
    
    console.log('Signing data:');
    console.log(`   ${signedData.substring(0, 60)}...\n`);
    
    // Sign the request
    console.log('Signing with private key...');
    const sign = crypto.createSign('SHA256');
    sign.update(signedData);
    sign.end();
    
    const signature = sign.sign({
      key: privateKey,
      padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
      saltLength: 32
    });
    
    const signatureBase64 = signature.toString('base64');
    console.log('✅ Signature created');
    console.log(`   Signature: ${signatureBase64.substring(0, 40)}...\n`);
    
    // Make request
    console.log('STEP 4: Sending to Backend');
    console.log('───────────────────────────\n');
    
    console.log('Headers:');
    console.log(`   Authorization: Bearer ${jwt.substring(0, 30)}...`);
    console.log(`   X-Signature: ${signatureBase64.substring(0, 30)}...`);
    console.log(`   X-Device-ID: ${deviceId}`);
    console.log(`   X-Timestamp: ${timestamp}`);
    console.log('');
    
    const options = {
      hostname: 'localhost',
      port: 9000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestString),
        'Authorization': `Bearer ${jwt}`,
        'X-Signature': signatureBase64,
        'X-Device-ID': deviceId,
        'X-Timestamp': timestamp,
        'Origin': 'http://localhost:3000'
      }
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log('STEP 5: Backend Response');
        console.log('─────────────────────────\n');
        
        console.log(`Status: ${res.statusCode}`);
        console.log(`Body: ${data}\n`);
        
        if (res.statusCode === 200) {
          console.log('✅ SUCCESS! Request verified!');
          console.log('\nBackend verified:');
          console.log('  ✓ JWT valid');
          console.log('  ✓ Device registered');
          console.log('  ✓ Signature matches');
          console.log('  → Request accepted!\n');
        } else {
          console.log('⚠️  Request failed');
          console.log(`   Reason: ${data}\n`);
        }
        
        resolve({ status: res.statusCode, body: data });
      });
    });
    
    req.on('error', reject);
    req.write(requestString);
    req.end();
  });
}

// Main
async function main() {
  try {
    const jwt = await login();
    await makeSignedRequest(jwt, deviceInfo.device_id, deviceInfo.private_key);
    
    console.log('════════════════════════════════════════════════════');
    console.log('✅ TEST COMPLETE!');
    console.log('════════════════════════════════════════════════════\n');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();
