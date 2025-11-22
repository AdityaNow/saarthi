# Healthcare Mobile Application

A Flutter-based mobile application for tracking and monitoring personal health metrics like blood sugar, blood pressure, heart rate, temperature, weight, and more.

---

## 📱 What is This Project?

This is a **mobile health tracking app** that helps users:
- Record daily health measurements (blood sugar, blood pressure, heart rate, etc.)
- View their health data in graphs and charts
- Track their health progress over time
- Store their health information securely in the cloud

Think of it like a digital health diary that you can carry in your pocket!

---

## 🏗️ Architecture Overview

### **Frontend (What You See)**
- **Technology**: Flutter (Dart programming language)
- **Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux
- **Location**: All code in the `lib/` folder

### **Backend (Where Data is Stored)**
- **Technology**: Supabase (a cloud-based database service)
- **What it does**: Stores user accounts, health data, and handles authentication
- **Connection**: The app connects to Supabase using special keys (URL and API key)

---

## 🔄 How the Code Works - Simple Explanation

### **1. App Startup (main.dart)**

When you open the app:
1. The app initializes and connects to Supabase (the cloud database)
2. It checks if you're already logged in
3. If logged in → Shows the main screen
4. If not logged in → Shows the welcome/onboarding screen

**Think of it like**: When you enter a building, the security guard checks if you have an ID card. If yes, you go inside. If no, you go to the registration desk.

---

### **2. User Authentication Flow**

#### **Sign Up (Creating Account)**
**File**: `lib/Auth/SignUp.dart`

**What happens**:
1. User enters name, email, and password
2. Password is encrypted (hashed) for security
3. Account is created in Supabase database
4. User information is saved in two tables:
   - `users` table (basic info)
   - `profiles` table (detailed profile)
5. Login status is saved locally on the phone
6. User is taken to the main screen

**Simple analogy**: Like filling out a form at a new gym. They take your details, create your membership card, and you're ready to use the facilities.

#### **Sign In (Logging In)**
**File**: `lib/Auth/SignIn.dart`

**What happens**:
1. User enters email and password
2. App checks the database to find the user
3. Password is encrypted and compared with stored password
4. If correct → User is logged in
5. Login status is saved locally
6. User is taken to the main screen

**Simple analogy**: Like swiping your membership card at the gym entrance. The system checks if it's valid, and if yes, you can enter.

---

### **3. Main Application Flow**

#### **Navigation Structure**
**File**: `lib/BottomNavBar/NavBarScreen.dart`

The app has a **bottom navigation bar** with:
- **Home** tab: Where you add and view health entries
- **Graph** tab: Where you see charts and visualizations

There's also a **floating microphone button** in the center for voice input.

**Think of it like**: A restaurant menu with different sections. You tap on "Home" to order food, or "Graph" to see the bill summary.

---

### **4. Home Screen (Adding Health Data)**
**File**: `lib/Home/HomeScreen.dart`

**What you can do**:
- Add blood sugar readings
- Add blood pressure readings
- Add heart rate, pulse, temperature, weight, height
- Add CBC (Complete Blood Count) test results
- Add notes about your health

**How it works**:
1. User fills in a form (or uses voice input)
2. Data is sent to Supabase database
3. Data is stored in specific tables:
   - `health_entries` (for blood sugar)
   - `bp_entries` (for blood pressure)
   - `heart_rate_entries` (for heart rate)
   - `pulse_entries` (for pulse)
   - `temprature_entries` (for temperature)
   - `weight` (for weight)
   - `height` (for height)
   - `cbc_entries` (for CBC tests)
4. The screen refreshes to show the new data

**Simple analogy**: Like writing in a diary. You write your health measurements, and the diary saves them. Later, you can read them back.

---

### **5. Graph Screen (Viewing Data)**
**File**: `lib/Graph/GraphScreen.dart`

**What it does**:
- Fetches all health data from Supabase
- Displays data in visual charts and graphs
- Shows trends over time
- Allows exporting data as PDF

**How it works**:
1. App requests data from Supabase database
2. Data is received and organized
3. Charts are drawn using the data
4. User can see their health progress visually

