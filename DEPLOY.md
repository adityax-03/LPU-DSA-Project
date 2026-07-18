# LPU Campus Navigation System - Deployment Guide

This guide details how to build, package, and deploy both the Spring Boot backend API and the Flutter Web frontend to production cloud platforms.

---

## 1. Backend Deployment (Spring Boot API)

The backend compiles into a single, self-contained executable JAR file.

### Step A: Build the Executable JAR
Navigate to the `backend` directory and compile the production build:
```bash
# Windows
.\gradlew.bat bootJar

# Linux / macOS
./gradlew bootJar
```
This packages the compiled code into a JAR file located at:
📁 `backend/build/libs/demo-0.0.1-SNAPSHOT.jar`

### Step B: Host the API on the Cloud

#### Option 1: Render (Easiest Free Hosting)
1. Push your repository to **GitHub**.
2. Sign in to [Render](https://render.com) and click **New > Web Service**.
3. Connect your GitHub repository.
4. Set the following configuration parameters:
   - **Runtime:** `Docker` (or `Java`)
   - **Build Command:** `./gradlew clean bootJar`
   - **Start Command:** `java -jar build/libs/demo-0.0.1-SNAPSHOT.jar`
   - **Port:** `8080`
5. Render will automatically compile, run, and expose your API (e.g. `https://your-app.onrender.com`).

#### Option 2: Dockerize (AWS, GCP, Azure, DigitalOcean)
Create a `Dockerfile` inside the `backend` folder:
```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app
COPY . .
RUN chmod +x gradlew
RUN ./gradlew clean bootJar

# Runtime stage
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```
Build and run the Docker image:
```bash
docker build -t lpu-nav-backend .
docker run -p 8080:8080 lpu-nav-backend
```

---

## 2. Frontend Deployment (Flutter Web)

Since Flutter Web builds into static assets (HTML, CSS, JavaScript, and images), hosting is fast and free.

### Step A: Production Web Build
Change the backend URL to your production cloud endpoint in [app_state.dart](file:///c:/Users/rrwad/OneDrive/Desktop/dsalpuproject/frontend/lib/providers/app_state.dart):
```dart
// Replace 'http://localhost:8080/api' with your deployed backend URL:
final String backendUrl = 'https://your-deployed-backend.onrender.com/api';
```
Then, compile the static web build inside the `frontend` directory:
```bash
flutter build web --release
```
This generates all static web client assets inside:
📁 `frontend/build/web/`

### Step B: Host Static Files

#### Option 1: Netlify / Vercel (Free Hosting)
1. Install the Netlify/Vercel CLI or sign in to their web panels.
2. Select your repository.
3. Configure the settings:
   - **Build Command:** `flutter build web --release`
   - **Publish Directory:** `frontend/build/web`
4. Deploy! Your app will be live on a public URL.

#### Option 2: GitHub Pages (Free Hosting)
You can deploy the static files directly into your GitHub repository pages:
```bash
# Install the peanut package to build directly to a separate gh-pages branch
flutter pub global activate peanut
flutter pub global run peanut

# Push the gh-pages branch to GitHub
git push origin gh-pages
```
Enable GitHub Pages in your repository settings pointing to the `gh-pages` branch.

---

## 3. Production Environment CORS Configuration
Make sure the `@CrossOrigin` annotation inside [NavigationController.java](file:///c:/Users/rrwad/OneDrive/Desktop/dsalpuproject/backend/src/main/java/com/example/demo/controller/NavigationController.java) is set to allow connections from your deployed web frontend URL:
```java
@CrossOrigin(origins = "https://your-deployed-frontend.netlify.app")
```
