#!/usr/bin/env bash
# 본보기 저장소의 원격 main을 캐시 폴더로 받아 오고, 그 경로를 한 줄로 출력한다.
# 캐시가 있으면 원격 최신으로 맞춘다. 캐시는 이 스크립트 전용이라 덮어써도 된다.
set -u

REMOTE="https://github.com/jaydenchuljinlee/hhplus-ecommerce.git"
BRANCH="main"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/spring-kotlin-blueprint/hhplus-ecommerce"

if [ -d "$CACHE/.git" ]; then
  # 네트워크가 안 되면 기존 캐시를 그대로 쓴다.
  if git -C "$CACHE" fetch -q --depth 1 origin "$BRANCH" 2>/dev/null; then
    git -C "$CACHE" reset -q --hard FETCH_HEAD
  else
    echo "원격에 연결하지 못해 기존 캐시를 사용함" >&2
  fi
else
  mkdir -p "$(dirname "$CACHE")"
  if ! git clone -q --depth 1 --branch "$BRANCH" "$REMOTE" "$CACHE"; then
    echo "본보기 저장소를 받지 못함: $REMOTE" >&2
    exit 1
  fi
fi

echo "커밋: $(git -C "$CACHE" log -1 --format='%h %cs')" >&2
echo "$CACHE"
