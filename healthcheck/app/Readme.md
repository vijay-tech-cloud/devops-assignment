# Trade API — USING Node.js

API's

- `GET /health` → `200 {"ok": true}`
- `POST /trade/place` → `200 {"status":"accepted","id":"<uuid>"}`

## Folder Structure
```
app/
─ unittest/
─ Dockerfile
─ package.json
─ package-lock.json
─ server.js
```

## Prerequisites
- Node.js **20+**
- npm
- Docker

## Validating the api
```bash
cd healthcheck/app
npm i 
or 
npm install          
npm start       
```
![alt text](image.png)

Command to Verify :
```bash
Invoke-RestMEthod -Uri http://127.0.0.1:8080/health
# {"ok":true}
![alt text](image-1.png)
Invoke-RestMethod -Uri http://localhost:8080/trade/place -Method POST -Headers @{"Content-Type"= "application/json"} -Body "{}"
# {"status":"accepted","id":"<uuid>"}
![alt text](image-2.png)
```


## Docker Commands
Build:
```bash
docker build -t trade-api:latest .
```
Run:
```bash
docker run --rm -p 8080:8080 -e PORT=8080 trade-api:latest
```
## Security &  Best Practises for production env
- Limit body size: `app.use(express.json({ limit: '100kb' }))`.
- Container: run as **non-root**, add a **HEALTHCHECK**, and keep image small (alpine).
- No secrets in code; use AWS Secrets Manager/SSM when infra is created or provisioned.