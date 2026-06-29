#!/usr/bin/env node
/**
 * Complete Device Registration Script
 * Run: node register-device.js
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');

console.log('🔐 Complete Device Registration Flow');
console.log('════════════════════════════════════════════════════\n');

// Step 1: Login
async function login() {
  console.log('STEP 1: Login as QR Reader');
  console.log('─────────────────────────────────\n');
  
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
        if (result.token) {
          console.log('✅ Login successful!');
          console.log(`   JWT: ${result.token.substring(0, 40)}...\n`);
          resolve(result.token);
        } else {
          reject('Login failed');
        }
      });
    });
    
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Step 2: Generate Keys
function generateKeys() {
  console.log('STEP 2: Generate RSA Key Pair');
  console.log('─────────────────────────────────\n');
  
  const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
  });
  
  console.log('✅ Key pair generated');
  console.log(`   Public key: ${publicKey.substring(0, 50)}...\n`);
  
  return { publicKey, privateKey };
}

// Step 3: Register Device
async function registerDevice(token, publicKey) {
  console.log('STEP 3: Register Device with Backend');
  console.log('──────────────────────────────────────\n');
  
  const deviceId = 'device_' + Date.now();
  
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      device_id: deviceId,
      public_key_pem: publicKey,
      device_name: 'Node.js Registered Device',
      platform: 'android'
    });
    
    const options = {
      hostname: 'localhost',
      port: 9000,
      path: '/api/v1/app/register-certificate',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        'Authorization': `Bearer ${token}`,
        'Origin': 'http://localhost:3000'
      }
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log(`Response Status: ${res.statusCode}`);
        console.log(`Response Body: ${data}\n`);
        
        if (res.statusCode === 201 || res.statusCode === 200) {
          console.log('✅ Device registered successfully!');
          console.log(`   Device ID: ${deviceId}\n`);
          resolve({ deviceId, response: data });
        } else {
          reject(`Registration failed: ${data}`);
        }
      });
    });
    
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Step 4: Save Keys
function saveKeys(deviceId, publicKey, privateKey) {
  console.log('STEP 4: Save Keys to File');
  console.log('──────────────────────────\n');
  
  const config = {
    device_id: deviceId,
    public_key: publicKey,
    private_key: privateKey,
    registered_at: new Date().toISOString()
  };
  
  const filename = `device-${deviceId}.json`;
  fs.writeFileSync(filename, JSON.stringify(config, null, 2));
  
  console.log(`✅ Keys saved to: ${filename}\n`);
  
  return filename;
}

// Main
async function main() {
  try {
    // Step 1: Login
    const token = await login();
    
    // Step 2: Generate keys
    const { publicKey, privateKey } = generateKeys();
    
    // Step 3: Register
    const { deviceId } = await registerDevice(token, publicKey);
    
    // Step 4: Save
    const filename = saveKeys(deviceId, publicKey, privateKey);
    
    // Summary
    console.log('════════════════════════════════════════════════════');
    console.log('✅ REGISTRATION COMPLETE!');
    console.log('════════════════════════════════════════════════════\n');
    
    console.log('Device Information:');
    console.log(`  Device ID: ${deviceId}`);
    console.log(`  Keys saved: ${filename}`);
    console.log(`  Status: Registered ✅\n`);
    
    console.log('Next Steps:');
    console.log('  1. Keep private key safe');
    console.log('  2. Use device_id and private_key to sign requests');
    console.log('  3. Include X-Device-Signature header in API calls\n');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

// Run
main();
