# Claude Plugin to Gemini Extension 마이그레이션 가이드

이 문서는 Claude용으로 개발된 플러그인(Plugin)을 Gemini CLI의 확장 프로그램(Extension) 및 스킬(Skill) 시스템으로 이관하는 방법을 안내합니다.

## 1. 개념 매핑

*   **Claude Plugin**: Gemini CLI의 **Extension (확장 프로그램)**에 해당합니다. 여러 관련 스킬들을 묶는 논리적인 그룹입니다.
*   **Claude Plugin 내 개별 기능**: Gemini CLI의 **Skill (스킬)**에 해당합니다. `SKILL.md` 파일을 통해 정의되는 개별 작업 단위입니다.

## 2. 필수 파일 및 디렉토리 구조

Gemini CLI는 전역으로 설치된 확장 프로그램을 `~/.gemini/extensions/` 디렉토리에서 로드합니다. 각 확장 프로그램은 고유한 하위 디렉토리에 위치해야 하며, 스킬을 포함하려면 해당 확장 프로그램 디렉토리 내에 `skills/` 하위 디렉토리를 사용해야 합니다.

**필수 구조:**

```text
~/.gemini/extensions/
└── <extension-name>/
    ├── gemini-extension.json       # (필수) 확장 프로그램 매니페스트 파일
    └── skills/                     # (스킬이 있을 경우 필수) 스킬 디렉토리
        └── <skill-name>/           # 특정 스킬 디렉토리
            └── SKILL.md            # (필수) 스킬 정의 및 매니페스트
```

**명명 규칙:**

*   `<extension-name>` 디렉토리 이름은 `gemini-extension.json` 파일 내의 `name` 속성과 **반드시 일치**해야 합니다.
*   이름은 소문자와 대시(-)를 사용하여 명명하는 것이 좋습니다 (예: `my-frontend-extension`).

## 3. `gemini-extension.json` 작성 가이드

이 파일은 Gemini CLI가 특정 디렉토리를 유효한 확장 프로그램으로 인식하도록 만드는 매니페스트 파일입니다.

**필수 내용:**

최소한 `name`과 `version` 필드를 포함해야 합니다. `description` 필드는 확장 프로그램 관리 시 유용합니다.

```json
{
  "name": "frontend",
  "version": "1.0.0",
  "description": "프론트엔드 개발 관련 유용한 스킬 모음"
}
```

## 4. `SKILL.md` 작성 가이드

`skills/` 디렉토리 내의 각 스킬은 `SKILL.md` 파일을 통해 정의됩니다. 이 파일은 YAML frontmatter를 사용하여 스킬의 메타데이터를 정의하며, Gemini CLI가 스킬을 발견하고 자동 활성화하는 데 사용됩니다.

**필수 내용:**

`SKILL.md` 파일은 YAML 블록으로 시작해야 합니다.

```markdown
---
name: frontend-a11y-perf
description: WCAG 2.1 AA 접근성 + Core Web Vitals 성능 + 반응형·모바일 우선 설계 검토. UI 컴포넌트 작성·리뷰 시 수동 호출.
---

# 스킬 지침
(여기에 스킬에 대한 구체적인 절차 및 지침을 상세하게 작성합니다.)
```

*   **참고**: `description` 필드는 Gemini CLI가 사용자의 요청에 따라 스킬을 활성화할지 결정하는 중요한 트리거 역할을 합니다. 매우 명확하고 구체적으로 작성해야 합니다.

## 5. 마이그레이션 단계 (실행 명령어)

에이전트에게는 전역 디렉토리(`~/.gemini/extensions/`)에 직접 파일을 쓰거나 복사할 권한이 없으므로, 사용자님이 직접 터미널에서 다음 명령어를 실행해야 합니다.

1.  **임시 확장 프로그램 디렉토리 생성 및 스킬 파일 복사:**
    현재 프로젝트 디렉토리 내에 임시로 올바른 구조의 확장 프로그램 디렉토리를 만들고, 기존 Claude 플러그인의 스킬 파일들을 복사합니다.

    ```bash
    mkdir -p .tmp_extensions/frontend/skills && mkdir -p .tmp_extensions/devlog/skills && 
    cp -R plugins/frontend/skills/* .tmp_extensions/frontend/skills/ && 
    cp -R plugins/devlog/skills/* .tmp_extensions/devlog/skills/
    ```

2.  **`gemini-extension.json` 파일 생성:**
    각 확장 프로그램의 루트 디렉토리에 `gemini-extension.json` 파일을 생성합니다. (위 `3. gemini-extension.json 작성 가이드` 참조)

    ```bash
    echo '{ "name": "frontend", "version": "1.0.0", "description": "프론트엔드 개발 관련 유용한 스킬 모음" }' > .tmp_extensions/frontend/gemini-extension.json
    echo '{ "name": "devlog", "version": "1.0.0", "description": "개발 블로그 관리 스킬 모음" }' > .tmp_extensions/devlog/gemini-extension.json
    ```

3.  **생성된 임시 확장 프로그램을 Gemini 전역 설정으로 복사:**
    이제 `.tmp_extensions/`에 있는 확장 프로그램 디렉토리들을 Gemini CLI의 전역 확장 프로그램 경로로 복사합니다.

    ```bash
    cp -R .tmp_extensions/frontend /Users/jangchun.lee/.gemini/extensions/
    cp -R .tmp_extensions/devlog /Users/jangchun.lee/.gemini/extensions/
    ```

4.  **임시 디렉토리 삭제 (선택 사항):**
    마이그레이션이 완료되면 임시 디렉토리는 삭제해도 됩니다.

    ```bash
    rm -rf .tmp_extensions
    ```

## 6. 확인 방법

위 단계를 모두 완료한 후, 현재 Gemini CLI 세션을 종료하고 다시 시작합니다.

새 세션에서 Gemini CLI는 `~/.gemini/extensions/` 디렉토리를 스캔하여 새로 설치된 확장 프로그램과 스킬들을 인식하고 로드할 것입니다. 정상적으로 로드되었다면, 이제 해당 스킬들을 활용할 수 있습니다.
