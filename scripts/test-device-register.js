const http = require('http');
const crypto = require('crypto');

// Your JWT token
const TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODMyNzkwNDgsInJvbGUiOiJxcl9yZWFkZXIiLCJzdWIiOiJhYjliZDYwOS1iODliLTQ2YzgtOWFhNS0wNDE2ZDcwZDJlMmIifQ.2qo-L_1N-kq9aacIdaC3lLCmeZACiS_Fzd4FuhStsTE';

console.log('🔑 Testing Device Registration');
console.log('================================\n');

// Step 1: Generate real RSA key pair
console.log('Step 1: Generating RSA key pair...');
const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
});

console.log('✅ Key pair generated');
console.log('Public key:', publicKey.substring(0, 60) + '...\n');

// Step 2: Prepare request
const deviceId = 'nodejs_test_' + Date.now();
const requestBody = JSON.stringify({
  device_id: deviceId,
  public_key_pem: publicKey,
  device_name: 'Node.js Test Device',
  platform: 'android'
});

console.log('Step 2: Preparing request...');
console.log('Device ID:', deviceId);
console.log('');

// Step 3: Send request
console.log('Step 3: Sending to backend...');

const options = {
  hostname: 'localhost',
  port: 9000,
  path: '/api/v1/app/register-certificate',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(requestBody),
    'Authorization': `Bearer ${TOKEN}`,
    'Origin': 'http://localhost:3000'
  }
};

const req = http.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('\nResponse:');
    console.log('Status:', res.statusCode);
    console.log('Body:', data);
    console.log('');
    
    if (res.statusCode === 200 || res.statusCode === 201) {
      console.log('✅ SUCCESS! Device registered!');
      console.log('');
      console.log('Private key (save this):');
      console.log(privateKey);
      console.log('');
      console.log('Next step: Use this private key to sign requests');
    } else {
      console.log('❌ Failed to register');
      console.log('Check error message above');
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
});

req.write(requestBody);
req.end();
