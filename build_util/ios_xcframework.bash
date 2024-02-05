#!/usr/bin/env bash
set -eu

echo "* Get original onnxruntime file name from rpath"
output=$(otool -L "artifact/voicevox_core-aarch64-apple-ios/libvoicevox_core.dylib")
matched_line=$(echo "$output" | grep "@rpath" | grep "libonnxruntime")
if [[ $matched_line ]]; then
    if [[ $matched_line =~ (@rpath/([^ ]+\.dylib)) ]]; then
        dylib_string=${BASH_REMATCH[2]}
    else
        echo "Expected pattern not found in the matched line"
        echo "$output"
        exit 1
    fi
else
    echo "No line containing '@rpath' and 'libonnxruntime' found"
    echo "$output"
    exit 1
fi
echo "Original onnx dylib file name: $dylib_string"

arches=("aarch64" "sim")
for arch in "${!arches[@]}"; do
    echo "* copy Framework-${arch} template"
    mkdir -p "Framework-${arch}/voicevox_core.framework/Headers"
    cp -vr "crates/voicevox_core_c_api/xcframework/Frameworks/${arch}/" "Framework-${framework}/"
    cp -v "artifact/voicevox_core-aarch64-apple-ios/voicevox_core.h" \
        "Framework-${arch}/voicevox_core.framework/Headers/voicevox_core.h"
done

echo "* Create dylib"
# aarch64のdylibはコピー
cp -v "artifact/voicevox_core-aarch64-apple-ios/libvoicevox_core.dylib" \
    "Framework-aarch64/voicevox_core.framework/voicevox_core"

# sim(x86_64 + arrch64)のdylibは作成
lipo -create "artifact/voicevox_core-x86_64-apple-ios/libvoicevox_core.dylib" \
    "artifact/voicevox_core-aarch64-apple-ios-sim/libvoicevox_core.dylib" \
    -output "Framework-sim/voicevox_core.framework/voicevox_core"

for arch in "${arches[@]}"; do
    echo "* Change ${arch} @rpath"
    # 自身への@rpathを変更
    install_name_tool -id "@rpath/voicevox_core.framework/voicevox_core" \
        "Framework-${arch}/voicevox_core.framework/voicevox_core"

    # 依存ライブラリの@rpathを変更
    # $dylib_string に具体的な値を設定する必要があるかもしれません
    install_name_tool -change "@rpath/$dylib_string" \
        "@rpath/onnxruntime.framework/onnxruntime" \
        "Framework-${arch}/voicevox_core.framework/voicevox_core"
done


echo "* Create XCFramework"
mkdir -p "artifact/${ASSET_NAME}"
xcodebuild -create-xcframework \
    -framework "Framework-sim/voicevox_core.framework" \
    -framework "Framework-aarch64/voicevox_core.framework" \
    -output "artifact/${ASSET_NAME}/voicevox_core.xcframework"
