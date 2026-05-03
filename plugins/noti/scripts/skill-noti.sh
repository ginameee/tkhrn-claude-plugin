#!/usr/bin/env bash
set -eo pipefail

input="$(cat)"

skill_name="$(printf '%s' "$input" | jq -r '.tool_input.skill // empty')"
skill_args="$(printf '%s' "$input" | jq -r '.tool_input.args // empty')"

if [[ -z "$skill_name" ]]; then
  exit 0
fi

if [[ -n "$skill_args" ]]; then
  args_preview="${skill_args:0:120}"
  if [[ ${#skill_args} -gt 120 ]]; then
    args_preview="${args_preview}..."
  fi
  msg="Skill → ${skill_name} (args: ${args_preview})"
else
  msg="Skill → ${skill_name}"
fi

jq -nc --arg msg "$msg" '{systemMessage: $msg}'
