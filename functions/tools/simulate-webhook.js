require('dotenv').config();
const crypto = require('crypto');
const axios = require('axios');

const secret = process.env.CHARGILY_SECRET_KEY || 'test_sk_CVIutOPoR8ixglwfJt4i7KqpjC9oItZnWgpEQK6o';

const payload = {
  type: 'checkout.paid',
  data: {
    status: 'paid',
    metadata: { userId: process.env.UID || 'test-user', planType: process.env.PLAN || 'monthly' }
  }
};

const body = JSON.stringify(payload);
const signature = crypto.createHmac('sha256', secret).update(body, 'utf8').digest('hex');

const url = process.env.WEBHOOK_URL || 'http://127.0.0.1:5001/macroaize/europe-west1/chargilyWebhook';
console.log('Posting to', url);

axios.post(url, body, {
  headers: {
    'Content-Type': 'application/json',
    'x-chargily-signature': signature
  },
  transformRequest: [(data) => data], // send body as-is
}).then((r) => {
  console.log('Status:', r.status);
  console.log('Response:', typeof r.data === 'string' ? r.data : JSON.stringify(r.data));
}).catch((e) => {
  if (e.response) {
    console.error('Error Status:', e.response.status);
    console.error('Error Body:', e.response.data);
  } else {
    console.error('Error:', e.message);
  }
});
