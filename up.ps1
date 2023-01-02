docker compose up -d
docker exec demo-web1-1 powershell -file C:/tools/startup.ps1 -Source 'c:/data' -Destination 'c:/data-backup'