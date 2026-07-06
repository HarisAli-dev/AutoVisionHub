# AutoVisionHub

A comprehensive Flutter application with Node.js backend for event management, chat, and group messaging with push notifications.
<img width="370" height="1000" alt="762cda69-6448-412b-a11b-b80ace966067" src="https://github.com/user-attachments/assets/d91a0d8a-c8c7-4dda-88ff-b504e826c24f" />
<img width="370" height="1000" alt="ea74ab1b-9b10-4f30-94bc-fff8f8d46830" src="https://github.com/user-attachments/assets/ed2c12eb-06e4-4433-b83c-2a2229aed006" />
<img width="370" height="1000" alt="fc6fd291-00ec-4355-9351-d23338c028d3" src="https://github.com/user-attachments/assets/14ba372a-d041-4ce1-a453-f8d6bb827029" />


## 🔧 Environment Setup

### Backend Environment Variables (.env)

Create a `.env` file in the `back/` directory with the following variables:

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# JWT Secret
JWT_SECRET=your_jwt_secret_key

# Stripe Configuration
STRIPE_SECRET_KEY=your_stripe_secret_key

# Firebase Admin SDK Configuration
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY_ID=your_firebase_private_key_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_CLIENT_ID=your_firebase_client_id
```

### Frontend Environment Variables (.env)

Create a `.env` file in the `front/` directory with the following variables:

```env
# Firebase Configuration for Flutter App
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_API_KEY=your_web_api_key
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# Backend API Configuration
API_BASE_URL=http://localhost:8080/api

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
```

## 🔥 Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable Authentication, Firestore, and Cloud Messaging

### 2. Get Service Account Credentials
1. Go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Extract the values and add them to your backend `.env` file

### 3. Get Web App Configuration
1. Go to Project Settings → General
2. Add a web app if you haven't already
3. Copy the configuration values to your frontend `.env` file

## 📱 Push Notifications Setup

The app includes comprehensive push notification functionality:

- ✅ Firebase Cloud Messaging (FCM) integration
- ✅ Deep linking to specific chats/groups
- ✅ Background and foreground notifications
- ✅ Automatic FCM token management
- ✅ Local notifications for better UX

### Features:
- Real-time chat notifications
- Group message notifications
- Event updates
- Deep linking navigation
- Secure token management

## 🚀 Installation

### Backend
```bash
cd back
npm install
npm start
```

### Frontend
```bash
cd front
flutter pub get
flutter run
```

## 🔒 Security Notes

- Never commit `.env` files to version control
- Keep Firebase service account credentials secure
- Use environment variables in production
- Regularly rotate API keys and secrets
- The app automatically excludes sensitive files via `.gitignore`

## 📁 Project Structure

```
AutoVisionHub/
├── back/                 # Node.js Backend
│   ├── config/          # Configuration files
│   ├── controllers/     # API controllers
│   ├── models/          # Database models
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   └── .env            # Environment variables (create this)
├── front/               # Flutter Frontend
│   ├── lib/            # Dart source code
│   ├── assets/         # App assets
│   └── .env           # Environment variables (create this)
└── README.md
```

## 🛠 Technologies Used

### Backend
- Node.js & Express
- MongoDB with Mongoose
- Socket.IO for real-time communication
- Firebase Admin SDK for push notifications
- Stripe for payments
- Cloudinary for media storage

### Frontend
- Flutter & Dart
- Provider for state management
- Firebase SDK
- Socket.IO client
- Stripe Flutter SDK
- Local notifications

## 📞 Support

For setup assistance or issues, please refer to the documentation or create an issue in the repository.
