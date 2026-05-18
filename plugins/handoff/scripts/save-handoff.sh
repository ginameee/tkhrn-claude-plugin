#!/usr/bin/env bash
set -eo pipefail

input="$(cat)"

transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // empty')"
trigger="$(printf '%s' "$input" | jq -r '.trigger // "unknown"')"
session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"

outdir="${HOME}/.claude/handoffs"
mkdir -p "$outdir"

ts="$(date +%Y%m%d-%H%M%S)"
outfile="${outdir}/handoff-${ts}-${trigger}.md"

{
  printf '# Handoff Document\n\n'
  printf -- '- **Generated**: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf -- '- **Trigger**: PreCompact / %s\n' "$trigger"
  printf -- '- **Session**: %s\n' "$session_id"
  printf -- '- **Working dir**: %s\n' "${cwd:-unknown}"
  printf -- '- **Source transcript**: %s\n\n' "${transcript_path:-unknown}"
  printf -- '---\n\n## Conversation\n\n'

  if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    jq -r '
      def render_content:
        if . == null then ""
        elif type == "string" then .
        elif type == "array" then
          map(
            if .type == "text" then (.text // "")
            elif .type == "tool_use" then
              "**Tool: " + (.name // "?") + "**\n\n```json\n" + ((.input // {}) | tostring) + "\n```"
            elif .type == "tool_result" then
              "**Tool result:**\n\n```\n" + (
                if (.content | type) == "array" then
                  (.content | map(if .type == "text" then (.text // "") else (. | tostring) end) | join("\n"))
                else ((.content // "") | tostring)
                end
              ) + "\n```"
            elif .type == "thinking" then
              "<details><summary>thinking</summary>\n\n" + (.thinking // "") + "\n\n</details>"
            else "_[" + (.type // "unknown") + "]_"
            end
          ) | join("\n\n")
        else (. | tostring)
        end;

      if .type == "user" then
        "### User\n\n" + (((.message.content // .content) // "") | render_content) + "\n"
      elif .type == "assistant" then
        "### Assistant\n\n" + (((.message.content // .content) // "") | render_content) + "\n"
      elif .type == "summary" then
        "### Summary\n\n" + ((.summary // "") | tostring) + "\n"
      else empty
      end
    ' "$transcript_path" 2>/dev/null || printf '_(Transcript parsing failed. Raw file: %s)_\n' "$transcript_path"
  else
    printf '_(Transcript file not available)_\n'
  fi
} > "$outfile"

jq -nc --arg msg "Handoff saved -> ${outfile}" '{systemMessage: $msg}'
