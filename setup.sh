#!/bin/bash
# =============================================================
# openclaw-api-dev / setup.sh
# OpenClaw 설치 + API 키 감지 + 모델 설정 스크립트
#
# 모델 우선순위 (환경변수 감지 순서):
#   1. ANTHROPIC_API_KEY  → claude-sonnet-4-5  (OpenClaw 공식 추천)
#   2. OPENAI_API_KEY     → gpt-4o             (검증된 안정성)
#   3. GEMINI_API_KEY     → gemini-2.5-flash   (저비용 선택지)
#
# 필수 환경변수 (셋 중 하나):
#   ANTHROPIC_API_KEY     — Anthropic API 키
#   OPENAI_API_KEY        — OpenAI API 키
#   GEMINI_API_KEY        — Google Gemini API 키
#
# 필수 환경변수 (공통):
#   TELEGRAM_BOT_TOKEN    — Telegram 봇 토큰 (BotFather에서 발급)
#   GOOGLE_CLIENT_ID      — Google Cloud Console OAuth 클라이언트 ID
#   GOOGLE_CLIENT_SECRET  — Google Cloud Console OAuth 클라이언트 시크릿
#   GOOGLE_REFRESH_TOKEN  — Google OAuth Refresh Token
#   GITHUB_USER_EMAIL     — GitHub 계정 이메일
#   GITHUB_USER_NAME      — GitHub 계정 이름 (실명, git log에 표시)
#   GITHUB_LOGIN          — GitHub 로그인 아이디 (공백 없음, 예: johndoe)
#   GITHUB_TOKEN          — GitHub Personal Access Token
# =============================================================

set -eo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}▶ $1${NC}"; }

echo ""
echo "=================================================="
echo "  OpenClaw API 버전 설치 스크립트"
echo "  (오케스트레이션 멀티 에이전트 구조)"
echo "=================================================="
echo ""

# ── 1. Node.js 확인 ───────────────────────────────────────
section "Node.js 확인"

if ! command -v node &>/dev/null; then
  error "Node.js 18 이상이 필요합니다. https://nodejs.org 에서 설치해 주세요."
fi

NODE_MAJOR=$(node -e "process.stdout.write(process.version.slice(1).split('.')[0])")
if [ "$NODE_MAJOR" -lt 18 ]; then
  error "Node.js 18 이상이 필요합니다. 현재 버전: $(node --version)"
fi
info "Node.js $(node --version) 확인됨"

# ── 2. OpenClaw 설치 ──────────────────────────────────────
section "OpenClaw 설치"

if ! command -v openclaw &>/dev/null; then
  npm install -g openclaw
  info "OpenClaw 설치 완료"
else
  info "OpenClaw 이미 설치됨: $(openclaw --version)"
fi

# ── 3. OpenClaw 워크스페이스 초기화 ───────────────────────
section "OpenClaw 워크스페이스 초기화"

openclaw setup --workspace .
info "워크스페이스 초기화 완료"

# ── 4. API 키 감지 및 모델 선택 ───────────────────────────
section "API 키 감지"

PROVIDER=""
MODEL_ID=""
API_KEY=""

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  PROVIDER="anthropic"
  MODEL_ID="claude-sonnet-4-5"
  API_KEY="$ANTHROPIC_API_KEY"
  info "Anthropic API 키 감지됨 → 모델: $MODEL_ID"
elif [ -n "${OPENAI_API_KEY:-}" ]; then
  PROVIDER="openai"
  MODEL_ID="gpt-4o"
  API_KEY="$OPENAI_API_KEY"
  info "OpenAI API 키 감지됨 → 모델: $MODEL_ID"
elif [ -n "${GEMINI_API_KEY:-}" ]; then
  PROVIDER="google"
  MODEL_ID="gemini-2.5-flash"
  API_KEY="$GEMINI_API_KEY"
  info "Gemini API 키 감지됨 → 모델: $MODEL_ID"
