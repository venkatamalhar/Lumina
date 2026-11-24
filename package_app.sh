#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Lumina"
BUILD_DIR="${SCRIPT_DIR}/.build/release"
APP_BUNDLE="${SCRIPT_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME} in release configuration..."
swift build -c release --package-path "${SCRIPT_DIR}"

echo "Creating application bundle at ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${SCRIPT_DIR}/.build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "${SCRIPT_DIR}/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

if [ -f "${SCRIPT_DIR}/Resources/AppIcon.icns" ]; then
    cp "${SCRIPT_DIR}/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

echo "Applying ad-hoc code signature..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Successfully built and packaged ${APP_BUNDLE}"
