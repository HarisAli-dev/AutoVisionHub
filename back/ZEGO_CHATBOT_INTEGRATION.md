# ZEGOCLOUD AI Chatbot Integration Guide

## Overview
This implementation integrates ZEGOCLOUD's AI Agent service with your AutoVisionHub live streaming platform, enabling intelligent chatbot interactions during live streams.

## Architecture

### Components
1. **ZegoChatbotService** (`services/zegoChatbotService.js`)
   - Manages AI agent registration and lifecycle
   - Handles chatbot sessions for live streams
   - Generates ZEGOCLOUD authentication tokens
   - Maintains active chatbot instances

2. **ZegoChatbotController** (`controllers/zegoChatbotController.js`)
   - Exposes REST API endpoints for chatbot management
   - Handles HTTP requests and responses
   - Integrates with live stream service

3. **Routes** (`routes/zegoChatbotRoutes.js`)
   - Defines API endpoints for chatbot operations
   - Applies authentication middleware

4. **Live Stream Integration** (`controllers/events/liveStreamController.js`)
   - Automatically starts chatbot when live stream begins
   - Stops chatbot when live stream ends
   - Handles viewer join/leave notifications

## Configuration

### Environment Variables
Add these to your `.env` file:

```env
# ZEGOCLOUD Configuration
ZEGO_APP_ID=your_zego_app_id_here
ZEGO_SERVER_SECRET=your_zego_server_secret_here
ZEGO_API_BASE_URL=https://rtc-api.zego.im
ZEGO_AI_API_BASE_URL=https://ai-api.zego.im

# AI Model Configuration (use Gemini or DashScope)
DASHSCOPE_API_KEY=your_dashscope_api_key_or_use_gemini
AI_MODEL_URL=https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent
```

