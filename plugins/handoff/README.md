# handoff

PreCompact 직전(자동 컴팩션 + /compact 수동 호출 모두)에 현재 대화 내용을 markdown 파일로 자동 저장하는 Claude Code 플러그인.

## 목적

- 컨텍스트 컴팩션으로 작업 흐름이 사라지기 전에 **인계 가능한 스냅샷** 확보
- 다른 에이전트(또는 미래의 자기 자신)에게 현재까지의 작업을 전달
- 장기 프로젝트에서 시점별 기록 보존

## 동작

`PreCompact` hook이 발동되면:

1. 현재 세션의 transcript JSONL을 읽어
2. `~/.claude/handoffs/handoff-YYYYMMDD-HHMMSS-{auto|manual}.md` 로 markdown 변환 저장
3. `systemMessage` 로 저장 경로를 알림

저장된 md는 다음을 포함:
- 생성 시각, 트리거(auto/manual), 세션 ID, 작업 디렉토리, 원본 transcript 경로
- 사용자 프롬프트 / 어시스턴트 응답 / 도구 사용 / 도구 결과 / thinking (collapsed)

> **주의**: hook은 비대화형 셸에서 실행되므로 저장 여부를 사용자에게 직접 묻지는 못함.
> 항상 저장하고, 불필요한 파일은 사후에 `~/.claude/handoffs/` 에서 정리.

## 설치

```bash
# 마켓플레이스 추가 (이미 추가되어 있다면 스킵)
/plugin marketplace add ginameee/tkhrn-claude-plugin

# 플러그인 설치
/plugin install handoff@tkhrn-plugins
```

또는 `~/.claude/settings.json` 에 직접:

```json
{
  "enabledPlugins": {
    "handoff@tkhrn-plugins": true
  }
}
```

## 의존성

- `bash`, `jq`, `date` (mac/linux 기본 제공 또는 `brew install jq`)

## 파일 정리

저장된 핸드오프는 자동 삭제되지 않음. 주기적으로 정리하려면:

```bash
# 30일 지난 파일 삭제
find ~/.claude/handoffs -name 'handoff-*.md' -mtime +30 -delete
```

## 커스터마이징

다른 저장 경로를 쓰고 싶으면 `scripts/save-handoff.sh` 의 `outdir` 변수 수정.