else
  echo ""
  echo -e "${RED}[ERROR]${NC} API 키가 설정되지 않았습니다."
  echo ""
  echo "  셋 중 하나를 설정해 주세요:"
  echo "    export ANTHROPIC_API_KEY='...'   (권장: claude-sonnet-4-5)"
  echo "    export OPENAI_API_KEY='...'      (gpt-4o)"
  echo "    export GEMINI_API_KEY='...'      (gemini-2.5-flash)"
  echo ""
  exit 1
fi

# ── 5. 공통 환경변수 확인 ─────────────────────────────────
section "환경변수 확인"

: "${TELEGRAM_BOT_TOKEN:?'TELEGRAM_BOT_TOKEN 이 설정되지 않았습니다 (@BotFather에서 발급)'}"
: "${GOOGLE_CLIENT_ID:?'GOOGLE_CLIENT_ID 가 설정되지 않았습니다'}"
: "${GOOGLE_CLIENT_SECRET:?'GOOGLE_CLIENT_SECRET 이 설정되지 않았습니다'}"
: "${GOOGLE_REFRESH_TOKEN:?'GOOGLE_REFRESH_TOKEN 이 설정되지 않았습니다'}"
: "${GITHUB_USER_EMAIL:?'GITHUB_USER_EMAIL 이 설정되지 않았습니다'}"
: "${GITHUB_USER_NAME:?'GITHUB_USER_NAME 이 설정되지 않았습니다'}"
: "${GITHUB_LOGIN:?'GITHUB_LOGIN 이 설정되지 않았습니다 (GitHub 로그인 아이디, 공백 없음, 예: johndoe)'}"
: "${GITHUB_TOKEN:?'GITHUB_TOKEN 이 설정되지 않았습니다'}"

info "환경변수 확인 완료"

# ── 6. Git 설정 ───────────────────────────────────────────
section "Git 전역 설정"

git config --global user.email "$GITHUB_USER_EMAIL"
git config --global user.name  "$GITHUB_USER_NAME"
git config --global credential.helper store
echo "https://${GITHUB_LOGIN}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
info "Git 설정 완료"

# ── 7. OpenClaw 모델 설정 ─────────────────────────────────
section "OpenClaw 모델 설정"

OPENCLAW_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_DIR"

# .env 생성
{
  printf 'GOOGLE_CLIENT_ID=%s\n'       "${GOOGLE_CLIENT_ID}"
  printf 'GOOGLE_CLIENT_SECRET=%s\n'   "${GOOGLE_CLIENT_SECRET}"
  printf 'GOOGLE_REFRESH_TOKEN=%s\n'   "${GOOGLE_REFRESH_TOKEN}"
  printf 'TELEGRAM_BOT_TOKEN=%s\n'     "${TELEGRAM_BOT_TOKEN}"
  printf 'PROVIDER=%s\n'               "${PROVIDER}"
  printf 'MODEL_ID=%s\n'               "${MODEL_ID}"
  printf 'API_KEY=%s\n'                "${API_KEY}"
} > "$OPENCLAW_DIR/.env"
chmod 600 "$OPENCLAW_DIR/.env"
info ".env 생성 완료"

# openclaw.json 생성
cat > "$OPENCLAW_DIR/openclaw.json" << EOF
{
  "models": {
    "mode": "merge",
    "providers": {
      "${PROVIDER}": {
        "apiKey": "${API_KEY}"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${PROVIDER}/${MODEL_ID}"
      }
    }
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  },
  "env": {
    "GOOGLE_CLIENT_ID": "${GOOGLE_CLIENT_ID}",
    "GOOGLE_CLIENT_SECRET": "${GOOGLE_CLIENT_SECRET}",
    "GOOGLE_REFRESH_TOKEN": "${GOOGLE_REFRESH_TOKEN}"
  },
  "gateway": {
    "mode": "local"
  }
}
EOF
info "openclaw.json 생성 완료 (모델: ${PROVIDER}/${MODEL_ID})"

# ── 완료 ──────────────────────────────────────────────────
echo ""
echo "=================================================="
echo "  기본 설치 완료!"
echo ""
echo "  ✅ 선택된 모델: ${PROVIDER}/${MODEL_ID}"
echo ""
echo "  다음 단계: ./setup-agent.sh 실행"
echo "=================================================="
echo ""
