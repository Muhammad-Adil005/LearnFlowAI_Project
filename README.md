# LearnFlow AI — Smart AI Study Assistant

> An AI-powered mobile study assistant built with Flutter and Firebase, designed to help students learn smarter — not harder.

LearnFlow AI combines Google Gemini 2.5 Flash with real-time Firebase to give students a personal AI tutor in their pocket. Ask questions, summarize textbooks, generate quizzes, plan your schedule, and track how much you actually study — all in one app.

**[▶ Watch Demo Video](https://github.com/Seerat-Un-Nisa/LearnFlow-AI/releases/download/v1.0/learnflow-AI_Demo.mp4)**

---

## Table of Contents

- [About the Project](#about-the-project)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Getting Started](#getting-started)
- [API Key Setup](#api-key-setup)
- [Project Structure](#project-structure)
- [Project Status](#project-status)
- [Acknowledgements](#acknowledgements)

---

## About the Project

I built LearnFlow AI to solve a problem every student faces — scattered tools, no time tracking, and generic AI responses that don't feel like studying. This app brings everything into one place: a Gemini-powered chat assistant, PDF summarizer, quiz generator, and a study planner, all connected to Firebase so your progress syncs in real time.

The dashboard shows how many minutes you actually studied, how many quizzes you completed, how many PDFs you summarized, and a feed of your recent activity — grouped by day. It works on Android, iOS, and Web from a single codebase.

---


## Tech Stack

| Technology | Version | Purpose |
|---|---|---|
| Flutter | 3.x | Cross-platform UI framework |
| Dart | 3.x | Programming language |
| Firebase Authentication | 5.x | User sign-up, login, email verification |
| Cloud Firestore | 5.x | Real-time database for progress & tasks |
| Google Gemini AI | 2.5 Flash | AI engine for chat, quiz, and PDF summary |
| Syncfusion Flutter PDF | 25.1.x | PDF text extraction |
| Flutter File Picker | 8.x | File selection on Android, iOS, and Web |
| Shared Preferences | 2.x | Local chat history storage |
| HTTP | 1.x | Gemini API calls |

---

## Features

### Authentication
- Email and password sign-up with strong validation (uppercase, number, special character)
- Email verification required before first login
- Forgot password via Firebase reset email
- Session persistence — the app remembers you between launches
- Splash screen checks your auth state and routes you correctly every time

### AI Chat
- Powered by Gemini 2.5 Flash with up to 8192 token responses
- Full conversation history stored locally — never lose a chat
- Suggested prompts on the empty screen to get started fast
- Long press any message to copy it
- Session timer tracks how many minutes you spend chatting

### PDF Summarization
- Upload any PDF — textbooks, notes, assignments, research papers
- AI returns results in three tabs: Summary, Key Points, and Exam Questions
- Reading time is tracked from when the summary loads — not from upload
- Counts toward your study progress on the dashboard

### Quiz Generator
- Generate quizzes on any topic with a single tap
- Choose type: MCQ, True/False, or Short Answer
- Choose difficulty: Easy, Medium, or Hard
- Pick 3 to 15 questions
- Each question shows the correct answer and an explanation after you answer
- Timer runs from the moment the quiz starts — actual minutes are saved to Firestore
- Results screen shows your score, percentage, grade, and a retry button

### Study Planner
- Add tasks with a subject, description, date, and priority (High / Medium / Low)
- Tap a checkbox to mark tasks complete
- Progress bar shows your overall completion percentage
- All tasks sync to Firestore and persist across devices

### Home Dashboard
- Welcome card with your name pulled from Firebase
- Live search — searches your activity history in real time
- Study Progress grid with four cards: Study Time, AI Chats, Quizzes Done, PDFs Done
- Recent Activity shows the latest 5 items grouped by Today / Yesterday / This Week / Earlier
- See All button opens the full activity history

### Profile & Settings
- Edit your display name
- Send a password reset email with one tap
- Toggle notifications for study reminders, quiz reminders, and app alerts
- Pick your AI response style: Concise, Balanced, or Detailed
- Preferences are saved locally with Shared Preferences
- Logout clears the session and returns you to the welcome screen

---

## Getting Started

### What you need before you start

- [Flutter SDK 3.0+](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code
- A Google account (for Firebase and Gemini API)

### Step 1 — Clone the repo

```bash
git clone https://github.com/Seerat-Un-Nisa/LearnFlow-AI.git
cd LearnFlow-AI
```

### Step 2 — Set up Firebase

1. Create a new project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android and/or iOS app
3. Download `google-services.json` and place it in `android/app/`
4. Enable **Email/Password** under Authentication → Sign-in method
5. Create a **Firestore Database** (start in production mode)
6. Run FlutterFire to generate your `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Step 3 — Add your Gemini API key

See the [API Key Setup](#api-key-setup) section below.

### Step 4 — Install dependencies

```bash
flutter pub get
```

### Step 5 — Run

```bash
# Android or iOS
flutter run

# Web
flutter run -d chrome

# Release APK
flutter build apk --release
```

---

## API Key Setup

LearnFlow AI uses the Gemini API for all three AI features. You need to add your key in three files manually.

Get your free API key from [Google AI Studio](https://aistudio.google.com/app/apikey), then paste it here:

**`lib/chat_screen.dart`**
```dart
const String _apiKey = 'PASTE_YOUR_KEY_HERE';
```

**`lib/pdf_summary_screen.dart`**
```dart
const String _pdfApiKey = 'PASTE_YOUR_KEY_HERE';
```

**`lib/quiz_screen.dart`**
```dart
const String _apiKey = 'PASTE_YOUR_KEY_HERE';
```

> **Important:** Do not commit your API key to a public repository. Add `*apiKey*` patterns to your `.gitignore` or use `--dart-define` to pass keys at build time.

---

## Project Structure

```
learnflow_ai/
├── lib/
│   ├── main.dart                 # Entry point + Splash Screen (auth routing)
│   ├── welcome_screen.dart       # Onboarding screen
│   ├── login_screen.dart         # Login and Sign Up (single toggled screen)
│   ├── home_screen.dart          # Dashboard + Search + All Activities
│   ├── chat_screen.dart          # AI Chat with Gemini
│   ├── pdf_summary_screen.dart   # PDF Upload and AI Summary
│   ├── quiz_screen.dart          # Quiz Generator, Quiz, and Results
│   ├── planner_screen.dart       # Study Task Planner
│   ├── settings_screen.dart      # Profile and Settings
│   ├── auth_service.dart         # Firebase Auth wrapper
│   └── activity_service.dart     # Firestore progress and activity tracker
├── screenshots/
├── pubspec.yaml
└── README.md
```

### Firestore data shape

```
users/
  {uid}/
    chatCount        → number of AI messages sent
    quizCount        → number of quizzes completed
    pdfCount         → number of PDFs summarized
    studyMinutes     → total real study time in minutes
    activities/      → subcollection, one doc per activity
    tasks/           → subcollection, one doc per planner task
```

---

## Project Status

**Version 1.0 — complete and functional.**

The following features are planned for future versions:

- AI Flashcard Generator
- Voice Study Assistant
- OCR from camera (scan handwritten notes)
- Group Study Rooms
- AI Timetable Generator
- Offline Mode with local sync

---

## Acknowledgements

- [Google Gemini AI](https://ai.google.dev/) — the AI engine behind every feature
- [Firebase](https://firebase.google.com/) — auth, database, and real-time sync
- [Flutter](https://flutter.dev/) — cross-platform framework that made one codebase run everywhere
- [Syncfusion Flutter PDF](https://www.syncfusion.com/flutter-widgets/flutter-pdf) — PDF text extraction
- [Material Design 3](https://m3.material.io/) — design system and components

---

*Built by [Seerat Un Nisa](https://github.com/Seerat-Un-Nisa)*
