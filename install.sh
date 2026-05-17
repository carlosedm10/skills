#!/usr/bin/env bash
set -euo pipefail

# When piped via `curl | bash`, BASH_SOURCE[0] is unset / not a real file.
# Download the repo tarball to a temp dir and re-run from there.
if [[ -z "${BASH_SOURCE[0]:-}" ]] || [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  echo "Downloading skills repo..."
  curl -fsSL "https://github.com/carlosedm10/skills/archive/refs/heads/main.tar.gz" \
    | tar -xz -C "$TMP" --strip-components=1
  bash "$TMP/install.sh" "$@"
  exit $?
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS="${ROOT}/install/utils.sh"
# shellcheck source=install/utils.sh
source "${UTILS}"

usage() {
  sed -n '1,120p' <<'USAGE'
Usage:
  install.sh                  Interactive installer
  install.sh new <name>       Copy skill-template/ → skills/<name>/
  install.sh [options]        Non-interactive install

Options:
  -y, --yes              Assume yes for prompts
  --platforms LIST       Comma-separated: cursor,claude-code,codex,opencode,pi,agents
  --skills LIST          Comma-separated skill folder names, or "all"
  --mode MODE            copy | symlink

Environment:
  CODEX_HOME             Override Codex config dir (default: ~/.codex)
USAGE
}

cmd_new() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    printf 'Usage: install.sh new <skill-name>\n' >&2
    exit 1
  fi
  if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    printf 'Skill name must be kebab-case (lowercase letters, digits, hyphens).\n' >&2
    exit 1
  fi
  local dest="${ROOT}/skills/${name}"
  if [[ -e "$dest" ]]; then
    printf 'Already exists: %s\n' "$dest" >&2
    exit 1
  fi
  mkdir -p "$dest"
  cp "${ROOT}/skill-template/SKILL.md" "${dest}/SKILL.md"
  if sed --version >/dev/null 2>&1; then
    sed -i "s/skill-template/${name}/g" "${dest}/SKILL.md"
  else
    sed -i '' "s/skill-template/${name}/g" "${dest}/SKILL.md"
  fi
  printf 'Created %s — edit name/description in SKILL.md.\n' "${dest}/SKILL.md"
}

INTERACTIVE="1"
ASSUME_YES="0"
MODE=""
PLATFORMS_CSV=""
SKILLS_CSV=""

SUBCOMMAND=""
if [[ "${1:-}" == "new" ]]; then
  SUBCOMMAND="new"
  shift
  cmd_new "${1:-}"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -y|--yes)
      ASSUME_YES="1"
      INTERACTIVE="0"
      shift
      ;;
    --platforms)
      PLATFORMS_CSV="$2"
      INTERACTIVE="0"
      shift 2
      ;;
    --skills)
      SKILLS_CSV="$2"
      INTERACTIVE="0"
      shift 2
      ;;
    --mode)
      MODE="$2"
      INTERACTIVE="0"
      shift 2
      ;;
    install|"")
      shift || true
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

SKILLS_DIR="${ROOT}/skills"
mkdir -p "${SKILLS_DIR}"

ALL_SKILLS=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && ALL_SKILLS+=("${line}")
done <<< "$(list_skill_names "${SKILLS_DIR}")"

if [[ "$INTERACTIVE" == "1" ]]; then
  if ! ensure_gum; then
    printf '%s\n' "Note: gum not installed — using plain prompts (install gum for a richer UI)." >&2
  fi

  gum_banner "Agent skills installer" \
    "Select platforms and skills to install."

  platforms_raw="$(choose_platforms_interactive)" || true
  SELECTED_PLATFORMS=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && SELECTED_PLATFORMS+=("${line}")
  done <<< "${platforms_raw}"
  if [[ ${#SELECTED_PLATFORMS[@]} -eq 0 || -z "${SELECTED_PLATFORMS[0]:-}" ]]; then
    printf 'No platforms selected.\n' >&2
    exit 1
  fi

  skills_raw="$(choose_skills_interactive "${ALL_SKILLS[@]}")" || true
  SELECTED_SKILLS=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && SELECTED_SKILLS+=("${line}")
  done <<< "${skills_raw}"
  if [[ ${#SELECTED_SKILLS[@]} -eq 0 || -z "${SELECTED_SKILLS[0]:-}" ]]; then
    printf 'No skills selected.\n' >&2
    exit 1
  fi

  MODE="$(choose_mode_interactive)"
  MODE="$(echo "$MODE" | xargs)"
  [[ "$MODE" == "symlink" || "$MODE" == "copy" ]] || MODE="copy"

  PLATFORMS_CSV="$(IFS=,; echo "${SELECTED_PLATFORMS[*]}")"
  SKILLS_CSV="$(IFS=,; echo "${SELECTED_SKILLS[*]}")"
fi

[[ -n "$MODE" ]] || MODE="copy"

if [[ "$SKILLS_CSV" == "all" || -z "$SKILLS_CSV" ]]; then
  if [[ ${#ALL_SKILLS[@]} -eq 0 ]]; then
    printf 'No skills found under %s\n' "${SKILLS_DIR}" >&2
    exit 1
  fi
  SKILLS_CSV="$(IFS=,; echo "${ALL_SKILLS[*]}")"
fi

if [[ -z "$PLATFORMS_CSV" ]]; then
  printf 'No platforms specified (use interactive mode or --platforms).\n' >&2
  exit 1
fi

if [[ "$INTERACTIVE" != "1" && "$ASSUME_YES" != "1" ]]; then
  read -r -p "Install mode=${MODE}, platforms=${PLATFORMS_CSV}, skills=${SKILLS_CSV} — proceed? [y/N] " ans || true
  [[ "${ans:-}" =~ ^[Yy]$ ]] || exit 0
fi

chmod +x "${ROOT}/install/batch-install.sh" 2>/dev/null || true

if command -v gum >/dev/null 2>&1 && [[ "${INTERACTIVE}" == "1" ]]; then
  gum spin --spinner minidot --title "Installing skills..." -- \
    bash "${ROOT}/install/batch-install.sh" \
    --mode "${MODE}" \
    --skills-dir "${SKILLS_DIR}" \
    --skills "${SKILLS_CSV}" \
    --platforms "${PLATFORMS_CSV}"
else
  bash "${ROOT}/install/batch-install.sh" \
    --mode "${MODE}" \
    --skills-dir "${SKILLS_DIR}" \
    --skills "${SKILLS_CSV}" \
    --platforms "${PLATFORMS_CSV}"
fi

if command -v gum >/dev/null 2>&1; then
  gum style --foreground 10 --padding "0 1" "Installation finished."
else
  printf '%s\n' "Installation finished."
fi
