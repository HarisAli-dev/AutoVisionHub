import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:front/config/app_config.dart';

/// Service for Gemini AI Chatbot integration in live streams
class GeminiChatbotService {
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// System prompt that defines the chatbot's behavior and knowledge
  static const String _systemPrompt = '''
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
''';

  /// Generate a response from Gemini AI
  static Future<String?> generateResponse({
    required String userMessage,
    String? eventContext,
    List<Map<String, String>>? chatHistory,
  }) async {
    debugPrint('\n========================================');
    debugPrint('🌐 GEMINI API CALL');
    debugPrint('User message: "$userMessage"');
    debugPrint('Has event context: ${eventContext != null}');
    debugPrint('Chat history length: ${chatHistory?.length ?? 0}');

    try {
      final apiKey = AppConfig.geminiApiKey;

      debugPrint(
        '🔑 API Key status: ${apiKey.isEmpty ? "❌ EMPTY" : "✅ Configured (${apiKey.length} chars)"}',
      );

      if (apiKey.isEmpty) {
        debugPrint('❌ Gemini API key not configured');
        return 'Chatbot is not configured. Please contact support.';
      }

      // Build conversation context
      String contextPrompt = _systemPrompt;

      if (eventContext != null) {
        contextPrompt += '\n\nCurrent Event Context:\n$eventContext';
      }

      // Build chat history for context
      List<Map<String, dynamic>> contents = [];

      // Add system context as first user message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': contextPrompt},
        ],
      });

      // Add a model response acknowledging the context
      contents.add({
        'role': 'model',
        'parts': [
          {
            'text':
                'I understand. I\'m ready to assist users with questions about the Community Hub app and this live stream event.',
          },
        ],
      });

      // Add recent chat history (last 5 messages for context)
      if (chatHistory != null && chatHistory.isNotEmpty) {
        final recentHistory = chatHistory.length > 5
            ? chatHistory.sublist(chatHistory.length - 5)
            : chatHistory;

        for (var message in recentHistory) {
          contents.add({
            'role': message['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': message['message'] ?? ''},
            ],
          });
        }
      }

      // Add current user message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });

      debugPrint(
        '📦 Request payload prepared (${contents.length} content items)',
      );
      debugPrint('🌍 Making API request to Gemini...');

      // Make API request
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 150, // Increased for complete short responses
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      debugPrint('📡 API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Response decoded successfully');
        debugPrint('📋 Full response: ${response.body}');

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          debugPrint('🔍 Candidate: ${candidate.toString()}');

          // Check if content exists and has parts
          if (candidate['content'] != null) {
            final content = candidate['content'];
            debugPrint('🔍 Content: ${content.toString()}');

            if (content['parts'] != null && content['parts'].isNotEmpty) {
              final text = content['parts'][0]['text'];
              debugPrint('💬 Generated response: "$text"');
              debugPrint('========================================\n');
              return text;
            } else {
              debugPrint('⚠️ Parts field is missing or empty');
            }
          } else {
            debugPrint('⚠️ Content field is missing');
          }
        }

        debugPrint('⚠️ Unexpected response format');
        debugPrint('Response data: ${data.toString().substring(0, 200)}...');
        debugPrint('========================================\n');
        return 'Sorry, I received an unexpected response. Please try again.';
      } else {
        debugPrint('❌ API error: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        debugPrint('========================================\n');
        return 'Sorry, I\'m having trouble connecting right now. Please try again later.';
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION in generateResponse');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('========================================\n');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  /// Process a livestream chat message and determine if chatbot should respond
  /// Returns null if chatbot shouldn't respond, or a response string if it should
  static Future<String?> processLiveStreamMessage({
    required String message,
    required String senderName,
    required bool isBotMention,
    String? eventContext,
    List<Map<String, String>>? chatHistory,
  }) async {
    debugPrint('\n========================================');
    debugPrint('🔍 SHOULD BOT RESPOND CHECK');
    debugPrint('Message: "$message"');
    debugPrint('Sender: $senderName');
    debugPrint('Bot mentioned: $isBotMention');

    // Only respond if:
    // 1. Bot is explicitly mentioned (e.g., "@bot" or "hey bot")
    // 2. Message is a direct question
    // 3. Message contains app-related keywords

    final lowerMessage = message.toLowerCase();
    final botKeywords = ['@bot', 'hey bot', 'hi bot', 'hello bot', 'chatbot'];
    final questionWords = [
      'how',
      'what',
      'where',
      'when',
      'why',
      'can i',
      'help',
    ];
    final appKeywords = [
      'marketplace',
      'event',
      'group',
      'chat',
      'buy',
      'sell',
      'bid',
      'stream',
    ];

    // Check conditions
    bool hasBotKeyword = botKeywords.any(
      (keyword) => lowerMessage.contains(keyword),
    );
    bool hasQuestionWord = questionWords.any(
      (word) => lowerMessage.startsWith(word),
    );
    bool hasAppKeyword = appKeywords.any(
      (keyword) => lowerMessage.contains(keyword),
    );

    debugPrint('Conditions:');
    debugPrint('  - Is bot mention: $isBotMention');
    debugPrint('  - Has bot keyword: $hasBotKeyword');
    debugPrint('  - Has question word: $hasQuestionWord');
    debugPrint('  - Has app keyword: $hasAppKeyword');

    // Check if bot should respond
    bool shouldRespond =
        isBotMention || hasBotKeyword || (hasQuestionWord && hasAppKeyword);

    debugPrint('🎯 DECISION: ${shouldRespond ? "✅ RESPOND" : "❌ SKIP"}');

    if (!shouldRespond) {
      debugPrint('Reason: No bot mention, keyword, or relevant question');
      debugPrint('========================================\n');
      return null;
    }

    // Remove bot mentions from message
    String cleanedMessage = message;
    for (var keyword in botKeywords) {
      cleanedMessage = cleanedMessage
          .replaceAll(RegExp(keyword, caseSensitive: false), '')
          .trim();
    }

    debugPrint('📝 Cleaned message: "$cleanedMessage"');

    // Generate response
    final response = await generateResponse(
      userMessage: cleanedMessage,
      eventContext: eventContext,
      chatHistory: chatHistory,
    );

    debugPrint(
      'Final response: ${response != null ? "✅ Generated" : "❌ null"}',
    );
    debugPrint('========================================\n');
    return response;
  }

  /// Generate event context string for the chatbot
  static String generateEventContext({
    required String eventName,
    required String eventDescription,
    required String eventLocation,
    required DateTime eventDateTime,
    int? viewerCount,
  }) {
    return '''
Event Name: $eventName
Description: $eventDescription
Location: $eventLocation
Date/Time: ${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year} ${eventDateTime.hour}:${eventDateTime.minute.toString().padLeft(2, '0')}
${viewerCount != null ? 'Current Viewers: $viewerCount' : ''}
''';
  }

  /// Get quick reply suggestions based on common questions
  static List<String> getQuickReplies() {
    return [
      'How do I buy items?',
      'How do I join a group?',
      'What features are available?',
      'How do I create an event?',
      'How does bidding work?',
    ];
  }

  /// Check if Gemini API is configured
  static bool isConfigured() {
    return AppConfig.geminiApiKey.isNotEmpty;
  }
}
