@echo off
echo [Open Design Launcher] Switching terminal environment to Node 24...
call nvm use 24.18.0

echo [Open Design Launcher] Configuring Vela companion binary path...
set VELA_BIN=C:\Users\vince\open-design\node_modules\.pnpm\@powerformer+vela-cli-win32-x64@0.0.26\node_modules\@powerformer\vela-cli-win32-x64\bin\vela.exe

echo [Open Design Launcher] Starting dev server (daemon + web client)...
cd /d C:\Users\vince\open-design
pnpm tools-dev run web
