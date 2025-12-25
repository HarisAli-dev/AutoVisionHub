const axios = require('axios');
require('dotenv').config();

class GeminiChatbotService {
  constructor() {
    this.apiKey = process.env.GEMINI_API_KEY;
    this.apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
    
    // System prompt that defines the chatbot's behavior
    this.systemPrompt = `
You are an AI assistant for a Community Hub application that includes:
- Marketplace: Buy, sell, and bid on items
- Events: Create, manage, and attend events with live streaming
- Groups: Community discussions and chat
- One-on-one Chats: Private messaging

You are currently assisting in a live stream event. Your role is to:
1. Answer questions about the application features
2. Help users navigate the app
3. Provide information about events, marketplace, and community features
4. Be friendly, helpful, and EXTREMELY concise
5. If you don't know something specific about the event, acknowledge it and offer to help with general app questions

CRITICAL: Keep responses VERY SHORT - maximum 1-2 sentences (20-30 words). Be direct and to the point. Use simple language. Avoid explanations unless asked.
`;
  }

  /**
   * Check if the chatbot should respond to a message
   */
  shouldRespond(message) {
    if (!message || typeof message !== 'string') return false;
    
    const lowerMessage = message.toLowerCase();
    return (
      lowerMessage.includes('bot') ||
      lowerMessage.includes('help') ||
      lowerMessage.includes('?') ||
      lowerMessage.includes('how') ||
      lowerMessage.includes('what') ||
      lowerMessage.includes('where')
    );
  }

  /**
   * Generate event context for the chatbot
   */
  generateEventContext(event) {
    if (!event) return '';
    
    return `
Current Event Context:
- Event: ${event.eventName || 'Live Stream'}
- Description: ${event.eventDescription || 'Community live stream'}
- Location: ${event.eventLocation || 'Online'}
- Date: ${event.eventDateTime ? new Date(event.eventDateTime).toLocaleDateString() : 'Now'}
`;
  }

  /**
   * Generate response using Gemini AI
   */
  async generateResponse(message, eventContext = '', chatHistory = []) {
    try {
      console.log('\n🤖 GEMINI API CALL');
      console.log('Message:', message);
      console.log('Has event context:', !!eventContext);
      console.log('Chat history length:', chatHistory.length);

      if (!this.apiKey) {
        console.log('❌ Gemini API key not configured');
        return 'Chatbot is not configured. Please contact support.';
      }

      // Build conversation context
      let contextPrompt = this.systemPrompt;
      if (eventContext) {
        contextPrompt += '\n\n' + eventContext;
      }

      // Build contents array for Gemini API
      const contents = [];

      // Add system context as first user message
      contents.push({
        role: 'user',
        parts: [{ text: contextPrompt }]
      });

      // Add model response acknowledging the context
      contents.push({
        role: 'model',
        parts: [{ 
          text: 'I understand. I\'m ready to assist users with questions about the Community Hub app and this live stream event.' 
        }]
      });

      // Add recent chat history (last 5 messages for context)
      if (chatHistory && chatHistory.length > 0) {
        const recentHistory = chatHistory.slice(-5);
        for (const msg of recentHistory) {
          contents.push({
            role: msg.role === 'user' ? 'user' : 'model',
            parts: [{ text: msg.message || '' }]
          });
        }
      }

      // Add current user message
      contents.push({
        role: 'user',
        parts: [{ text: message }]
      });

      console.log('📦 Request payload prepared');
      console.log('🌍 Making API request to Gemini...');

      const requestBody = {
        contents: contents,
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 500
        },
        safetySettings: [
          {
            category: 'HARM_CATEGORY_HARASSMENT',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            category: 'HARM_CATEGORY_HATE_SPEECH',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
            threshold: 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      const response = await axios.post(
        `${this.apiUrl}?key=${this.apiKey}`,
        requestBody,
        {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );

      console.log('📡 API Response status:', response.status);

      if (response.status === 200 && response.data) {
        const data = response.data;
        console.log('✅ Response decoded successfully');
        console.log('🔍 Full API Response:', JSON.stringify(data, null, 2));

        if (data.candidates && data.candidates.length > 0) {
          const candidate = data.candidates[0];
          console.log('🔍 Candidate structure:', JSON.stringify(candidate, null, 2));
          
          // Check for MAX_TOKENS finish reason
          if (candidate.finishReason === 'MAX_TOKENS') {
            console.log('⚠️ Response was truncated due to token limit');
          }
          
          if (candidate.content && candidate.content.parts && candidate.content.parts.length > 0) {
            const text = candidate.content.parts[0].text;
            console.log('💬 Generated response:', text);
            return text;
          } else {
            console.log('❌ No content parts found in response');
            return 'I\'m having trouble generating a response right now. Could you try rephrasing your question?';
          }
        }

        console.log('⚠️ Unexpected response format');
        console.log('Available keys:', Object.keys(data));
        return 'Sorry, I received an unexpected response. Please try again.';
      } else {
        console.log('❌ API error:', response.status);
        return 'Sorry, I\'m having trouble connecting right now. Please try again later.';
      }
    } catch (error) {
      console.error('❌ Error in Gemini API call:', error.message);
      if (error.response) {
        console.error('Error status:', error.response.status);
        console.error('Error data:', error.response.data);
      }
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  /**
   * Process a livestream message and generate bot response if needed
   */
  async processLiveStreamMessage(messageData, event = null) {
    try {
      const { message, userName, userId } = messageData;
      
      console.log('\n🔍 PROCESSING LIVESTREAM MESSAGE');
      console.log('Message:', message);
      console.log('User:', userName);
      console.log('Should respond:', this.shouldRespond(message));

      // Check if bot should respond
      if (!this.shouldRespond(message)) {
        return null;
      }

      // Generate event context
      const eventContext = this.generateEventContext(event);

      // Generate response
      const botResponse = await this.generateResponse(message, eventContext, []);

      if (botResponse) {
        return {
          message: botResponse,
          userId: 'chatbot_ai',
          userName: '🤖 AI Assistant',
          isBot: true,
          timestamp: new Date()
        };
      }

      return null;
    } catch (error) {
      console.error('❌ Error processing livestream message:', error);
      return null;
    }
  }
}

module.exports = new GeminiChatbotService();