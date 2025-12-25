const geminiChatbotService = require('../services/geminiChatbotService');
const { liveStreamService } = require('../services/liveStreamService');
const Event = require('../models/events/eventModel');

/**
 * Handle ZEGO webhook callbacks
 */
exports.handleWebhook = async (req, res) => {
  try {
    console.log('\n🔔 ZEGO WEBHOOK RECEIVED at:', new Date().toISOString());
    console.log('Method:', req.method);
    console.log('URL:', req.url);
    console.log('Headers:', req.headers);
    console.log('Body:', JSON.stringify(req.body, null, 2));

    const { event_type, payload } = req.body;

    // Try to find message content in any format
    let messagePayload = null;
    
    // Check various possible ZEGO webhook formats
    if (event_type === 'kZegoCallbackCommandIMTextMsg' || 
        event_type === 'im_text_msg' ||
        event_type === 'text_message' ||
        payload?.msg_type === 'text') {
      
      messagePayload = payload || req.body;
      console.log('✅ Message event detected via event_type');
    } 
    // Check if the whole body is the message payload
    else if (req.body.room_id && req.body.msg_content) {
      messagePayload = req.body;
      console.log('✅ Message detected in root body');
    }
    // Check if there's a messages array
    else if (req.body.messages && req.body.messages.length > 0) {
      messagePayload = req.body.messages[0];
      console.log('✅ Message detected in messages array');
    }

    if (messagePayload) {
      console.log('📨 Processing message payload...');
      await handleChatMessage(messagePayload);
    } else {
      console.log('ℹ️ No message content found in webhook payload');
    }

    // Respond to ZEGO that webhook was received
    res.status(200).json({ 
      success: true, 
      timestamp: new Date().toISOString(),
      processed: true 
    });

  } catch (error) {
    console.error('❌ Error handling ZEGO webhook:', error);
    res.status(500).json({ 
      error: 'Webhook processing failed',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Process chat message from ZEGO webhook
 */
async function handleChatMessage(payload) {
  try {
    console.log('\n💬 PROCESSING ZEGO CHAT MESSAGE');
    
    const {
      room_id,
      from_userid,
      from_username,
      msg_content,
      msg_seq,
      msg_timestamp
    } = payload;

    console.log('Room ID:', room_id);
    console.log('User ID:', from_userid);
    console.log('Username:', from_username);
    console.log('Message:', msg_content);

    // Skip if message is from bot
    if (from_userid === 'chatbot_ai' || from_username?.includes('🤖')) {
      console.log('🤖 Skipping bot message');
      return;
    }

    // Get event context first to check ownership
    const event = await getEventFromRoomId(room_id);
    
    // Skip if message is from event owner (they don't need bot help for their own event)
    if (event && event.organizer && event.organizer.toString() === from_userid) {
      console.log('👑 Skipping message from event owner');
      return;
    }

    // Check if message should trigger chatbot
    if (!geminiChatbotService.shouldRespond(msg_content)) {
      console.log('❌ Message should not trigger bot');
      return;
    }

    console.log('✅ Message should trigger bot');
    
    // Generate bot response
    const botResponseData = await geminiChatbotService.processLiveStreamMessage({
      message: msg_content,
      userName: from_username,
      userId: from_userid
    }, event);

    if (botResponseData && botResponseData.message) {
      console.log('🤖 Bot response generated:', botResponseData.message);
      
      // Send response back to ZEGO room
      await sendMessageToZegoRoom(room_id, botResponseData.message);
    }

  } catch (error) {
    console.error('❌ Error processing chat message:', error);
  }
}

/**
 * Get event details from room ID
 */
async function getEventFromRoomId(roomId) {
  try {
    // Try to find live stream by room ID
    const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
    if (liveStream && liveStream.eventId) {
      return await Event.findById(liveStream.eventId);
    }
    return null;
  } catch (error) {
    console.error('Error getting event from room ID:', error);
    return null;
  }
}

/**
 * Send message to ZEGO room via Socket.IO
 */
async function sendMessageToZegoRoom(roomId, message) {
  try {
    console.log('📤 Sending bot message to room:', roomId);
    console.log('🤖 Bot message:', message);
    
    // Get socket.io instance from the socketConfig
    const socketConfig = require('../config/socket');
    const io = socketConfig.getIO();
    
    if (io) {
      // Send bot message to all users in the live stream room
      io.to(roomId).emit('chatbot_response', {
        message: message,
        userId: 'chatbot_ai',
        userName: '🤖 AI Assistant',
        timestamp: new Date(),
        type: 'bot_message'
      });
      
      console.log('✅ Bot message sent via Socket.IO to room:', roomId);
    } else {
      console.error('❌ Socket.IO instance not available');
    }
    
  } catch (error) {
    console.error('❌ Error sending message via Socket.IO:', error);
  }
}