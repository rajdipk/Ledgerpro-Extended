@echo off
cd /d %~dp0
npx pm2 delete all
npx pm2 start ecosystem.config.js
