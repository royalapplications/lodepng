#!/usr/bin/env bash

set -e

IOS_VERSION_MIN="13.4"
MACOS_VERSION_MIN="11.0"
CODESIGN_ID="-"

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo "Script Path: ${SCRIPT_PATH}"

BUILD_ROOT_DIR="${SCRIPT_PATH}/../build"
echo "Build Path: ${BUILD_ROOT_DIR}"
mkdir -p "${BUILD_ROOT_DIR}"

pushd "${SCRIPT_PATH}/.."
LODEPNG_VERSION=`git rev-parse HEAD:Submodules/lodepng`
popd

if [[ -z $LODEPNG_VERSION ]]; then
  echo "LODEPNG_VERSION not set; aborting"
  exit 1
fi

echo "lodepng Version (Commit Hash): ${LODEPNG_VERSION}"

SRC_DIR="${SCRIPT_PATH}/../Submodules/lodepng"
BUILD_DIR="${BUILD_ROOT_DIR}/lodepng-build-${LODEPNG_VERSION}"

if [[ -d "${BUILD_DIR}" ]]; then
  rm -r "${BUILD_DIR}"
fi

mkdir -p "${BUILD_DIR}"

BUILD_DIR_MACOS="${BUILD_DIR}/macosx"
BUILD_DIR_IOS="${BUILD_DIR}/iphoneos"
BUILD_DIR_IOS_SIM="${BUILD_DIR}/iphonesimulator"

if [[ ! -d "${BUILD_DIR_MACOS}" ]]; then
  mkdir -p "${BUILD_DIR_MACOS}"
fi

if [[ ! -d "${BUILD_DIR_IOS}" ]]; then
  mkdir -p "${BUILD_DIR_IOS}"
fi

if [[ ! -d "${BUILD_DIR_IOS_SIM}" ]]; then
  mkdir -p "${BUILD_DIR_IOS_SIM}"
fi

if [[ ! -d "${BUILD_DIR_MACOS}_temp" ]]; then
  mkdir -p "${BUILD_DIR_MACOS}_temp"
fi

if [[ ! -d "${BUILD_DIR_IOS}_temp" ]]; then
  mkdir -p "${BUILD_DIR_IOS}_temp"
fi

if [[ ! -d "${BUILD_DIR_IOS_SIM}_temp" ]]; then
  mkdir -p "${BUILD_DIR_IOS_SIM}_temp"
fi

copy_output() {
  local target_dir="$1"

  mkdir "${target_dir}/lib"
  cp "liblodepng.a" "${target_dir}/lib"

  mkdir "${target_dir}/include"
  mkdir "${target_dir}/include/lodepng"
  cp "${SRC_DIR}/lodepng.h" "${target_dir}/include/lodepng"
}

build_macos() {
  echo "Building for macOS Universal"

  pushd "${BUILD_DIR_MACOS}_temp"

  local sdk_root=$(xcrun --sdk macosx --show-sdk-path)
  local additional_c_flags="-mmacosx-version-min=${MACOS_VERSION_MIN}"

  local object_file_name="liblodepng.o"
  local library_file_name="liblodepng.a"

  clang -c "${SRC_DIR}/lodepng.cpp" \
    -o "arm64_${object_file_name}" \
    -DNDEBUG \
    -O3 \
    -arch arm64 \
    -isysroot "${sdk_root}" \
    "${additional_c_flags}"

  ar rcs \
    "arm64_${library_file_name}" \
    "arm64_${object_file_name}"

  strip -x "arm64_${library_file_name}"

  clang -c "${SRC_DIR}/lodepng.cpp" \
    -o "x86_64_${object_file_name}" \
    -DNDEBUG \
    -O3 \
    -arch x86_64 \
    -isysroot "${sdk_root}" \
    "${additional_c_flags}"

  ar rcs \
    "x86_64_${library_file_name}" \
    "x86_64_${object_file_name}"

  strip -x "x86_64_${library_file_name}"

  lipo -create \
    -output "${library_file_name}" \
    "x86_64_${library_file_name}" \
    "arm64_${library_file_name}"

  lipo -info "${library_file_name}"

  copy_output "${BUILD_DIR_MACOS}"

  popd
}

build_ios() {
  echo "Building for iOS ARM64"

  pushd "${BUILD_DIR_IOS}_temp"

  local sdk_root=$(xcrun --sdk iphoneos --show-sdk-path)
  local additional_c_flags="-mios-version-min=${IOS_VERSION_MIN}"

  local object_file_name="liblodepng.o"
  local library_file_name="liblodepng.a"

  clang -c "${SRC_DIR}/lodepng.cpp" \
    -o "${object_file_name}" \
    -DNDEBUG \
    -O3 \
    -arch arm64 \
    -isysroot "${sdk_root}" \
    "${additional_c_flags}"

  ar rcs \
    "${library_file_name}" \
    "${object_file_name}"

  strip -x "${library_file_name}"

  lipo -info "${library_file_name}"

  copy_output "${BUILD_DIR_IOS}"

  popd
}

build_ios_sim() {
  echo "Building for iOS Simulator"

  pushd "${BUILD_DIR_IOS_SIM}_temp"

  local sdk_root=$(xcrun --sdk iphonesimulator --show-sdk-path)
  local additional_c_flags="-mios-simulator-version-min=${IOS_VERSION_MIN}"

  local object_file_name="liblodepng.o"
  local library_file_name="liblodepng.a"

  clang -c "${SRC_DIR}/lodepng.cpp" \
    -o "arm64_${object_file_name}" \
    -DNDEBUG \
    -O3 \
    -arch arm64 \
    -isysroot "${sdk_root}" \
    "${additional_c_flags}"

  ar rcs \
    "arm64_${library_file_name}" \
    "arm64_${object_file_name}"

  strip -x "arm64_${library_file_name}"

  clang -c "${SRC_DIR}/lodepng.cpp" \
    -o "x86_64_${object_file_name}" \
    -DNDEBUG \
    -O3 \
    -arch x86_64 \
    -isysroot "${sdk_root}" \
    "${additional_c_flags}"

  ar rcs \
    "x86_64_${library_file_name}" \
    "x86_64_${object_file_name}"

  strip -x "x86_64_${library_file_name}"

  lipo -create \
    -output "${library_file_name}" \
    "x86_64_${library_file_name}" \
    "arm64_${library_file_name}"

  lipo -info "${library_file_name}"

  copy_output "${BUILD_DIR_IOS_SIM}"

  popd
}

build_macos
build_ios
build_ios_sim

if [[ ! -d "${BUILD_DIR}/LodePNG.xcframework" ]]; then
  xcodebuild -create-xcframework \
    -library "${BUILD_DIR_MACOS}/lib/liblodepng.a" \
    -library "${BUILD_DIR_IOS}/lib/liblodepng.a" \
    -library "${BUILD_DIR_IOS_SIM}/lib/liblodepng.a" \
    -output "${BUILD_DIR}/LodePNG.xcframework"

  codesign \
    --force --deep --strict \
    --sign "${CODESIGN_ID}" \
    "${BUILD_DIR}/LodePNG.xcframework"
fi