#!/usr/bin/env bash
#
# 在 macOS Runner 上安装 iOS 签名材料：临时 Keychain + Apple Distribution 证书 + Provisioning Profiles。
# 本脚本只负责"准备签名材料"，不负责构建，因此 GitLab / CircleCI 的 macOS Runner 也能直接复用。
#
# 必需环境变量：
#   IOS_CERTIFICATE_P12_BASE64  Apple Distribution 证书（含私钥）的 Base64
#   IOS_CERTIFICATE_PASSWORD    .p12 导出密码
#   IOS_PROFILES_ZIP_BASE64     包含所有 .mobileprovision 的 ZIP 的 Base64
#   KEYCHAIN_PASSWORD           CI 临时 Keychain 的密码（任意随机串）
#
# 用法：bash scripts/ci/setup_ios_signing.sh
set -euo pipefail

: "${IOS_CERTIFICATE_P12_BASE64:?缺少 IOS_CERTIFICATE_P12_BASE64}"
: "${IOS_CERTIFICATE_PASSWORD:?缺少 IOS_CERTIFICATE_PASSWORD}"
: "${IOS_PROFILES_ZIP_BASE64:?缺少 IOS_PROFILES_ZIP_BASE64}"
: "${KEYCHAIN_PASSWORD:?缺少 KEYCHAIN_PASSWORD}"

# 跨 CI 的临时目录：GitHub 用 RUNNER_TEMP，其他环境退回 TMPDIR/tmp。
CI_TMP_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
KEYCHAIN_PATH="$CI_TMP_DIR/flutter-ci.keychain-db"
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"

TMP_DIR="$(mktemp -d "${CI_TMP_DIR%/}/ios-signing.XXXXXX")"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# GNU base64（Linux）与 BSD base64（macOS）参数不同，这里自动选择。
decode_base64() {
  if base64 --decode </dev/null >/dev/null 2>&1; then
    base64 --decode
  else
    base64 -D
  fi
}

printf '%s' "$IOS_CERTIFICATE_P12_BASE64" | decode_base64 > "$TMP_DIR/distribution.p12"
printf '%s' "$IOS_PROFILES_ZIP_BASE64" | decode_base64 > "$TMP_DIR/profiles.zip"

mkdir -p "$TMP_DIR/profiles"
unzip -q "$TMP_DIR/profiles.zip" -d "$TMP_DIR/profiles"

# ---------------------------------------------------------------- 临时 Keychain
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
# 6 小时自动锁定：足够跑完一次构建，又不会长期驻留。
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

security import "$TMP_DIR/distribution.p12" \
  -k "$KEYCHAIN_PATH" \
  -P "$IOS_CERTIFICATE_PASSWORD" \
  -T /usr/bin/codesign \
  -T /usr/bin/security

# 关键一步：允许 codesign 在无人值守环境下使用私钥（否则会出现 UI 授权弹窗导致 CI 卡住）。
security set-key-partition-list \
  -S apple-tool:,apple: \
  -s \
  -k "$KEYCHAIN_PASSWORD" \
  "$KEYCHAIN_PATH" >/dev/null

# 把临时 Keychain 加入搜索列表，并设为默认。
security list-keychains -d user -s \
  "$KEYCHAIN_PATH" \
  "$(security default-keychain -d user | tr -d '"')"
security default-keychain -d user -s "$KEYCHAIN_PATH"

# ---------------------------------------------------------------- Provisioning Profiles
mkdir -p "$PROFILE_DIR"

found_profile=0
while IFS= read -r -d '' profile; do
  found_profile=1
  # 用 PlistBuddy 从解码后的 plist 读 UUID（比管道更直观，排错更容易）。
  security cms -D -i "$profile" > "$TMP_DIR/profile.plist"
  UUID=$(/usr/libexec/PlistBuddy -c 'Print UUID' "$TMP_DIR/profile.plist")
  cp "$profile" "$PROFILE_DIR/$UUID.mobileprovision"
  echo "已安装 Provisioning Profile：$UUID"
done < <(find "$TMP_DIR/profiles" -name '*.mobileprovision' -print0)

if [ "$found_profile" -ne 1 ]; then
  echo "错误：ZIP 中没有找到任何 .mobileprovision 文件" >&2
  exit 1
fi

# ---------------------------------------------------------------- 前置校验
echo "当前可用签名身份："
security find-identity -v -p codesigning "$KEYCHAIN_PATH"

# 没有可用身份时提前失败，避免构建到 exportArchive 阶段才报 "No signing certificate"。
if ! security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -q "Apple Distribution\|iPhone Distribution"; then
  echo "错误：未找到可用的分发证书（Apple Distribution）。请确认 .p12 中包含证书与私钥。" >&2
  exit 1
fi

echo "iOS 签名材料安装完成。"
