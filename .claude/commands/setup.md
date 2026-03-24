# /setup

setup.sh 를 작성 또는 수정한다.

스펙 참조: @spec/SPEC.md

## 작업 순서

1. **.env 검증**
   - 프로젝트 루트 `.env` 로드 (있을 경우)
   - 필수 변수 확인: `TELEGRAM_BOT_TOKEN`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`,
     `GOOGLE_REFRESH_TOKEN`, `ANTHROPIC_API_KEY`,
     `ORCHESTRATOR_MODEL`, `MAIL_MODEL`, `CALENDAR_MODEL`, `DRIVE_MODEL`, `FALLBACK_MODEL`
   - 미설정 변수 목록 출력 후 `log_stop` 종료

2. **Node.js 확인**
   - 미설치 또는 22 미만이면 NodeSource 스크립트로 설치:
     ```bash
     curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
     apt-get install -y nodejs
     ```
   - 설치 후 버전 재확인

3. **gogcli 설치**
   - 미설치 시:
     1. gogcli go.mod에서 요구 Go 버전 확인 → Ubuntu `golang-go`는 버전이 낮아 사용 불가
     2. 공식 Go 바이너리 설치:
        ```bash
        GO_VERSION="<gogcli go.mod의 go directive에 맞춰 조정>"
        curl -OL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        ```
     3. 빌드 의존성: `apt-get install -y make build-essential`
     4. `/tmp`에 `https://github.com/steipete/gogcli.git` clone → `make` → `/usr/local/bin/gog` 복사
   - 설치됨 시: 버전 출력

3-1. **Chromium 헤드리스 설치** (gogcli 설치 완료 후)
   - xtradeb PPA(`ppa:xtradeb/apps`)로 설치 (snap wrapper 오류 방지)
   - 이미 설치된 경우 버전 출력 후 건너뜀
   - 설치 실패 시 `log_warn` (스크립트 중단 안 함)

4. **OpenClaw 설치**
   - 미설치 시: `npm install -g openclaw`
   - 설치됨 시: 버전 출력

5. **openclaw.json 생성** (`~/.openclaw/openclaw.json`)
   - `models.providers.anthropic`: apiKey `${ANTHROPIC_API_KEY}`
   - `agents.defaults`: compaction safeguard, runTimeoutSeconds 120
   - `agents.list`: orchestrator, mail, calendar, drive
     - 각 에이전트 `model.primary`에 해당 `${*_MODEL}` 환경변수 그대로 사용
       (예: `"${ORCHESTRATOR_MODEL}"` → 값이 `anthropic/claude-sonnet-4-6` 형태)
     - `model.fallbacks`: `["${FALLBACK_MODEL}"]`
     - orchestrator의 `subagents.allowAgents`: ["mail", "calendar", "drive"]
   - `channels.telegram`: botToken, dmPolicy open, dmScope per-channel-peer, allowFrom ["*"]
   - `env`: GOG_ACCOUNT, GOG_ACCESS_TOKEN (빈 문자열, run.sh에서 동적 업데이트)
   - `tools.exec`: enabled true, host "gateway"
   - **plugins**: `telegram`, `duckduckgo` 모두 `enabled: true`
   - **gateway**: port **18789**, bind **loopback**, trustedProxies ["127.0.0.1"],
     dangerouslyAllowHostHeaderOriginFallback true

6. **~/.openclaw/.env 생성** (chmod 600)
   - Google 인증 정보 + 봇 토큰 + API 키 + 모델명 기록
   - `printf '%s\n'` 사용 (특수문자 안전)

## 로그 스타일

CLAUDE.md의 로그 함수를 사용한다.
