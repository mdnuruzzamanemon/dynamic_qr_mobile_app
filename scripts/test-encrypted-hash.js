#!/usr/bin/env node
/**
 * Test Encrypted QR Hash Payload
 * Run: node test-encrypted-hash.js
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');

console.log('🔐 Testing Encrypted QR Hash Payload');
console.log('════════════════════════════════════════════════════\n');

// Encrypted hash from QR
const ENCRYPTED_HASH = 'f0ZUbefQ3ZMicugaQwjT7kL68K4znPc5KZf56uDEfl1x6OYK5QLwHs2dtNEcQ9d-TYhAbDmmTvQ2i8wUtOC9KZXnpNnbmbhgMBimFYyk7p7hE7J3Jvo0ykFkzOY2fxGhZxdf3_4z7eRUbXB_0i9IoKolfXE';

// Load device keys
const files = fs.readdirSync('.').filter(f => f.startsWith('device-device_'));
if (files.length === 0) {
  console.log('❌ No device file found!\n');
  process.exit(1);
}

const deviceFile = files[0];
const deviceInfo = JSON.parse(fs.readFileSync(deviceFile, 'utf8'));

console.log('Device loaded:', deviceInfo.device_id);
console.log('Testing hash:', ENCRYPTED_HASH.substring(0, 50) + '...\n');

// Step 1: Login
function login() {
  return new Promise((resolve, reject) => {
    console.log('STEP 1: Login');
    console.log('──────────────\n');
    
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
        console.log('✅ Login successful\n');
        resolve(result);
      });
    });
    
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Step 2: POST encrypted hash to backend
function postEncryptedHash(jwt, deviceId, privateKey, hash) {
  return new Promise((resolve, reject) => {
    console.log('STEP 2: POST Encrypted Hash to Backend');
    console.log('────────────────────────────────────────\n');
    
    const method = 'POST';
    const path = '/api/v1/app/decrypt-hash';
    const timestamp = Date.now().toString();
    
    const requestBody = {
      encrypted_payload: hash
    };
    
    const requestString = JSON.stringify(requestBody);
    
    // Sign request
    const signedData = `${method}|${path}|${timestamp}|${requestString}`;
    const sign = crypto.createSign('SHA256');
    sign.update(signedData);
    sign.end();
    
    const signature = sign.sign({
      key: privateKey,
      padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
      saltLength: 32
    });
    
    const signatureBase64 = signature.toString('base64');
    
    console.log('Request:');
    console.log(`  POST ${path}`);
    console.log(`  Body: { encrypted_payload: "${hash.substring(0, 30)}..." }\n`);
    
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
        console.log('Backend Response:');
        console.log(`  Status: ${res.statusCode}`);
        console.log(`  Body: ${data}\n`);
        
        if (res.statusCode === 200) {
          console.log('✅ SUCCESS!\n');
          try {
            const result = JSON.parse(data);
            console.log('Decrypted Document:');
            console.log(JSON.stringify(result, null, 2));
          } catch (e) {
            console.log(data);
          }
        } else {
          console.log('❌ Failed\n');
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
    const loginResponse = await login();
    await postEncryptedHash(
      loginResponse.token,
      deviceInfo.device_id,
      deviceInfo.private_key,
      ENCRYPTED_HASH
    );
    
    console.log('\n════════════════════════════════════════════════════');
    console.log('✅ TEST COMPLETE!');
    console.log('════════════════════════════════════════════════════\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
