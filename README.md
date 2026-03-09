# openclaw-api-dev

**AI 업무 비서팀** — Telegram 봇 하나로 Gmail·Google Calendar·Google Drive를 AI가 처리합니다.

OpenClaw 기반 오케스트레이션 멀티 에이전트 구조.
Claude / GPT-4o / Gemini 외부 API를 사용하므로 **GPU 없이 일반 서버에서 바로 실행**됩니다.

---

## ollama-dev와의 차이점

| | [openclaw-ollama-dev](https://github.com/your-org/openclaw-ollama-dev) | openclaw-api-dev |
|---|---|---|
| 모델 실행 방식 | Ollama 로컬 모델 | 외부 API (Claude / GPT-4o / Gemini) |
| GPU | 필요 (24~32GB VRAM) | 불필요 |
| 모델 비용 | 없음 | API 사용량 기준 과금 |
| 설치 시간 | 모델 다운로드 10~30분 | 즉시 |
| 에이전트 구조 | 동일 | 동일 |

---

## 지원 모델

| 우선순위 | 환경변수 | 모델 | 특징 |
|---|---|---|---|
| 1순위 | `ANTHROPIC_API_KEY` | `claude-sonnet-4-5` | OpenClaw 공식 추천, 프롬프트 인젝션 저항 최강 |
| 2순위 | `OPENAI_API_KEY` | `gpt-4o` | 검증된 안정성, 높은 인지도 |
| 3순위 | `GEMINI_API_KEY` | `gemini-2.5-flash` | 저비용 선택지 |

여러 키가 설정되어 있으면 우선순위 높은 것 하나만 사용됩니다.

> **DeepSeek은 지원하지 않습니다.** 데이터 프라이버시 이슈로 인해 업무용 에이전트에 적합하지 않습니다.

---

## 빠른 시작

### 1. 환경변수 설정

```bash
# API 키 (셋 중 하나 — 우선순위 순)
export ANTHROPIC_API_KEY="sk-ant-..."       # 권장
# export OPENAI_API_KEY="sk-..."
# export GEMINI_API_KEY="AI..."

# Telegram
export TELEGRAM_BOT_TOKEN="your-bot-token"

# Google OAuth
export GOOGLE_CLIENT_ID="your-client-id"
export GOOGLE_CLIENT_SECRET="your-client-secret"
export GOOGLE_REFRESH_TOKEN="your-refresh-token"

# GitHub
export GITHUB_USER_EMAIL="your@email.com"
export GITHUB_USER_NAME="Your Name"
export GITHUB_LOGIN="your-github-id"
export GITHUB_TOKEN="your-github-token"
```

### 2. 설치 및 실행

```bash
# 1. 저장소 클론
git clone https://github.com/your-org/openclaw-api-dev.git
cd openclaw-api-dev

# 2. 실행 권한 부여
chmod +x setup.sh setup-agent.sh

# 3. OpenClaw 설치 + API 키 감지 + 모델 설정
./setup.sh

# 4. 에이전트 4개 등록
./setup-agent.sh

# 5. 시작
openclaw start
```

---

## 환경변수

| 변수명 | 필수 여부 | 설명 |
|---|---|---|
| `ANTHROPIC_API_KEY` | 셋 중 하나 필수 | Anthropic API 키 |
| `OPENAI_API_KEY` | 셋 중 하나 필수 | OpenAI API 키 |
| `GEMINI_API_KEY` | 셋 중 하나 필수 | Google Gemini API 키 |
| `TELEGRAM_BOT_TOKEN` | 필수 | Telegram BotFather에서 발급 |
| `GOOGLE_CLIENT_ID` | 필수 | Google Cloud Console에서 발급 |
| `GOOGLE_CLIENT_SECRET` | 필수 | Google Cloud Console에서 발급 |
| `GOOGLE_REFRESH_TOKEN` | 필수 | OAuth 인증 후 발급 |
| `GITHUB_USER_EMAIL` | 필수 | GitHub 계정 이메일 |
| `GITHUB_USER_NAME` | 필수 | GitHub 계정 이름 (실명, `git log`에 표시됨) |
| `GITHUB_LOGIN` | 필수 | GitHub 로그인 아이디 (공백 없음, 예: `johndoe`) |
| `GITHUB_TOKEN` | 필수 | GitHub Personal Access Token |

---

## 파일 구조

```
openclaw-api-dev/
├── setup.sh                         # OpenClaw 설치 + API 키 감지 + 모델 설정
├── setup-agent.sh                   # 에이전트 4개 등록
│
├── agents/
│   ├── orchestrator/AGENTS.md       # 오케스트레이터 지침 (위임 로직)
│   ├── mail/AGENTS.md               # 메일 에이전트 지침
│   ├── calendar/AGENTS.md           # 일정 에이전트 지침
│   └── drive/AGENTS.md              # 문서 에이전트 지침
│
└── skills/
    ├── gmail/SKILL.md               # Gmail API 사용법
    ├── calendar/SKILL.md            # Calendar API 사용법
    └── drive/SKILL.md               # Drive/Docs API 사용법
```

---

## 런타임 모니터링

```bash
openclaw tui                    # 터미널 대시보드 (전체 현황)
openclaw gateway logs --follow  # 실시간 처리 로그
openclaw status                 # 게이트웨이·채널 상태 요약
openclaw agents list            # 등록된 에이전트 확인
openclaw agents bindings        # 봇↔에이전트 연결 확인
```

---

## 관련 레포

| 레포 | 설명 |
|---|---|
| [openclaw-ollama-dev](https://github.com/your-org/openclaw-ollama-dev) | Ollama 로컬 모델 버전 (GPU 필요, API 비용 없음) |
| [openclaw-ollama-image](https://github.com/your-org/openclaw-ollama-image) | Ollama 버전 Docker 이미지 |
| openclaw-api-image *(예정)* | API 버전 Docker 이미지 |

---

## 라이선스

MIT
