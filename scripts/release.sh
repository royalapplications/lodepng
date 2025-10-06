#!/usr/bin/env bash

set -e

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo "Script Path: ${SCRIPT_PATH}"

pushd "${SCRIPT_PATH}/.."
LODEPNG_VERSION=`git rev-parse HEAD:Submodules/lodepng`
popd

if [[ -z $LODEPNG_VERSION ]]; then
  echo "LODEPNG_VERSION not set; aborting"
  exit 1
fi

LODEPNG_VERSION="${LODEPNG_VERSION::7}"

echo "lodepng Version (Commit Hash): ${LODEPNG_VERSION}"

BUILD_DIR="${SCRIPT_PATH}/../build/lodepng-build-${LODEPNG_VERSION}"
echo "Build Path: ${BUILD_DIR}"

if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "Build dir not found: ${BUILD_DIR}"
  exit 1
fi

pushd "${BUILD_DIR}"

echo "Creating ${BUILD_DIR}/lodepng.tar.gz"
rm -f "lodepng.tar.gz"
tar czf "lodepng.tar.gz" iphoneos iphonesimulator macosx

echo "Creating ${BUILD_DIR}/LodePNG.xcframework.tar.gz"
rm -f "LodePNG.xcframework.tar.gz"
tar czf "LodePNG.xcframework.tar.gz" LodePNG.xcframework

popd