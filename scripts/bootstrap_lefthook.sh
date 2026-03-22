#!/usr/bin/env sh
set -eu

LEFTHOOK_VERSION="${LEFTHOOK_VERSION:-1.7.10}"
BIN_DIR="${BIN_DIR:-.bin}"
BIN="$BIN_DIR/lefthook"

mkdir -p "$BIN_DIR"

if [ ! -x "$BIN" ]; then
  echo "Downloading lefthook v$LEFTHOOK_VERSION ..."

  OS="$(uname -s)"
  ARCH="$(uname -m)"

  case "$OS" in
    Linux)  OS=Linux ;;
    Darwin) OS=Darwin ;;
    *)
      echo "Unsupported OS: $OS" >&2
      exit 2
      ;;
  esac

  case "$ARCH" in
    x86_64|amd64) ARCH=x86_64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *)
      echo "Unsupported arch: $ARCH" >&2
      exit 2
      ;;
  esac

  ASSET_NAME="lefthook_${LEFTHOOK_VERSION}_${OS}_${ARCH}"
  URL="https://github.com/evilmartians/lefthook/releases/download/v${LEFTHOOK_VERSION}/${ASSET_NAME}"
  CHECKSUMS_URL="https://github.com/evilmartians/lefthook/releases/download/v${LEFTHOOK_VERSION}/lefthook_${LEFTHOOK_VERSION}_checksums.txt"

  TMP_BIN="${BIN}.tmp"
  TMP_SUM="${TMP_BIN}.sha256"

  curl --fail --show-error --silent --location \
     --proto '=https' \
     --tlsv1.2 \
     "$URL" -o "$TMP_BIN"

  curl --fail --show-error --silent --location \
     --proto '=https' \
     --tlsv1.2 \
     "$CHECKSUMS_URL" -o "$TMP_SUM"

  EXPECTED_SUM_LINE="$(grep " ${ASSET_NAME}"'$' "$TMP_SUM" || true)"
  if [ -z "$EXPECTED_SUM_LINE" ]; then
    echo "Failed to find checksum for ${ASSET_NAME} in ${CHECKSUMS_URL}" >&2
    rm -f "$TMP_BIN" "$TMP_SUM"
    exit 1
  fi

  EXPECTED_SUM="$(printf '%s\n' "$EXPECTED_SUM_LINE" | awk '{print $1}')"

  if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_SUM="$(sha256sum "$TMP_BIN" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    ACTUAL_SUM="$(shasum -a 256 "$TMP_BIN" | awk '{print $1}')"
  else
    echo "Neither sha256sum nor shasum is available for checksum verification" >&2
    rm -f "$TMP_BIN" "$TMP_SUM"
    exit 1
  fi

  if [ "$EXPECTED_SUM" != "$ACTUAL_SUM" ]; then
    echo "Checksum verification failed for ${ASSET_NAME}" >&2
    rm -f "$TMP_BIN" "$TMP_SUM"
    exit 1
  fi

  mv "$TMP_BIN" "$BIN"
  rm -f "$TMP_SUM"
  chmod +x "$BIN"
fi

echo "Lefthook available at: $BIN"
