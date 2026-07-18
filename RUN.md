# LPU Campus Navigation System - Run Guide

This guide describes how to run the backend API service and the frontend web application.

---

## 1. Prerequisites
- **Java JDK 21** (Required for the Spring Boot backend)
- **Flutter SDK** (Required for the frontend application)

---

## 2. Running the Backend (Spring Boot)

The backend is located in the [backend](file:///c:/Users/rrwad/OneDrive/Desktop/dsalpuproject/backend) directory.

### Quick Run (PowerShell - using IntelliJ's JDK 21)
If JDK 21 is not your system-default Java version, you can run it pointing explicitly to your IntelliJ JBR directory:
```powershell
# 1. Navigate to the backend directory
cd c:\Users\rrwad\OneDrive\Desktop\dsalpuproject\backend

# 2. Start the Spring Boot Application
$env:JAVA_HOME="C:\Program Files\JetBrains\IntelliJ IDEA 2025.3.2\jbr"
.\gradlew.bat bootRun
```

### Standard Run (If Java 21 is in your System PATH)
```bash
# Windows
.\gradlew.bat bootRun

# Linux / macOS
./gradlew bootRun
```

The backend server starts on: **`http://localhost:8080`**

### Verification
You can verify the backend is running by opening the nodes endpoint in your browser:
- [http://localhost:8080/api/navigation/nodes](http://localhost:8080/api/navigation/nodes)

---

## 3. Running the Frontend (Flutter Web)

The frontend is located in the [frontend](file:///c:/Users/rrwad/OneDrive/Desktop/dsalpuproject/frontend) directory.

### Step-by-Step Instructions
```powershell
# 1. Navigate to the frontend directory
cd c:\Users\rrwad\OneDrive\Desktop\dsalpuproject\frontend

# 2. Get dependencies
flutter pub get

# 3. Run the application
# To run as a web-server (view in any browser):
flutter run -d web-server --web-port 8000

# OR to run directly in Google Chrome:
flutter run -d chrome --web-port 8000
```

The application will be served at: **`http://localhost:8000`**
