#!/usr/bin/env bash
# Repackage Microsoft's ORT CocoaPods pod archive (framework-format xcframework,
# static ar archives inside .framework bundles) into a LIBRARY-format xcframework
# (plain static libraries + headers).
#
# Why: SwiftPM/Xcode embeds framework-format binary targets into the app bundle
# even when the binary is a static archive. Xcode materializes a stub dylib
# (linked at the app's deployment target) next to the framework's original
# Info.plist (MinimumOSVersion of the ORT build, e.g. 15.1). App Store Connect
# validation rejects the mismatch with ITMS-90208 (and 90360/90530 on older ORT
# versions whose plist lacked MinimumOSVersion entirely).
# A library-format xcframework has no bundle, so Xcode embeds nothing and the
# entire class of validation errors disappears. Linking is unchanged (static).
#
# Usage: ./repackage_ort_spm_artifact.sh <ort-version>   e.g. 1.23.0
set -euo pipefail

VERSION="${1:?usage: $0 <ort-version>}"
WORK="$(mktemp -d)"
OUT="$PWD/onnxruntime-libs-${VERSION}.zip"
trap 'rm -rf "$WORK"' EXIT

echo "Downloading pod archive for ${VERSION}..."
curl -fsSL -o "$WORK/pod.zip" "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-${VERSION}.zip"
unzip -q "$WORK/pod.zip" -d "$WORK/pod"

SRC="$WORK/pod/onnxruntime.xcframework"
mkdir -p "$WORK/headers/onnxruntime"
# Headers are identical across slices; take the device slice's set. The
# `onnxruntime/` subdirectory preserves the SPM_BUILD include prefix
# (#include "onnxruntime/onnxruntime_c_api.h") used by the ObjC bindings.
cp "$SRC/ios-arm64/onnxruntime.framework/Headers/"*.h "$WORK/headers/onnxruntime/"

cp "$SRC/ios-arm64/onnxruntime.framework/onnxruntime"                        "$WORK/libonnxruntime-ios.a"
cp "$SRC/ios-arm64_x86_64-simulator/onnxruntime.framework/onnxruntime"       "$WORK/libonnxruntime-sim.a"
cp "$SRC/macos-arm64_x86_64/onnxruntime.framework/Versions/A/onnxruntime"    "$WORK/libonnxruntime-macos.a"

xcodebuild -create-xcframework \
  -library "$WORK/libonnxruntime-ios.a"   -headers "$WORK/headers" \
  -library "$WORK/libonnxruntime-sim.a"   -headers "$WORK/headers" \
  -library "$WORK/libonnxruntime-macos.a" -headers "$WORK/headers" \
  -output "$WORK/out/onnxruntime.xcframework"

cp "$WORK/pod/LICENSE" "$WORK/out/LICENSE"
(cd "$WORK/out" && zip -q -r -X "$OUT" onnxruntime.xcframework LICENSE)

echo "Wrote $OUT"
echo "SwiftPM checksum:"
swift package compute-checksum "$OUT"
