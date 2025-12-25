const express = require('express');
const router = express.Router();
const zegoController = require('../controllers/zegoController');

// Test endpoint to verify ZEGO routes are working
router.get('/test', (req, res) => {
  console.log('✅ ZEGO test endpoint called');
  res.json({ 
    status: 'success', 
    message: 'ZEGO webhook routes are working',
    timestamp: new Date().toISOString()
  });
});

// Webhook endpoint for ZEGO callbacks - catch all methods to debug
router.all('/webhook', zegoController.handleWebhook);

// Also handle GET requests to webhook for testing
router.get('/webhook', (req, res) => {
  console.log('🔍 GET request to ZEGO webhook endpoint');
  res.json({ 
    status: 'webhook_ready',
    message: 'ZEGO webhook endpoint is accessible',
    expected_method: 'POST'
  });
});

module.exports = router;