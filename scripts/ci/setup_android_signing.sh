#!/usr/bin/env bash
#
# 在 CI 中恢复 Android 签名材料（keystore + key.properties）。
#
# 为什么抽成脚本（参考文档的收尾建议 #1）：GitHub / GitLab / CircleCI 只需要准备环境变量，
# 复用同一份逻辑；Android 的签名准备不该散落在某个 CI 的 YAML 里。
#
# 必需环境变量：
#   ANDROID_KEYSTORE_BASE64    keystore(.jks) 的 Base64（整串，无换行）
#   ANDROID_KEYSTORE_PASSWORD  keystore 密码
#   ANDROID_KEY_ALIAS          签名别名
#   ANDROID_KEY_PASSWORD       别名对应私钥密码
#
# 用法：bash scripts/ci/setup_android_signing.sh
set -euo pipefail

: "${ANDROID_KEYSTORE_BASE64:?缺少 ANDROID_KEYSTORE_BASE64（keystore 的 Base64）}"
: "${ANDROID_KEYSTORE_PASSWORD:?缺少 ANDROID_KEYSTORE_PASSWORD}"
: "${ANDROID_KEY_ALIAS:?缺少 ANDROID_KEY_ALIAS}"
: "${ANDROID_KEY_PASSWORD:?缺少 ANDROID_KEY_PASSWORD}"

# 项目根目录（脚本位于 <root>/scripts/ci/）。
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEYSTORE_PATH="$PROJECT_ROOT/android/app/upload-keystore.jks"
PROPERTIES_PATH="$PROJECT_ROOT/android/key.properties"

# GNU base64（Linux Runner）与 BSD base64（macOS）参数不同，这里自动选择。
decode_base64() {
  if base64 --decode </dev/null >/dev/null 2>&1; then
    base64 --decode
  else
    base64 -D
  fi
}

printf '%s' "$ANDROID_KEYSTORE_BASE64" | decode_base64 > "$KEYSTORE_PATH"
chmod 600 "$KEYSTORE_PATH"

# key.properties 由 android/app/build.gradle.kts 读取（storeFile 使用相对路径）。
cat > "$PROPERTIES_PATH" <<PROPERTIES
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=upload-keystore.jks
PROPERTIES
chmod 600 "$PROPERTIES_PATH"

echo "Android 签名材料已就绪："
echo "  keystore : $KEYSTORE_PATH"
echo "  properties: $PROPERTIES_PATH"
echo "  alias    : ${ANDROID_KEY_ALIAS}"
