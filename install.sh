#!/usr/bin/env bash
set -Eeuo pipefail

SKILL_NAME="minimax-h3-colab"
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
FORCE=0
DEST_ROOT=""
TARGET_CLI="gemini"

usage() {
  cat <<'EOF'
Install the MiniMax H3 Colab skill into Gemini CLI and/or Codex skills directory.

Usage:
  ./install.sh [--gemini | --codex | --all] [--force]
  ./install.sh [--dest SKILLS_DIR] [--force]

Targets:
  --gemini     Install to Gemini CLI ($GEMINI_HOME/skills or ~/.gemini/skills) [Default]
  --codex      Install to Codex ($CODEX_HOME/skills or ~/.codex/skills)
  --all        Install to both Gemini CLI and Codex
  --dest PATH  Custom skills directory to use

Options:
  --force      Replace an existing install after moving it to a timestamped backup
  -h, --help   Show this help

The default install is deliberately non-destructive: an existing skill directory
is kept intact and the command exits successfully. Use --force only when replacing
that installation is intended.
EOF
}

while (($#)); do
  case "$1" in
    --gemini)
      TARGET_CLI="gemini"
      shift
      ;;
    --codex)
      TARGET_CLI="codex"
      shift
      ;;
    --all)
      TARGET_CLI="all"
      shift
      ;;
    --dest)
      (($# >= 2)) || { echo "Missing path after --dest." >&2; usage >&2; exit 2; }
      DEST_ROOT="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for required in SKILL.md scripts/runner.py assets/MiniMax_H3_Turbo_Colab.ipynb; do
  [[ -f "$REPO_DIR/$required" ]] || { echo "Repository is missing required file: $required" >&2; exit 2; }
done

install_to() {
  local skills_root="$1"
  local label="$2"

  skills_root="$(python3 -c 'import os, sys; print(os.path.abspath(os.path.expanduser(sys.argv[1])))' "$skills_root")"
  local target="$skills_root/$SKILL_NAME"

  mkdir -p "$skills_root"

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ "$FORCE" != 1 ]]; then
      if [[ -d "$target" ]]; then
        echo "[$label] Skill already installed; preserving: $target"
        echo "       Use --force to replace it (the old directory will be backed up)."
        return 0
      fi
      echo "[$label] Refusing to replace non-directory path: $target" >&2
      return 2
    fi
    [[ -d "$target" && ! -L "$target" ]] || { echo "[$label] Refusing to replace non-directory or symlink path: $target" >&2; return 2; }
  fi

  local staging
  staging="$(mktemp -d "$skills_root/.${SKILL_NAME}.install.XXXXXXXX")"
  local backup=""

  cp -R "$REPO_DIR/SKILL.md" "$staging/SKILL.md"
  cp -R "$REPO_DIR/scripts" "$staging/scripts"
  cp -R "$REPO_DIR/assets" "$staging/assets"
  find "$staging" -type d -name __pycache__ -prune -exec rm -rf {} +
  chmod +x "$staging/scripts/runner.py" 2>/dev/null || true

  if [[ -e "$target" || -L "$target" ]]; then
    local timestamp
    timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
    backup="$target.backup.$timestamp"
    local suffix=0
    while [[ -e "$backup" || -L "$backup" ]]; do
      suffix=$((suffix + 1))
      backup="$target.backup.$timestamp.$suffix"
    done
    mv "$target" "$backup"
  fi

  if ! mv "$staging" "$target"; then
    if [[ -n "$backup" && ! -e "$target" ]]; then
      mv "$backup" "$target"
    fi
    echo "[$label] Could not install skill at: $target" >&2
    return 1
  fi

  echo "[$label] Installed $SKILL_NAME to $target"
  if [[ -n "$backup" ]]; then
    echo "       Previous installation preserved at $backup"
  fi
}

HOME_DIR="${HOME:-}"

if [[ -n "$DEST_ROOT" ]]; then
  install_to "$DEST_ROOT" "Custom"
  exit 0
fi

GEMINI_SKILLS="${GEMINI_HOME:-$HOME_DIR/.gemini}/skills"
CODEX_SKILLS="${CODEX_HOME:-$HOME_DIR/.codex}/skills"

case "$TARGET_CLI" in
  gemini)
    install_to "$GEMINI_SKILLS" "Gemini CLI"
    ;;
  codex)
    install_to "$CODEX_SKILLS" "Codex"
    ;;
  all)
    install_to "$GEMINI_SKILLS" "Gemini CLI"
    install_to "$CODEX_SKILLS" "Codex"
    ;;
esac
