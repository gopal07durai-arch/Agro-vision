# Deploying AgroVision AI Backend to Cloud (HTTPS)

This guide explains how to deploy your FastAPI backend to a public HTTPS cloud platform (Render, Railway, or Google Cloud Run).

---

## Option A: Deploy to Render.com (Recommended & Free/Easy)

1. Create a free account at [render.com](https://render.com).
2. Push your `backend/` folder to a GitHub repository.
3. In Render Dashboard, click **New +** $\rightarrow$ **Web Service**.
4. Select your GitHub repository.
5. Configure the service:
   - **Name**: `agrovision-ai-backend`
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Health Check Path**: `/health`
6. Click **Create Web Service**.
7. Once deployed, Render will provide your public HTTPS URL, for example:
   ```
   https://agrovision-ai-backend.onrender.com
   ```

---

## Option B: Deploy with Docker (Railway / Fly.io / GCP Cloud Run)

Run:
```bash
docker build -t agrovision-ai-backend .
docker run -p 8000:8000 agrovision-ai-backend
```

---

## Connecting Flutter App to Your Cloud Backend

Once your backend is deployed:

1. Open `agrovision_app/.env` (or configure via compile-time argument `--dart-define=PROD_API_BASE_URL=https://your-backend.onrender.com`):
   ```env
   PROD_API_BASE_URL=https://your-backend.onrender.com
   ```
2. Build the release APK:
   ```bash
   flutter build apk --release
   ```
3. The resulting APK will communicate directly with your public HTTPS backend over mobile data / Wi-Fi anywhere in the world!
