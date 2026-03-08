@echo off
echo 🚀 Iniciando API Cogitare...
echo.
cd backend
echo 📦 Instalando dependências...
call npm install
echo.
echo 🔧 Iniciando servidor...
echo 📱 API disponível em: http://localhost:3000
echo 🔗 Health check: http://localhost:3000/api/health
echo.
echo Pressione Ctrl+C para parar o servidor
echo.
call node server.js
pause
