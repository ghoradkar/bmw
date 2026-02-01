# mpcb_bio_waste

# MPCB Bio Medical Waste Mobile Application

## Project Overview
This is a Flutter-based mobile application developed for MPCB to complete the process of disposing Bio medical waste collected from HCF.
This application integrates securely with backend APIs.

This README serves as the
**primary documentation for code handover and audit purposes**.

---

## Technology Stack
- Framework: Flutter
- Language: Dart
- Supported Platforms: Android (Primary), iOS (Optional)
- API Communication: REST APIs

---

## Key Features
- Secure user authentication and authorization
- Dashboard and data visualization
- Form-based data entry with validations
- API integration with backend systems
- Role-based access control
- Error handling and logging
- Add waste,Assign vehicle,Reception and Disposal
- Selection of HCF using google map
- Barcode and QR printing with scanning
- App Localization is done for Marathi and English Language

---

## Folder Structure Overview

MPCB/
├── lib/                    # Main source code
│   ├── authentication/     # Authentication files
│   ├── CBWTF/              # CBWTF files
│   ├── CBWTF_Disposal/     # Disposal files
│   ├── CBWTF_Reception/    # Reception files
│   ├── Global/             # Custom widgets
│   ├── HCF/                # HCF files
│   ├── Localization/       # App Localization
│   ├── network/            # Online & Offline code
│   ├── vehicle_user/       # Vehicle user files
│   └── main.dart           # Application entry point
├── assets/                 # Static or public assets
├── android/                # Android config files
├── ios/                    # IOS config files
├── docs/                   # Documentation
└── README.md               # Project overview

---

## System Requirements

### Development Environment
- Operating System: Windows / macOS
- Flutter SDK: 3.x or above
- Dart SDK: Compatible with Flutter SDK
- IDE: Android Studio / VS Code
- RAM: Minimum 8 GB recommended

### Target Devices
- Android version: 9.0 and above
- iOS version: 13 and above

---

## Installation Guide

### Step 1: Clone the Repository
git clone <repository-url>
cd mpcb

### Step 2: Install Dependencies
flutter pub get

### Step 3: Run the Application
flutter run

---

## Build Commands

### Android APK
flutter build apk

### Android App Bundle
flutter build appbundle

### IOS IPA
flutter build ipa

### IOS Build
flutter build ios


---

## Configuration Notes
- Environment-specific configurations are maintained separately
- Sensitive credentials and keys are not committed to the repository
- Platform-specific configurations are available under `android/` and `ios/`

---

## Documentation
Additional technical and functional documents (if any) are available
inside the `docs/` folder.

---

## Support & Maintenance
For technical clarification or maintenance activities, refer to
the project handover documentation or contact the assigned development team.

---

## License
This project is intended for internal use by MPCB and associated stakeholders.

## Version Information

- Version: 1.0.0
- Release Date: 13-06-2025
- Released By:
- Support : Innowave IT Infrastructures






