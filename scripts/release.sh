#!/usr/bin/env bash

set -e

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo "Script Path: ${SCRIPT_PATH}"

if [[ -z $LODEPNG_VERSION ]]; then
  echo "LODEPNG_VERSION not set; aborting"
  exit 1
fi

BUILD_DIR="${SCRIPT_PATH}/../build/lodepng-${LODEPNG_VERSION}"
echo "Build Path: ${BUILD_DIR}"

if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "Build dir not found: ${BUILD_DIR}"
  exit 1
fi

pushd "${BUILD_DIR}"

echo "Creating ${BUILD_DIR}/lodepng.tar.gz"
rm -f "lodepng.tar.gz"
tar czf "lodepng.tar.gz" macosx

echo "Creating ${BUILD_DIR}/LodePNG.xcframework.tar.gz"
rm -f "LodePNG.xcframework.tar.gz"
tar czf "LodePNG.xcframework.tar.gz" LodePNG.xcframework

popd