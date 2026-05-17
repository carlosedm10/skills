#!/usr/bin/env bash
# Shared helpers for platform installers.

set -euo pipefail

install_bundle() {
  local src="$1"
  local dest="$2"
  local mode="$3"
  if [[ ! -d "$src" ]]; then
    printf 'Source directory not found: %s\n' "$src" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  if [[ "$mode" == "symlink" ]]; then
    local abs
    abs="$(cd "$src" && pwd)"
    ln -sfn "$abs" "$dest"
  elif [[ "$mode" == "copy" ]]; then
    mkdir -p "$dest"
    cp -a "${src}/." "$dest/"
  else
    printf 'Invalid mode %s (expected copy or symlink)\n' "$mode" >&2
    return 1
  fi
}

skill_dir_valid() {
  [[ -f "$1/SKILL.md" ]]
}

list_skill_names() {
  local root="$1"
  local d name
  shopt -s nullglob
  for d in "${root}"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    skill_dir_valid "${d%/}" || continue
    printf '%s\n' "$name"
  done | sort -u
}

escape_toml_double() {
  local s=$1
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

ensure_gum() {
  command -v gum >/dev/null 2>&1 && return 0

  if [[ "${OSTYPE:-}" == darwin* ]] && command -v brew >/dev/null 2>&1; then
    printf '%s\n' "Installing gum via Homebrew..." >&2
    brew install gum >/dev/null 2>&1 || brew install gum
    command -v gum >/dev/null 2>&1 && return 0
  fi

  if command -v go >/dev/null 2>&1; then
    printf '%s\n' "Installing gum via go install..." >&2
    local gopath_bin="${GOPATH:-$HOME/go}/bin"
    mkdir -p "$gopath_bin"
    GOPATH="${GOPATH:-$HOME/go}" go install github.com/charmbracelet/gum@latest
    export PATH="$gopath_bin:$PATH"
    command -v gum >/dev/null 2>&1 && return 0
  fi

  return 1
}

gum_banner() {
  local title="$1"
  shift
  if command -v gum >/dev/null 2>&1; then
    gum style --border rounded --padding "1 2" --margin "1" "$title" "$@"
  else
    printf '\n━━ %s ━━\n%s\n\n' "$title" "$(printf '%s\n' "$@")"
  fi
}

_gum_choose_multi() {
  local header="$1"
  shift
  gum choose --limit 0 --selected-prefix "[x] " --unselected-prefix "[ ] " \
    --header "$header" "$@" 2>/dev/null \
    || gum choose --no-limit --selected-prefix "[x] " --unselected-prefix "[ ] " \
      --header "$header" "$@" 2>/dev/null \
    || gum choose --limit 99 --selected-prefix "[x] " --unselected-prefix "[ ] " \
      --header "$header" "$@" \
    || true
}

choose_platforms_interactive() {
  local choices=(
    "cursor"
    "claude-code"
    "codex"
    "opencode"
    "pi"
    "agents"
  )
  if command -v gum >/dev/null 2>&1; then
    _gum_choose_multi "Select platforms (↑/↓, space to toggle, enter to confirm):" \
      "${choices[@]}"
  else
    printf '%s\n' "Available platforms: ${choices[*]}" >&2
    printf 'Enter comma-separated names (default: all): ' >&2
    local line
    read -r line || true
    line="$(echo "$line" | xargs)"
    if [[ -z "$line" ]]; then
      printf '%s\n' "${choices[@]}"
      return
    fi
    IFS=',' read -ra picked <<<"$line"
    local p
    for p in "${picked[@]}"; do
      echo "$(echo "$p" | xargs)"
    done
  fi
}

choose_skills_interactive() {
  local -a names=( "$@" )
  if [[ ${#names[@]} -eq 0 ]]; then
    printf '%s\n' "No skills found under skills/ — add folders with SKILL.md." >&2
    return 1
  fi
  if command -v gum >/dev/null 2>&1; then
    _gum_choose_multi "Select skills (↑/↓, space to toggle, enter to confirm):" \
      "${names[@]}"
  else
    printf '%s\n' "Skills: ${names[*]}" >&2
    printf 'Enter comma-separated names or "all" (default: all): ' >&2
    local line
    read -r line || true
    line="$(echo "$line" | xargs)"
    if [[ -z "$line" || "$line" == "all" ]]; then
      printf '%s\n' "${names[@]}"
      return
    fi
    IFS=',' read -ra picked <<<"$line"
    local p
    for p in "${picked[@]}"; do
      echo "$(echo "$p" | xargs)"
    done
  fi
}

choose_mode_interactive() {
  if command -v gum >/dev/null 2>&1; then
    gum choose --header "Install mode:" "symlink" "copy"
  else
    printf 'Install mode [symlink/copy] (default copy): ' >&2
    local m
    read -r m || true
    m="$(echo "$m" | xargs)"
    [[ -z "$m" ]] && m="copy"
    printf '%s\n' "$m"
  fi
}