**Simple analogy**: Like looking at a graph of your monthly expenses. You can see if you're spending more or less over time.

---

### **6. Voice Input Feature**
**File**: `lib/BottomNavBar/NavBarScreen.dart` (VoiceInputScreen class)

**What it does**:
- Uses your phone's microphone to listen to your voice
- Recognizes health-related words (like "sugar 120", "blood pressure 120/80")
- Extracts numbers from your speech
- Shows a confirmation screen to verify the data
- Saves the data to the database

**How it works**:
1. User taps the microphone button
2. App starts listening (for 8 seconds)
3. User speaks their health measurement
4. App processes the speech and extracts numbers
5. App shows a confirmation screen
6. User confirms or edits the data
7. Data is saved to database

**Simple analogy**: Like talking to a smart assistant. You say "My blood sugar is 120", and it writes it down for you.

---

## 🔌 How Frontend and Backend Connect

### **Connection Setup**
**File**: `lib/main.dart`

```dart
const supabaseUrl = 'https://kwrskwqmbbhutblilonq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

These are like **addresses and keys**:
- **supabaseUrl**: The address of the cloud database (like a website address)
- **supabaseKey**: A secret key that allows the app to access the database (like a password)

### **Data Flow Example: Adding Blood Sugar**

1. **User Action**: User enters "120" in the blood sugar field and taps "Save"
2. **Frontend (Flutter)**: 
   - Gets the user ID from local storage
   - Prepares the data: `{user_id: "abc123", value: 120, entry_date: "2024-01-15", time_of_day: "morning", meal_time: "pre-meal"}`
3. **Network Request**: App sends this data to Supabase over the internet
4. **Backend (Supabase)**:
   - Receives the data
   - Validates it (checks if user exists, if entry already exists for that day)
   - Saves it to the `health_entries` table in the database
   - Sends back a success message
5. **Frontend Response**: 
   - Receives success message
   - Shows a green notification: "Sugar entry added successfully!"
   - Refreshes the screen to show the new entry

**Simple analogy**: Like sending a letter through the post office:
- You write the letter (enter data in app)
- You put it in an envelope with an address (send to Supabase)
- Post office delivers it (Supabase saves it)
- You get a confirmation receipt (success message)

---

## 📁 Project Structure

```
health_care/
│
├── lib/                          # Main application code
│   ├── main.dart                # App entry point, initializes Supabase
│   │
│   ├── Auth/                    # Authentication screens
│   │   ├── SignIn.dart          # Login screen
│   │   ├── SignUp.dart          # Registration screen
│   │   └── forgot_password.dart # Password reset screen
│   │
│   ├── WelCome/                 # Welcome/Onboarding
│   │   └── WelComeScreen.dart   # First screen users see
│   │
│   ├── BottomNavBar/            # Main navigation
│   │   └── NavBarScreen.dart    # Bottom navigation bar + voice input
│   │
│   ├── Home/                    # Home screen
│   │   └── HomeScreen.dart      # Where users add health data
│   │
│   ├── Graph/                   # Charts and graphs
│   │   └── GraphScreen.dart     # Visual representation of health data
│   │
│   ├── profile/                 # User profile
│   │   └── profile_screen.dart  # User settings and profile
│   │
│   └── utils/                   # Helper functions
│       └── session.dart         # Manages user login session
│
├── assets/                      # Images and other files
│   ├── health_image.jpg
│   └── icon.png
│
├── android/                     # Android-specific code
├── ios/                         # iOS-specific code
├── web/                         # Web-specific code
├── windows/                     # Windows-specific code
├── linux/                       # Linux-specific code
├── macos/                        # macOS-specific code
│
├── pubspec.yaml                 # Project dependencies and configuration
└── README.md                    # This file
```

---

## 🗄️ Database Structure (Supabase Tables)

The app uses these database tables:

1. **users** - Basic user information
   - id, email, full_name, password, created_at

2. **profiles** - Detailed user profiles
   - id, full_name, email, password, agree_to_terms

3. **health_entries** - Blood sugar readings
   - id, user_id, value, entry_date, time_of_day, meal_time, created_at

4. **bp_entries** - Blood pressure readings
   - id, user_id, systolic, diastolic, entry_date, time_of_day, created_at

5. **heart_rate_entries** - Heart rate measurements
   - id, user_id, value, entry_date, time_of_day, created_at

6. **pulse_entries** - Pulse rate measurements
   - id, user_id, value, entry_date, time_of_day, created_at

7. **temprature_entries** - Temperature readings
   - id, user_id, value, entry_date, time_of_day, created_at

8. **weight** - Weight measurements
   - id, user_id, value, entry_date, time_of_day, created_at

9. **height** - Height measurements
   - id, user_id, value, entry_date, time_of_day, created_at

10. **cbc_entries** - Complete Blood Count test results
    - id, user_id, wbc, rbc, entry_date, time_of_day, created_at

11. **notes** - User notes
    - id, user_id, text, date, created_at

**Simple analogy**: Like different filing cabinets:
- One cabinet for user information
- One cabinet for blood sugar records
- One cabinet for blood pressure records
- And so on...

---

## 🔐 Security Features

1. **Password Hashing**: Passwords are encrypted using SHA-256 before storing
2. **User Authentication**: Only logged-in users can access their data
3. **Data Isolation**: Each user can only see their own health data
4. **Session Management**: Login status is saved locally and checked on app startup

**Simple analogy**: Like a bank vault:
- Your password is like a secret code that's scrambled
- Only you can access your account
- Your data is locked away from others

---

## 🎯 Key Features

1. **Multiple Health Metrics**: Track blood sugar, BP, heart rate, temperature, weight, height, CBC
2. **Voice Input**: Speak your measurements instead of typing
3. **Data Visualization**: See your health trends in graphs
4. **PDF Export**: Download your health reports as PDF
5. **Daily Limits**: Prevents duplicate entries for the same day
6. **Time-based Tracking**: Records morning/evening measurements separately
7. **Notes**: Add personal notes about your health

---

## 🔄 Complete User Journey

1. **First Time User**:
   - Opens app → Sees onboarding screens
   - Taps "Sign Up" → Creates account
   - Enters details → Account created in Supabase
   - Redirected to Home screen

2. **Returning User**:
   - Opens app → App checks if logged in
   - If logged in → Goes directly to Home screen
   - If not → Sees Welcome screen → Logs in → Goes to Home screen

3. **Adding Health Data**:
   - User on Home screen → Taps "Add Blood Sugar" (or any metric)
   - Enters value → Taps "Save"
   - Data sent to Supabase → Saved in database
   - Screen refreshes → Shows new entry

4. **Viewing Graphs**:
   - User taps "Graph" tab
   - App fetches all data from Supabase
   - Charts are displayed
   - User can see trends over time

5. **Voice Input**:
   - User taps microphone button
   - Speaks: "My blood sugar is 120"
   - App processes speech → Shows confirmation
   - User confirms → Data saved

---

## 🛠️ Technologies Used

- **Flutter**: Framework for building mobile apps
- **Dart**: Programming language
- **Supabase**: Backend-as-a-Service (database, authentication)
- **SharedPreferences**: Local storage on device
- **Speech to Text**: Voice recognition
- **PDF Generation**: Creating PDF reports
- **Charts/Graphs**: Data visualization

---

## 📝 Summary

This healthcare app is like a **digital health diary** that:
- Stores your health data in the cloud (Supabase)
- Lets you add data by typing or speaking
- Shows your health trends in beautiful graphs
- Keeps your data secure and private
- Works on multiple devices (phone, tablet, computer)

The **frontend** (Flutter app) is what you see and interact with. The **backend** (Supabase) is where all your data is safely stored. They communicate over the internet to keep everything in sync.

---

## 🚀 Getting Started

To run this project:

1. Install Flutter SDK
2. Install dependencies: `flutter pub get`
3. Configure Supabase credentials in `lib/main.dart`
4. Run the app: `flutter run`

---

**Note**: This documentation is written in simple terms for non-technical users. For technical details, refer to the code comments in individual files.
