# noti

Claude Code 동작에 대한 가벼운 알림 훅 모음. 향후 다른 noti 류 훅도 이 플러그인에 추가 예정.

## 현재 제공 훅

### Skill 호출 알림 (PreToolUse / Skill)

Claude가 `Skill` 도구로 skill을 호출하기 직전에 어떤 skill이 어떤 args로 실행되는지 `systemMessage`로 알림.

예시 출력:
```
Skill → sc:brainstorm (args: plugin organization)
Skill → update-config
```

긴 args는 120자에서 자동 절단됨. Skill 외 도구(Bash, Edit 등)는 알리지 않음.

## 목적

- Claude가 자동 활성화한 skill을 사용자가 인지할 수 있도록
- 어떤 시점에 어떤 skill이 동작했는지 transcript에서 추적 용이
- 의도와 다른 skill이 호출되는 경우 빠르게 감지

## 설치

```bash
/plugin marketplace add ginameee/tkhrn-claude-plugin
/plugin install noti@tkhrn-plugins
```

또는 `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "noti@tkhrn-plugins": true
  }
}
```

## 의존성

- `bash`, `jq`

## 향후 확장 후보

- 도구 실패 알림 (PostToolUseFailure)
- 컨텍스트 사용량 임계 알림
- 특정 도구(예: WebFetch) 호출 알림
