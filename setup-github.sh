#!/usr/bin/env bash
# ========================================================
# One-click GitHub Setup สำหรับ Lab Parfumo Stock System
# Usage: bash setup-github.sh
# ========================================================
set -e

echo ""
echo "🚀 ตั้งค่า GitHub repository สำหรับ Lab Parfumo Stock System"
echo "============================================================"
echo ""

# ตรวจสอบว่ามี git ติดตั้งหรือไม่
if ! command -v git &> /dev/null; then
  echo "❌ ไม่พบ git — กรุณาติดตั้งก่อนที่ https://git-scm.com/downloads"
  exit 1
fi

# ตรวจสอบว่ามี gh CLI หรือไม่ (ทางเลือก)
HAS_GH=$(command -v gh >/dev/null 2>&1 && echo "yes" || echo "no")

# ขอข้อมูลจากผู้ใช้
read -p "📝 GitHub Username ของคุณ: " GH_USER
read -p "📦 ชื่อ repo (default: kp-stock-app): " REPO_NAME
REPO_NAME=${REPO_NAME:-kp-stock-app}

read -p "💬 Commit message (default: Initial commit): " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"Initial commit — Lab Parfumo Stock System"}

echo ""
echo "🔍 ตรวจสอบ:"
echo "   User: $GH_USER"
echo "   Repo: $REPO_NAME"
echo "   Commit: $COMMIT_MSG"
echo ""
read -p "ดำเนินการต่อหรือไม่? (y/N): " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { echo "❌ ยกเลิก"; exit 1; }

echo ""
echo "📂 Init Git repository..."

# Init git ถ้ายังไม่มี
if [ ! -d .git ]; then
  git init
  echo "✓ git initialized"
fi

# Set main branch
git branch -M main 2>/dev/null || true

# Add ไฟล์ทั้งหมด
git add .
echo "✓ ไฟล์เพิ่มแล้ว"

# Commit (ถ้ามีการเปลี่ยนแปลง)
if git diff --cached --quiet; then
  echo "ℹ️  ไม่มีอะไรให้ commit"
else
  git -c user.email="$GH_USER@users.noreply.github.com" -c user.name="$GH_USER" commit -m "$COMMIT_MSG"
  echo "✓ Commit เสร็จ"
fi

# Set remote
REMOTE_URL="https://github.com/$GH_USER/$REPO_NAME.git"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi
echo "✓ Remote: $REMOTE_URL"

echo ""
if [ "$HAS_GH" = "yes" ]; then
  echo "🔧 พบ GitHub CLI — จะสร้าง repo และ push ให้อัตโนมัติ..."
  echo ""
  if gh auth status >/dev/null 2>&1; then
    gh repo create "$REPO_NAME" --public --source=. --remote=origin --push || {
      echo "ℹ️  repo อาจมีอยู่แล้ว — กำลังลอง push..."
      git push -u origin main
    }
  else
    echo "⚠️  GitHub CLI ยังไม่ login — รัน 'gh auth login' ก่อน"
    echo "    หรือกด Enter เพื่อ push ผ่าน https"
    read
    git push -u origin main
  fi
else
  echo "📤 กำลัง push ขึ้น GitHub..."
  echo "ℹ️  ถ้ายังไม่ได้สร้าง repo ให้ไปสร้างที่:"
  echo "    https://github.com/new"
  echo "    ชื่อ: $REPO_NAME"
  echo "    เลือก Public, ไม่ต้องติ๊ก add README"
  echo ""
  read -p "สร้าง repo เสร็จแล้วใช่ไหม? กด Enter ต่อ..."
  git push -u origin main
fi

echo ""
echo "✅ เสร็จเรียบร้อย!"
echo ""
echo "📋 ขั้นตอนต่อไป:"
echo ""
echo "1️⃣  เปิด GitHub Pages:"
echo "    https://github.com/$GH_USER/$REPO_NAME/settings/pages"
echo "    → Source: Deploy from a branch → main → / (root) → Save"
echo ""
echo "2️⃣  รอ 1-2 นาที แล้วเปิด:"
echo "    https://$GH_USER.github.io/$REPO_NAME/"
echo ""
echo "3️⃣  เพิ่ม URL เข้า Supabase Whitelist:"
echo "    Authentication → URL Configuration"
echo "    Site URL: https://$GH_USER.github.io/$REPO_NAME/"
echo "    Redirect URLs: https://$GH_USER.github.io/$REPO_NAME/*"
echo ""
echo "📖 คู่มือเต็ม: ดูใน DEPLOY_GUIDE.md"
echo ""