### Getting ZEGOCLOUD Credentials
1. Sign up at [ZEGOCLOUD Console](https://console.zegocloud.com)
2. Create a new project
3. Navigate to "Project Management" → "Project Information"
4. Copy your `AppID` and `ServerSecret`

## API Endpoints

### 1. Generate Authentication Token
**Endpoint:** `GET /api/zego/token`

**Authentication:** Required

**Query Parameters:**
- `user_id` (required): User identifier
- `effective_time` (optional): Token validity in seconds (default: 86400 = 24 hours)

**Example Request:**
```bash
curl -X GET "http://localhost:8080/api/zego/token?user_id=user123&effective_time=7200" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "base64_encoded_token",
    "user_id": "user123",
    "app_id": "your_app_id",
    "effective_time": 7200,
    "expires_at": "2025-11-28T12:00:00.000Z"
  }
}
```

### 2. Register AI Agent
**Endpoint:** `POST /api/zego/chatbot/register`

**Authentication:** Required

**Request Body:**
```json
{
  "AgentId": "custom-agent-id",
  "Name": "Custom AI Assistant",
  "LLM": {
    "Url": "https://api.example.com/generate",
    "Prompts": {
      "Personality": "Custom personality description",
      "Temperature": 0.7,
      "MaxTokens": 200
    }
  }
}
```

**Example Request:**
```bash
curl -X POST "http://localhost:8080/api/zego/chatbot/register" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "AutoVision AI",
    "LLM": {
      "Prompts": {
        "Personality": "Friendly automotive expert"
      }
    }
  }'
```

### 3. Start Chatbot Session
**Endpoint:** `POST /api/zego/chatbot/start`

**Authentication:** Required

**Request Body:**
```json
{
  "room_id": "live_event123_1732723200000",
  "host_user_id": "host_user_id",
  "options": {
    "autoStart": true,
    "welcomeMessage": "Welcome! Ask me anything about cars!"
  }
}
```

**Example Request:**
```bash
curl -X POST "http://localhost:8080/api/zego/chatbot/start" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_id": "live_event123_1732723200000",
    "options": {
      "welcomeMessage": "Hello everyone! I am here to help."
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Chatbot started successfully",
  "data": {
    "instanceId": "instance_abc123",
    "agentUserId": "ai-bot-live_event123_1732723200000",
    "agentStreamId": "ai-stream-live_event123_1732723200000",
    "roomId": "live_event123_1732723200000",
    "status": "active"
  }
}
```

### 4. Stop Chatbot Session
**Endpoint:** `POST /api/zego/chatbot/stop`

**Authentication:** Required

**Request Body:**
```json
{
  "room_id": "live_event123_1732723200000"
}
```

**Example Request:**
```bash
curl -X POST "http://localhost:8080/api/zego/chatbot/stop" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_id": "live_event123_1732723200000"
  }'
```

### 5. Send Message to Chatbot
**Endpoint:** `POST /api/zego/chatbot/message`

**Authentication:** Required

**Request Body:**
```json
{
  "room_id": "live_event123_1732723200000",
  "message": "What is the best car for off-roading?"
}
```

**Example Request:**
```bash
curl -X POST "http://localhost:8080/api/zego/chatbot/message" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_id": "live_event123_1732723200000",
    "message": "Tell me about electric vehicles"
  }'
```

### 6. Get Chatbot Status
**Endpoint:** `GET /api/zego/chatbot/status/:roomId`

**Authentication:** Required

**Example Request:**
```bash
curl -X GET "http://localhost:8080/api/zego/chatbot/status/live_event123_1732723200000" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "isActive": true,
    "instanceId": "instance_abc123",
    "agentUserId": "ai-bot-live_event123_1732723200000",
    "roomId": "live_event123_1732723200000",
    "startTime": "2025-11-27T10:00:00.000Z",
    "messagesCount": 45,
    "uptime": 3600
  }
}
```

### 7. Get All Active Chatbots
**Endpoint:** `GET /api/zego/chatbot/active`

**Authentication:** Required

**Example Request:**
```bash
curl -X GET "http://localhost:8080/api/zego/chatbot/active" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Automatic Integration with Live Streams

The chatbot is automatically managed with live streams:

1. **When Starting Live Stream:**
   - Chatbot session is automatically created
   - Welcome message is sent to the room
   - Agent joins as a participant

2. **During Live Stream:**
   - Users can mention "bot", "ai", or "assistant" in chat to trigger responses
   - Chatbot tracks viewer engagement
   - Analytics are collected

3. **When Stopping Live Stream:**
   - Chatbot session is automatically terminated
   - Final analytics are saved
   - Resources are cleaned up

## Frontend Integration

### For Flutter (Low-Level SDK)

Install the ZEGO Express SDK:
```yaml
dependencies:
  zego_express_engine: ^3.14.0
```

### Initialize SDK
```dart
import 'package:zego_express_engine/zego_express_engine.dart';

// Initialize engine
await ZegoExpressEngine.createEngineWithProfile(
  ZegoEngineProfile(
    appID: YOUR_APP_ID,
    appSign: YOUR_APP_SIGN,
    scenario: ZegoScenario.General,
  ),
);

// Get token from backend
final tokenResponse = await http.get(
  Uri.parse('$apiUrl/api/zego/token?user_id=$userId'),
  headers: {'Authorization': 'Bearer $jwtToken'},
);
final zegoToken = jsonDecode(tokenResponse.body)['data']['token'];

// Login to room
await ZegoExpressEngine.instance.loginRoom(
  roomId,
  ZegoUser(userId, userName),
  config: ZegoRoomConfig(0, true, zegoToken),
);
```

### Listen for Messages
```dart
// Set up message listener
ZegoExpressEngine.onIMRecvBarrageMessage = (String roomID, List<ZegoBarrageMessageInfo> messageList) {
  for (var msg in messageList) {
    // Check if message is from AI bot
    if (msg.fromUser.userID.startsWith('ai-bot-')) {
      // Handle bot message
      _handleBotMessage(msg.message);
    } else {
      // Handle user message
      _handleUserMessage(msg.fromUser.userName, msg.message);
    }
  }
};

// Send message (will be picked up by bot if it mentions bot)
await ZegoExpressEngine.instance.sendBarrageMessage(
  roomId,
  'Hey bot, what cars do you recommend?',
);
```

### Example Flutter Implementation
```dart
class LiveStreamScreen extends StatefulWidget {
  final String roomId;
  final String eventId;
  
  @override
  _LiveStreamScreenState createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  List<ChatMessage> _messages = [];
  bool _chatbotActive = false;
  
  @override
  void initState() {
    super.initState();
    _initializeZego();
    _checkChatbotStatus();
  }
  
  Future<void> _initializeZego() async {
    // Get token
    final token = await _getZegoToken();
    
    // Login to room
    await ZegoExpressEngine.instance.loginRoom(
      widget.roomId,
      ZegoUser(currentUserId, currentUserName),
      config: ZegoRoomConfig(0, true, token),
    );
    
    // Set up listeners
    ZegoExpressEngine.onIMRecvBarrageMessage = _onMessageReceived;
  }
  
  Future<void> _checkChatbotStatus() async {
    final response = await http.get(
      Uri.parse('$apiUrl/api/zego/chatbot/status/${widget.roomId}'),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      setState(() {
        _chatbotActive = data['isActive'] ?? false;
      });
    }
  }
  
  void _onMessageReceived(String roomID, List<ZegoBarrageMessageInfo> messageList) {
    setState(() {
      for (var msg in messageList) {
        _messages.add(ChatMessage(
          sender: msg.fromUser.userName,
          message: msg.message,
          isBot: msg.fromUser.userID.startsWith('ai-bot-'),
          timestamp: DateTime.now(),
        ));
      }
    });
  }
  
  Future<void> _sendMessage(String message) async {
    // Send via ZEGO
    await ZegoExpressEngine.instance.sendBarrageMessage(
      widget.roomId,
      message,
    );
    
    // If message mentions bot, also send to backend
    if (message.toLowerCase().contains('bot') || 
        message.toLowerCase().contains('ai')) {
      await http.post(
        Uri.parse('$apiUrl/api/zego/chatbot/message'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'message': message,
        }),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Video view
          Expanded(
            flex: 3,
            child: ZegoVideoView(),
          ),
          // Chat section
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (_chatbotActive)
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.blue.shade100,
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('AI Assistant is active'),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatBubble(
                        message: msg,
                        isBot: msg.isBot,
                      );
                    },
                  ),
                ),
                MessageInput(onSend: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Testing

### 1. Register Agent (First Time Setup)
```bash
curl -X POST "http://localhost:8080/api/zego/chatbot/register" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

### 2. Start Live Stream (Chatbot Auto-Starts)
```bash
curl -X POST "http://localhost:8080/api/livestream/start" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "event_id_here",
    "streamTitle": "Test Stream",
    "streamDescription": "Testing chatbot integration"
  }'
```

### 3. Check Chatbot Status
```bash
curl -X GET "http://localhost:8080/api/zego/chatbot/status/ROOM_ID" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 4. Send Test Message
```bash
curl -X POST "http://localhost:8080/api/zego/chatbot/message" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "room_id": "ROOM_ID",
    "message": "Hey bot, tell me about electric cars"
  }'
```

## Troubleshooting

### Issue: Token Generation Fails
- Verify `ZEGO_APP_ID` and `ZEGO_SERVER_SECRET` are correct
- Check that values are not wrapped in quotes in `.env`
- Ensure AppID is an integer

### Issue: Agent Registration Fails
- Confirm ZEGO AI service is enabled in your console
- Verify API base URLs are correct
- Check AI model API key is valid

### Issue: Chatbot Not Responding
- Verify chatbot session is active: `GET /api/zego/chatbot/status/:roomId`
- Check backend logs for error messages
- Ensure messages contain trigger words: "bot", "ai", or "assistant"

### Issue: Frontend Not Receiving Messages
- Verify ZEGO SDK is properly initialized
- Check message listener is set up before joining room
- Ensure room ID matches between backend and frontend

## Best Practices

1. **Resource Management**
   - Always stop chatbot sessions when streams end
   - Monitor active chatbot count
   - Set reasonable token expiry times

2. **Security**
   - Never expose server secret in frontend
   - Always generate tokens on backend
   - Validate user permissions before operations

3. **Performance**
   - Limit message history to prevent memory issues
   - Use pagination for analytics queries
   - Cache chatbot status when possible

4. **User Experience**
   - Provide clear indicators when chatbot is active
   - Show bot messages differently from user messages
   - Allow users to toggle chatbot visibility

## Additional Resources

- [ZEGOCLOUD Documentation](https://docs.zegocloud.com)
- [ZEGOCLOUD AI Agent Guide](https://docs.zegocloud.com/article/ai-agent)
- [Flutter SDK Documentation](https://docs.zegocloud.com/article/flutter-sdk)
- [API Reference](https://docs.zegocloud.com/article/api)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review ZEGOCLOUD console for service status
3. Check backend logs for detailed error messages
4. Contact ZEGOCLOUD support for SDK-specific issues
