const admin = require('firebase-admin');
const User = require('../models/users/userModel');

// Ensure dotenv is loaded
require('dotenv').config();

// Initialize Firebase Admin SDK with environment variables
if (!admin.apps.length) {
  try {
    // Check if all required environment variables are present
    const requiredEnvVars = [
      'FIREBASE_PROJECT_ID',
      'FIREBASE_PRIVATE_KEY_ID', 
      'FIREBASE_PRIVATE_KEY',
      'FIREBASE_CLIENT_EMAIL',
      'FIREBASE_CLIENT_ID'
    ];

    const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
      console.error('Missing Firebase environment variables:', missingVars);
      throw new Error(`Missing Firebase environment variables: ${missingVars.join(', ')}`);
    }

    admin.initializeApp({
      credential: admin.credential.cert({
        type: "service_account",
        project_id: process.env.FIREBASE_PROJECT_ID,
        private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
        private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        client_id: process.env.FIREBASE_CLIENT_ID,
        auth_uri: "https://accounts.google.com/o/oauth2/auth",
        token_uri: "https://oauth2.googleapis.com/token",
        auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
        client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL.replace('@', '%40')}`,
        universe_domain: "googleapis.com"
      }),
    });
    
    console.log('Firebase Admin SDK initialized successfully');
  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error.message);
    // Don't throw error here to prevent server crash, just log it
  }
}

/**
 * Send push notification to a user
 * @param {string} userId - The ID of the user to send notification to
 * @param {Object} notification - Notification data
 * @param {Object} data - Additional data for deep linking
 */
const sendNotificationToUser = async (userId, notification, data = {}) => {
  try {
    // Get user's FCM token from database
    const user = await User.findById(userId);
    if (!user || !user.fcmToken) {
      console.log(`No FCM token found for user ${userId}`);
      return;
    }

    const messagePayload = {
      token: user.fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        ...data,
        click_action: data.route || '',
        sound: 'default',
        // Include sender info for custom notification display
        senderName: data.senderName || '',
        profileImageUrl: notification.imageUrl || '',
      },
      android: {
        notification: {
          channelId: 'default',
          sound: 'default',
          priority: 'high',
          defaultSound: true,
          // Add image URL for Android
          imageUrl: notification.imageUrl && notification.imageUrl.startsWith('http') 
            ? notification.imageUrl 
            : undefined,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
        fcm_options: {
          // Add image for iOS
          image: notification.imageUrl && notification.imageUrl.startsWith('http') 
            ? notification.imageUrl 
            : undefined,
        },
      },
    };

    // Only add imageUrl if it's a valid URL (removed - handled in payload above)

    const response = await admin.messaging().send(messagePayload);
    console.log('Successfully sent message:', response);
    return response;
  } catch (error) {
    console.error('Error sending notification:', error.message);
    if (error.code === 'messaging/registration-token-not-registered') {
      console.log('FCM token is invalid, removing from user...');
      // Remove invalid token
      await User.findByIdAndUpdate(userId, { $unset: { fcmToken: 1 } });
    }
    throw error;
  }
};

/**
 * Send notification for new chat message
 * @param {string} recipientId - ID of the message recipient
 * @param {Object} sender - Sender information
 * @param {Object} message - Message data
 * @param {Object} chat - Chat information
 */
const sendChatMessageNotification = async (recipientId, sender, message, chat) => {
  try {
    const notification = {
      title: sender.name || 'New Message',
      body: message.type === 'text' 
        ? message.content 
        : getMessageTypeText(message.type),
      imageUrl: sender.profileImageUrl || null,
    };

    const data = {
      type: 'chat_message',
      chatId: chat._id.toString(),
      chatName: chat.name || sender.name,
      senderId: sender._id.toString(),
      senderName: sender.name,
      messageId: message._id.toString(),
      route: '/chat',
    };

    await sendNotificationToUser(recipientId, notification, data);
  } catch (error) {
    console.error('Error sending chat message notification:', error);
  }
};

/**
 * Send notification for new group message
 * @param {string} recipientId - ID of the message recipient
 * @param {Object} sender - Sender information
 * @param {Object} message - Message data
 * @param {Object} group - Group information
 */
const sendGroupMessageNotification = async (recipientId, sender, message, group) => {
  try {
    const notification = {
      title: group.groupName || 'New Group Message',
      body: `${sender.name}: ${message.type === 'text' 
        ? message.content 
        : getMessageTypeText(message.type)}`,
      imageUrl: group.groupImageUrl || null,
    };

    const data = {
      type: 'group_message',
      groupId: group._id.toString(),
      groupName: group.groupName || 'Group',
      senderId: sender._id.toString(),
      senderName: sender.name,
      messageId: message._id.toString(),
      currentUserId: recipientId,
      groupImage: group.groupImageUrl || '',
      route: '/group',
    };

    await sendNotificationToUser(recipientId, notification, data);
  } catch (error) {
    console.error('Error sending group message notification:', error);
  }
};

/**
 * Get readable text for different message types
 * @param {string} messageType - Type of message
 * @returns {string} Readable message text
 */
const getMessageTypeText = (messageType) => {
  const messageTypes = {
    image: '📷 Image',
    video: '🎥 Video',
    voice: '🎤 Voice message',
    file: '📁 File',
    call: '📞 Call',
  };
  
  return messageTypes[messageType] || 'New message';
};

/**
 * Send notification for event updates
 * @param {Array} userIds - Array of user IDs to notify
 * @param {Object} notification - Notification data
 * @param {Object} event - Event information
 */
const sendEventNotification = async (userIds, notification, event) => {
  try {
    const data = {
      type: 'event_update',
      eventId: event._id.toString(),
      route: '/event',
    };

    // Send to all users
    const promises = userIds.map(userId => 
      sendNotificationToUser(userId, notification, data)
    );
    
    await Promise.all(promises);
  } catch (error) {
    console.error('Error sending event notification:', error);
  }
};

/**
 * Update user's FCM token
 * @param {string} userId - User ID
 * @param {string} fcmToken - FCM token
 */
const updateUserFCMToken = async (userId, fcmToken) => {
  try {
    await User.findByIdAndUpdate(userId, { fcmToken });
    console.log(`FCM token updated for user ${userId}`);
  } catch (error) {
    console.error('Error updating FCM token:', error);
    throw error;
  }
};

module.exports = {
  sendNotificationToUser,
  sendChatMessageNotification,
  sendGroupMessageNotification,
  sendEventNotification,
  updateUserFCMToken,
  getMessageTypeText,
};