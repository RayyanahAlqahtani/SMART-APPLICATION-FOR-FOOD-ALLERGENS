# Smart Application for Food Allergens Detection 🔍🌾

An AI-powered mobile application designed to assist individuals with food allergies by automatically reading and analyzing product ingredient lists in real-time. The application utilizes Optical Character Recognition (OCR) and Natural Language Processing (NLP) to scan ingredient labels via the device camera or gallery uploads, instantly comparing them against a personalized allergen profile to provide visual safety feedback.

---

## ✨ Core Features
* Personalized Allergen Profiles: Users can easily select and manage their specific food allergens (e.g., wheat, peanuts, soy, milk, eggs).
* Real-Time OCR & AI Analysis: Instantly extracts and interprets printed text from product labels under varying lighting conditions.
* Instant Visual Feedback: Color-coded results for quick decision-making:
  * 🟢 Green Screen: "Safe Product" (No allergen matches found).
  * 🔴 Red Screen: "Allergen Alert" (Warning with highlighted detected allergens).
* Scan History Management: Allows users to track their previous scans or clear the history log anytime.
* Admin Control Panel: Dedicated dashboard to update the allergen dictionary, improve OCR mapping, and monitor system performance.

---

## 🛠️ System Architecture & Technologies
The system is built using a modern modular framework that bridges a cross-platform mobile frontend with a dedicated machine learning backend:

* Frontend Mobile App: Built using Flutter / Android Studio (Java).
* AI & NLP Backend: Powered by Python, Google ML Kit / Tesseract OCR, and NLP models developed in an Anaconda environment.
* Cloud & Database: Firebase (handling User Authentication, Realtime Database synchronization, and Cloud Storage).
* Communication: Connected via high-efficiency RESTful APIs.

---

## 🚀 How to Run the Project
1. Clone the Repository: Download the project files to your local environment.
2. Backend Setup: Open the Python backend module using Anaconda, install the required packages listed in requirements.txt, and start the RESTful API server.
3. Frontend Setup: Open the Flutter application folder in Android Studio.
4. Deploy: Connect an Android (8.0+) or iOS (12+) device/emulator and run the application to interface directly with the active backend server.
