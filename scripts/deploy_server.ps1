Write-Host @"
Fly.io deploy is no longer used (requires a payment card).

Deploy the matchmaking server on Render instead:
  1. Push this repo to GitHub
  2. https://dashboard.render.com → New → Web Service
  3. Runtime: Docker, Dockerfile Path: server/Dockerfile, Context: ./server
  4. Plan: Free, Health Check: /health
  5. Open https://YOUR-SERVICE.onrender.com/health

Full steps: docs/HOSTING.md
"@
