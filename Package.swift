// swift-tools-version: 5.9

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//
// A user of the Swift Package Manager (SPM) package will consume this file directly from the ORT SPM github repository.
// For example, the end user's config will look something like:
//
//     dependencies: [
//       .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager", from: "1.16.0"), 
//       ...
//     ],
//
// NOTE: For valid version numbers, please refer to this page:
// https://github.com/microsoft/onnxruntime-swift-package-manager/releases

import PackageDescription
import class Foundation.ProcessInfo

let package = Package(
    name: "onnxruntime",
    platforms: [.iOS(.v15),
                .macOS(.v14)],
    products: [
        .library(name: "onnxruntime",
                 type: .static,
                 targets: ["OnnxRuntimeBindings"]),
        // masicai fork: the "onnxruntime_extensions" product was removed in fork tag
        // 1.28.1. Its binary target pointed at Microsoft's download.onnxruntime.ai,
        // which has served a wrong TLS certificate and 404s since 2026-11-20. SwiftPM
        // downloads every binary target of a package, used or not, so that dead URL
        // broke clean resolves for consumers of the "onnxruntime" product too
        // (https://github.com/masicai/flutter_onnxruntime/issues/83).
        // flutter_onnxruntime never used the extensions product.
    ],
    dependencies: [],
    targets: [
        .target(name: "OnnxRuntimeBindings",
                dependencies: ["onnxruntime"],
                path: "objectivec",
                exclude: ["ReadMe.md", "format_objc.sh", "test", "docs",
                            "ort_checkpoint.mm",
                            "ort_checkpoint_internal.h",
                            "ort_training_session_internal.h",
                            "ort_training_session.mm",
                            "include/ort_checkpoint.h",
                            "include/ort_training_session.h",
                            "include/onnxruntime_training.h"],
                cxxSettings: [
                    .define("SPM_BUILD"),
                ]),
        .testTarget(name: "OnnxRuntimeBindingsTests",
                    dependencies: ["OnnxRuntimeBindings"],
                    path: "swift/OnnxRuntimeBindingsTests",
                    resources: [
                        .copy("Resources/single_add.basic.ort")
                    ]),
    ],
    cxxLanguageStandard: .cxx17
)

// Add the ORT CocoaPods C/C++ pod archive as a binary target.
//
// There are 2 scenarios:
// - Target will be set to a released pod archive and its checksum.
//
// - Target will be set to a local pod archive.
//   This can be used to test with the latest (not yet released) ORT Objective-C source code.

// CI or local testing where you have built/obtained the pod archive matching the current source code.
// Requires the ORT_POD_LOCAL_PATH environment variable to be set to specify the location of the pod.
if let pod_archive_path = ProcessInfo.processInfo.environment["ORT_POD_LOCAL_PATH"] {
    // ORT_POD_LOCAL_PATH MUST be a path that is relative to Package.swift.
    //
    // To build locally, tools/ci_build/github/apple/build_and_assemble_apple_pods.py can be used
    // See https://onnxruntime.ai/docs/build/custom.html#ios
    //  Example command:
    //    python3 tools/ci_build/github/apple/build_and_assemble_apple_pods.py \
    //      --build-settings-file tools/ci_build/github/apple/default_full_apple_framework_build_settings.json
    //
    // This should produce the pod archive in build/apple_pod_staging, and ORT_POD_LOCAL_PATH can be set to
    // "build/apple_pod_staging/pod-archive-onnxruntime-c-???.zip" where '???' is replaced by the version info in the
    // actual filename.
    package.targets.append(Target.binaryTarget(name: "onnxruntime", path: pod_archive_path))

} else {
    // ORT release
    //
    // masicai fork: pinned to ORT 1.28.0, the first release with the KleidiAI
    // conv/IGEMM memory fix (https://github.com/microsoft/onnxruntime/pull/28571)
    // for the 1.24.x regression on SME-capable ARM64 devices
    // (https://github.com/microsoft/onnxruntime/issues/29538). Kept below 1.29,
    // which turns on telemetry by default. The objectivec/ bindings source in this
    // repo is byte-identical between the upstream v1.23.0, v1.24.2 and v1.28.0
    // tags, so only this binary pin changes.
    //
    // The artifact is a LIBRARY-format xcframework (static libraries + headers)
    // repackaged from Microsoft's official pod-archive-onnxruntime-c-1.28.0.zip by
    // scripts/repackage_ort_spm_artifact.sh. The pod archive wraps its static
    // libraries in .framework bundles, and Xcode embeds framework-format binary
    // targets into the app bundle with a generated stub dylib, which App Store
    // Connect validation rejects (ITMS-90208/90360/90530; see
    // https://github.com/microsoft/onnxruntime/issues/27396 and
    // https://github.com/masicai/flutter_onnxruntime/issues/71). Library-format
    // targets are link-only, so nothing gets embedded.
    //
    // Fork tag 1.28.1 only drops the extensions product (see above). It ships the
    // same ORT 1.28.0 binary, so it keeps pointing at the asset of the 1.28.0 release.
    package.targets.append(
       Target.binaryTarget(name: "onnxruntime",
                           url: "https://github.com/masicai/onnxruntime-swift-package-manager/releases/download/1.28.0/onnxruntime-libs-1.28.0.zip",
                           // SwiftPM (SHA256) checksum of the release asset; recompute with
                           // `swift package compute-checksum <zip>` if the asset is regenerated.
                           checksum: "7e031979787f2da0f3ff45d18431db93c4443033020b210413b287a855870c3c")
    )
}
