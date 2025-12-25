require('dotenv').config();
const { SupportConversation, SupportTicket } = require('../models/supportModel');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini AI (only if API key is valid)
let genAI = null;
let model = null;

const apiKey = process.env.GEMINI_API_KEY ? process.env.GEMINI_API_KEY.trim() : null;

if (apiKey && apiKey !== 'YOUR_API_KEY' && apiKey.length > 20) {
  try {
    genAI = new GoogleGenerativeAI(apiKey);
    model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    console.log('✅ Gemini AI initialized successfully with model: gemini-2.0-flash');
  } catch (error) {
    console.error('Failed to initialize Gemini AI:', error.message);
  }
} else {
  console.warn('⚠️  Gemini API key not configured. Using fallback responses.');
  console.warn('   API key length:', apiKey ? apiKey.length : 0);
  console.warn('   Get your API key from: https://aistudio.google.com/app/apikey');
}

const supportService = {
  // Generate AI response based on user message
  generateAIResponse: async ({ userMessage, userId, context, userHistory }) => {
    try {
      // If Gemini is not available, use fallback immediately
      if (!model) {
        console.log('Gemini AI not available, using fallback responses');
        return await supportService.generateFallbackResponse(userMessage);
      }

      // Get conversation history for context
      const recentConversations = await SupportConversation.find({ userId })
        .sort({ timestamp: -1 })
        .limit(10)
        .select('userMessage aiResponse');

      // Get all indexed conversations for training context
      const allConversations = await SupportConversation.find({})
        .sort({ timestamp: -1 })
        .limit(100)
        .select('userMessage aiResponse context');

      // Build context for Gemini
      const appContext = `You are a helpful customer support AI assistant for AutoVisionHub, a comprehensive automotive community platform. 

AutoVisionHub Features:
- Event Management: Users can create, manage, and attend automotive events with ticket booking
- Live Streaming: Events can be live-streamed using Zego Cloud integration
- Groups & Communities: Users can join groups and participate in discussions
- Marketplace: Buy/sell automotive parts and vehicles
- Discussion Threads: Community members can create and participate in discussion threads
- User Profiles: Manage profiles, settings, and payment information
- Admin Features: Admins can manage users, groups, events, and view reports

Common Support Topics:
- Account management (login, password reset, profile updates)
- Event creation and management
- Live streaming setup and issues
- Group management and permissions
- Marketplace listings and transactions
- Payment and billing
- Technical issues and troubleshooting

Previous App Conversations (for learning):
${allConversations.map(c => `User: ${c.userMessage}\nAssistant: ${c.aiResponse}`).join('\n---\n')}

User's Recent Conversation History:
${recentConversations.map(c => `User: ${c.userMessage}\nAssistant: ${c.aiResponse}`).join('\n')}

Provide helpful, accurate, and friendly responses. If you don't know something specific, be honest and offer to escalate to human support.`;

      // Generate response using Gemini
      const chat = model.startChat({
        history: [
          {
            role: 'user',
            parts: [{ text: appContext }],
          },
          {
            role: 'model',
            parts: [{ text: 'I understand. I am now the AutoVisionHub support assistant with full knowledge of the platform features and previous conversations. I will provide helpful, accurate responses based on this context.' }],
          },
        ],
        generationConfig: {
          maxOutputTokens: 500,
          temperature: 0.7,
        },
      });

      const result = await chat.sendMessage(userMessage);
      const response = result.response.text();

      return response;

    } catch (error) {
      console.error('Error generating Gemini AI response:', error);
      // Fallback to pattern-based responses
      return await supportService.generateFallbackResponse(userMessage);
    }
  },

  // Fallback response generator (pattern-based)
  generateFallbackResponse: async (userMessage) => {
    try {
      // Normalize user message for analysis
      const normalizedMessage = userMessage.toLowerCase().trim();
      
      // Define response categories and patterns
      const responsePatterns = {
        greeting: {
          patterns: ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'],
          responses: [
            "Hello! I'm here to help you with any questions about AutoVisionHub. What can I assist you with today?",
            "Hi there! Welcome to AutoVisionHub support. How can I help you?",
            "Hey! I'm your AutoVisionHub assistant. Feel free to ask me anything about our platform."
          ]
        },
        
        account: {
          patterns: ['account', 'profile', 'login', 'password', 'signup', 'register', 'email', 'username'],
          responses: [
            "I can help you with account-related issues! Are you having trouble with:\n• Logging in\n• Resetting your password\n• Updating your profile\n• Account verification\n\nPlease let me know specifically what you need help with.",
            "For account issues, I can guide you through:\n• Password reset procedures\n• Profile updates\n• Login troubleshooting\n• Account settings\n\nWhat specific account issue are you experiencing?"
          ]
        },
        
        events: {
          patterns: ['event', 'create event', 'manage event', 'event management', 'booking', 'ticket'],
          responses: [
            "I can help you with event-related questions! AutoVisionHub allows you to:\n• Create and manage events\n• Handle bookings and tickets\n• Set up event layouts and seating\n• Manage event visibility\n\nWhat would you like to know about event management?",
            "Event management questions? I can assist with:\n• Creating new events\n• Managing existing events\n• Ticket booking issues\n• Event settings and permissions\n\nWhat specific event feature do you need help with?"
          ]
        },
        
        livestream: {
          patterns: ['live stream', 'livestream', 'streaming', 'broadcast', 'zego', 'recording'],
          responses: [
            "Live streaming questions? I can help with:\n• Setting up live streams for events\n• Troubleshooting streaming issues\n• Managing viewers and permissions\n• Recording and playback\n\nWhat streaming issue can I help you resolve?",
            "For live streaming support:\n• Stream setup and configuration\n• Viewer management\n• Recording functionality\n• Technical streaming issues\n\nWhat specific streaming problem are you facing?"
          ]
        },
        
        groups: {
          patterns: ['group', 'community', 'chat', 'message', 'group chat'],
          responses: [
            "Group and community features:\n• Creating and managing groups\n• Group chat functionality\n• Member management\n• Group permissions and settings\n\nWhat group-related question do you have?",
            "I can help with group features:\n• Setting up new groups\n• Managing group members\n• Group chat and messaging\n• Privacy and permission settings\n\nWhat do you need assistance with?"
          ]
        },
        
        technical: {
          patterns: ['error', 'bug', 'not working', 'broken', 'issue', 'problem', 'crash', 'slow'],
          responses: [
            "I'm sorry you're experiencing technical issues. To help you better:\n• Can you describe what's not working?\n• When did this issue start?\n• What device/browser are you using?\n• Any error messages you're seeing?\n\nThis information will help me provide better assistance.",
            "Technical problems can be frustrating! To troubleshoot:\n• Try refreshing the page or restarting the app\n• Check your internet connection\n• Clear browser cache if using web version\n• Make sure you're using the latest version\n\nIf the issue persists, please describe what's happening."
          ]
        },
        
        payment: {
          patterns: ['payment', 'billing', 'subscription', 'charge', 'refund', 'credit card'],
          responses: [
            "For payment and billing inquiries:\n• Payment processing issues\n• Subscription management\n• Refund requests\n• Billing questions\n\nPayment issues often require account verification. Would you like me to escalate this to our billing team?",
            "Payment-related questions are important! I can help with:\n• Understanding charges\n• Payment method updates\n• Subscription changes\n• Refund policies\n\nFor sensitive billing matters, I can connect you with our billing specialists."
          ]
        },
        
        help: {
          patterns: ['help', 'support', 'assistance', 'guide', 'tutorial', 'how to'],
          responses: [
            "I'm here to help! AutoVisionHub offers:\n• Event management and ticketing\n• Live streaming capabilities\n• Community groups and chat\n• User profiles and settings\n\nWhat specific feature would you like to learn about?",
            "Need guidance? I can explain:\n• How to use different features\n• Step-by-step tutorials\n• Best practices\n• Troubleshooting tips\n\nWhat would you like me to walk you through?"
          ]
        },
        
        thanks: {
          patterns: ['thank', 'thanks', 'appreciate', 'helpful'],
          responses: [
            "You're very welcome! I'm glad I could help. Is there anything else you'd like to know about AutoVisionHub?",
            "Happy to help! If you have any other questions about AutoVisionHub, feel free to ask anytime.",
            "You're welcome! Don't hesitate to reach out if you need more assistance with AutoVisionHub."
          ]
        },
        
        goodbye: {
          patterns: ['bye', 'goodbye', 'see you', 'talk later', 'thanks for the help'],
          responses: [
            "Goodbye! Thanks for using AutoVisionHub support. Have a great day!",
            "See you later! Feel free to come back anytime if you need more help.",
            "Take care! Remember, I'm always here if you need assistance with AutoVisionHub."
          ]
        }
      };
      
      // Find matching pattern
      let bestMatch = null;
      let maxMatches = 0;
      
      for (const [category, config] of Object.entries(responsePatterns)) {
        const matches = config.patterns.filter(pattern => 
          normalizedMessage.includes(pattern)
        ).length;
        
        if (matches > maxMatches) {
          maxMatches = matches;
          bestMatch = category;
        }
      }
      
      // Generate response
      if (bestMatch && maxMatches > 0) {
        const responses = responsePatterns[bestMatch].responses;
        const randomResponse = responses[Math.floor(Math.random() * responses.length)];
        return randomResponse;
      }
      
      // Default response for unmatched queries
      const defaultResponses = [
        "I understand you're asking about something specific. Could you provide more details so I can better assist you? I can help with:\n• Account and profile issues\n• Event management\n• Live streaming\n• Group features\n• Technical problems",
        "I want to make sure I give you the most helpful answer. Could you rephrase your question or provide more context? I'm here to help with all aspects of AutoVisionHub.",
        "I'm not sure I fully understand your question. Could you be more specific? I can assist with account issues, event management, live streaming, groups, and technical support."
      ];
      
      return defaultResponses[Math.floor(Math.random() * defaultResponses.length)];
      
    } catch (error) {
      console.error('Error generating fallback response:', error);
      return "I apologize, but I'm having trouble processing your request right now. Please try again, or if the issue persists, I can connect you with a human support agent.";
    }
  },

  // Log conversation for analytics and improvement
  logConversation: async (conversationData) => {
    try {
      const conversation = new SupportConversation(conversationData);
      await conversation.save();
      return conversation;
    } catch (error) {
      console.error('Error logging conversation:', error);
      // Don't throw error to avoid breaking the chat flow
    }
  },

  // Get conversation history for a user
  getConversationHistory: async (userId, limit = 50) => {
    try {
      return await SupportConversation.find({ userId })
        .sort({ timestamp: -1 })
        .limit(limit)
        .select('userMessage aiResponse timestamp context');
    } catch (error) {
      console.error('Error getting conversation history:', error);
      throw error;
    }
  },

  // Submit feedback on AI response
  submitFeedback: async (feedbackData) => {
    try {
      const conversation = await SupportConversation.findById(feedbackData.conversationId);
      if (conversation) {
        conversation.feedback = {
          rating: feedbackData.rating,
          comment: feedbackData.feedback,
          submittedAt: new Date()
        };
        await conversation.save();
      }
    } catch (error) {
      console.error('Error submitting feedback:', error);
      throw error;
    }
  },

  // Create support ticket for escalation
  createSupportTicket: async (ticketData) => {
    try {
      const ticket = new SupportTicket({
        ...ticketData,
        status: 'open',
        createdAt: new Date()
      });
      await ticket.save();
      return ticket;
    } catch (error) {
      console.error('Error creating support ticket:', error);
      throw error;
    }
  }
};

module.exports = supportService;