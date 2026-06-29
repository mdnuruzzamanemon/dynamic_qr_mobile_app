#!/usr/bin/env node
/**
 * Test Device Signature Only (No QR Password)
 * Run: node test-device-signature.js
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');

console.log('🔐 Testing Device Signature (No Password)');
console.log('════════════════════════════════════════════════════\n');

// Step 1: Load device info
const files = fs.readdirSync('.').filter(f => f.startsWith('device-device_'));
if (files.length === 0) {
  console.log('❌ No device file found!\n');
  process.exit(1);
}

const deviceFile = files[0];
const deviceInfo = JSON.parse(fs.readFileSync(deviceFile, 'utf8'));

console.log('✅ Device info loaded');
console.log(`   Device ID: ${deviceInfo.device_id}\n`);

// Step 2: Login
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
        console.log('✅ Login successful\n');
        resolve(result.token);
      });
    });
    
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Step 3: Get user profile (no password needed, just signature)
function getUserProfile(jwt, deviceId, privateKey) {
  return new Promise((resolve, reject) => {
    console.log('STEP: Get User Profile (Signature Required)');
    console.log('────────────────────────────────────────────\n');
    
    const method = 'GET';
    const path = '/api/v1/user/profile';
    const timestamp = Date.now().toString();
    const body = '';
    
    // Sign: METHOD|PATH|TIMESTAMP|BODY
    const signedData = `${method}|${path}|${timestamp}|${body}`;
    
    console.log('Signing data:', signedData);
    
    const sign = crypto.createSign('SHA256');
    sign.update(signedData);
    sign.end();
    
    const signature = sign.sign({
      key: privateKey,
      padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
      saltLength: 32
    });
    
    const signatureBase64 = signature.toString('base64');
    console.log('✅ Signature created\n');
    
    console.log('Headers:');
    console.log(`   Authorization: Bearer ${jwt.substring(0, 30)}...`);
    console.log(`   X-Signature: ${signatureBase64.substring(0, 30)}...`);
    console.log(`   X-Device-ID: ${deviceId}`);
    console.log(`   X-Timestamp: ${timestamp}\n`);
    
    const options = {
      hostname: 'localhost',
      port: 9000,
      path: path,
      method: method,
      headers: {
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
        console.log('Backend Response');
        console.log('─────────────────\n');
        console.log(`Status: ${res.statusCode}`);
        
        try {
          const json = JSON.parse(data);
          console.log('Body:', JSON.stringify(json, null, 2));
        } catch {
          console.log('Body:', data);
        }
        
        console.log('');
        
        if (res.statusCode === 200) {
          console.log('✅ SUCCESS! Device Signature Verified!');
          console.log('\nBackend verified:');
          console.log('  ✓ JWT valid');
          console.log('  ✓ Device registered');
          console.log('  ✓ Signature matches');
          console.log('  → Request accepted!\n');
        } else {
          console.log('❌ Failed:', data, '\n');
        }
        
        resolve({ status: res.statusCode, body: data });
      });
    });
    
    req.on('error', reject);
    req.end();
  });
}

// Main
async function main() {
  try {
    const jwt = await login();
    await getUserProfile(jwt, deviceInfo.device_id, deviceInfo.private_key);
    
    console.log('════════════════════════════════════════════════════');
    console.log('✅ DEVICE SIGNATURE TEST COMPLETE!');
    console.log('════════════════════════════════════════════════════\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

main();
