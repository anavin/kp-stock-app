@echo off
REM ========================================================
REM One-click GitHub Setup สำหรับ Lab Parfumo Stock System
REM Usage: ดับเบิลคลิกไฟล์นี้ หรือรัน setup-github.bat
REM ========================================================
setlocal enabledelayedexpansion
chcp 65001 > nul

echo.
echo 🚀 ตั้งค่า GitHub repository
echo ============================================================
echo.

REM ตรวจสอบ git
where git >nul 2>nul
if errorlevel 1 (
  echo ❌ ไม่พบ git — กรุณาติดตั้งก่อนที่ https://git-scm.com/downloads
  pause
  exit /b 1
)

set /p GH_USER=📝 GitHub Username ของคุณ:
set /p REPO_NAME=📦 ชื่อ repo (default: kp-stock-app):
if "%REPO_NAME%"=="" set REPO_NAME=kp-stock-app

set /p COMMIT_MSG=💬 Commit message (default: Initial commit):
if "%COMMIT_MSG%"=="" set COMMIT_MSG=Initial commit — Lab Parfumo Stock System

echo.
echo 🔍 ตรวจสอบ:
echo    User: %GH_USER%
echo    Repo: %REPO_NAME%
echo    Commit: %COMMIT_MSG%
echo.
set /p CONFIRM=ดำเนินการต่อหรือไม่? (y/N):
if /i not "%CONFIRM%"=="y" (
  echo ❌ ยกเลิก
  pause
  exit /b 1
)

echo.
echo 📂 Init Git repository...

if not exist .git (
  git init
  echo ✓ git initialized
)

git branch -M main 2>nul

git add .
echo ✓ ไฟล์เพิ่มแล้ว

git -c user.email="%GH_USER%@users.noreply.github.com" -c user.name="%GH_USER%" commit -m "%COMMIT_MSG%"

set REMOTE_URL=https://github.com/%GH_USER%/%REPO_NAME%.git
git remote get-url origin >nul 2>nul && (
  git remote set-url origin "%REMOTE_URL%"
) || (
  git remote add origin "%REMOTE_URL%"
)
echo ✓ Remote: %REMOTE_URL%

echo.
echo 📤 ถ้ายังไม่ได้สร้าง repo ให้ไปสร้างที่:
echo    https://github.com/new
echo    ชื่อ: %REPO_NAME%
echo    เลือก Public, ไม่ต้องติ๊ก add README
echo.
pause
git push -u origin main

echo.
echo ✅ เสร็จเรียบร้อย!
echo.
echo 📋 ขั้นตอนต่อไป:
echo.
echo 1️⃣  เปิด GitHub Pages:
echo     https://github.com/%GH_USER%/%REPO_NAME%/settings/pages
echo     Source: Deploy from a branch → main → / (root) → Save
echo.
echo 2️⃣  รอ 1-2 นาที แล้วเปิด:
echo     https://%GH_USER%.github.io/%REPO_NAME%/
echo.
echo 3️⃣  เพิ่ม URL เข้า Supabase Whitelist:
echo     Site URL: https://%GH_USER%.github.io/%REPO_NAME%/
echo     Redirect URLs: https://%GH_USER%.github.io/%REPO_NAME%/*
echo.
echo 📖 คู่มือเต็ม: ดูใน DEPLOY_GUIDE.md
echo.
pause
