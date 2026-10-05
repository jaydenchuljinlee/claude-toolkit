#!/usr/bin/env bash
# global/ 아래 설정을 ~/.claude 에 심볼릭 링크로 설치한다.
# 레포를 수정하면 ~/.claude 에 바로 반영되므로 둘이 따로 놀지 않는다.
#
#   ./install.sh            설치 (기존 파일은 ~/.claude/backups/toolkit-<시각>/ 으로 옮김)
#   ./install.sh --dry-run  무엇을 할지 출력만
set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

SRC="$(cd "$(dirname "$0")" && pwd)/global"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
BACKUP="$DEST/backups/toolkit-$(date +%Y%m%d-%H%M%S)"

run() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "[dry-run] $*"; else "$@"; fi
}

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok       ${dest#$DEST/}"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    run mkdir -p "$BACKUP/$(dirname "${dest#$DEST/}")"
    run mv "$dest" "$BACKUP/${dest#$DEST/}"
    echo "backup   ${dest#$DEST/}"
  fi
  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  echo "link     ${dest#$DEST/}"
}

link "$SRC/CLAUDE.md" "$DEST/CLAUDE.md"
for kind in skills agents commands output-styles; do
  [ -d "$SRC/$kind" ] || continue
  for item in "$SRC/$kind"/*; do
    [ -e "$item" ] || continue
    link "$item" "$DEST/$kind/$(basename "$item")"
  done
done

[ -d "$BACKUP" ] && echo "기존 파일 백업: $BACKUP"
echo "완료."
