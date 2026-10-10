#!/usr/bin/env bash
# Merge/conflict report: pelya/openttd-android#14 vs OpenTTD/OpenTTD#16.0-beta4
# Used by CI and locally. Needs: git, network. Read-only (uses temp clone).
set -u
PORT_REPO="${PORT_REPO:-https://github.com/pelya/openttd-android.git}"
PORT_REF="${PORT_REF:-14}"
UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/OpenTTD/OpenTTD.git}"
UPSTREAM_REF="${UPSTREAM_REF:-16.0-beta4}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "== cloning (blobless) =="
git clone --filter=blob:none --no-checkout "$PORT_REPO" "$WORK/port" -q
git -C "$WORK/port" checkout -q "$PORT_REF"
git -C "$WORK/port" remote add upstream "$UPSTREAM_REPO"
git -C "$WORK/port" fetch -q --filter=blob:none upstream tag "$UPSTREAM_REF"
BASE="$(git -C "$WORK/port" merge-base "$PORT_REF" "$UPSTREAM_REF")"
echo "port=$PORT_REF upstream=$UPSTREAM_REF merge-base=$BASE"
echo "== upstream diffstat ($BASE..$UPSTREAM_REF) =="
git -C "$WORK/port" diff --shortstat "$BASE..$UPSTREAM_REF"
echo "== port diffstat ($BASE..$PORT_REF) =="
git -C "$WORK/port" diff --shortstat "$BASE..$PORT_REF"
echo "== conflict count (merge-tree) =="
if git -C "$WORK/port" merge-tree "$(git -C "$WORK/port" merge-base "$PORT_REF" "$UPSTREAM_REF")" "$PORT_REF" "$UPSTREAM_REF" >/dev/null 2>&1; then
  # modern git: merge-tree writes conflicted blobs; count unmerged via temporary index instead
  git -C "$WORK/port" checkout -q -b report "$PORT_REF"
  if git -C "$WORK/port" merge --no-commit --no-ff "$UPSTREAM_REF" >/dev/null 2>&1; then
    echo "conflicts=0 (clean merge)"
  else
    echo "conflicts=$(git -C "$WORK/port" diff --name-only --diff-filter=U | wc -l)"
    git -C "$WORK/port" diff --name-only --diff-filter=U | head -50
  fi
  git -C "$WORK/port" merge --abort >/dev/null 2>&1 || true
else
  git -C "$WORK/port" checkout -q -b report "$PORT_REF"
  git -C "$WORK/port" merge --no-commit --no-ff "$UPSTREAM_REF" >/dev/null 2>&1 || true
  echo "conflicts=$(git -C "$WORK/port" diff --name-only --diff-filter=U | wc -l)"
  git -C "$WORK/port" merge --abort >/dev/null 2>&1 || true
fi
echo "== migration blockers =="
git -C "$WORK/port" show "$UPSTREAM_REF:src/video/sdl_v.cpp" >/dev/null 2>&1 && echo "sdl1_driver_present=yes" || echo "sdl1_driver_present=no (SDL2 migration required)"
git -C "$WORK/port" show "$UPSTREAM_REF:cmake/FindICU.cmake" >/dev/null 2>&1 && echo "custom_FindICU_present=yes" || echo "custom_FindICU_present=no (builtin FindICU)"
git -C "$WORK/port" show "$UPSTREAM_REF:cmake/FindSoxr.cmake" >/dev/null 2>&1 && echo "soxr=yes" || echo "soxr=no"
git -C "$WORK/port" show "$UPSTREAM_REF:cmake/FindOpusFile.cmake" >/dev/null 2>&1 && echo "opusfile=yes" || echo "opusfile=no"
