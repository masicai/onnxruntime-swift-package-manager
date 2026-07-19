# Release Instructions

These are the steps to create a new onnxruntime-swift-package-manager release.
Typically, an onnxruntime-swift-package-manager release will follow soon after an onnxruntime release.

## 1. Sync onnxruntime Objective-C source files

Check out the corresponding onnxruntime release version, i.e., a release tag.
```
cd <onnxruntime repo>
git checkout <release tag, e.g., v1.20.0>
```

Sync the onnxruntime Objective-C source files.
```
# Replace objectivec directory.
rm -r <onnxruntime-swift-package-manager repo>/objectivec
cp -r <onnxruntime repo>/objectivec <onnxruntime-swift-package-manager repo>/objectivec
```


## 2. Update dependency versions in Package.swift

Find the onnxruntime and onnxruntime-extensions binary target configuration in the Package.swift file. For example:

https://github.com/microsoft/onnxruntime-swift-package-manager/blob/bbc428e168a0374eb7d0503cdb7c73fdc1d99751/Package.swift#L98-L104

https://github.com/microsoft/onnxruntime-swift-package-manager/blob/bbc428e168a0374eb7d0503cdb7c73fdc1d99751/Package.swift#L110-L116

```swift
    // ORT release
    package.targets.append(
       Target.binaryTarget(name: "onnxruntime",
                           url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.19.2.zip",
                           //                                                              ^^^^^^ Update version
                           // SHA256 checksum
                           checksum: "28787ee2f966a2c47eb293322c733c5dc4b5e3327cec321c1fe31a7c698edf68")
                           //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Update checksum
    )
```

Update the version in the URL and checksum for both onnxruntime and onnxruntime-extensions targets.
To get the checksum value, download the file from the updated URL and compute its SHA256 checksum.

To compute a SHA256 checksum on Linux or MacOS:
```
sha256sum pod-archive-onnxruntime-c-x.y.z.zip
```

To compute a SHA256 checksum on Windows with Powershell:
```
(Get-FileHash -Algorithm SHA256 pod-archive-onnxruntime-c-x.y.z.zip).Hash.ToLower()
```


## 3. Check in updates and create a release

Note: This repo is updated relatively infrequently, so we currently do not have a release process that uses a separate release branch.

Check in the changes made in the previous steps to the `main` branch.

Create a release tag from the `main` branch.

The tag should match the tag of the corresponding onnxruntime release excluding the leading `v` in order to make it a valid semantic version string.
E.g., for onnxruntime tag `v1.20.0`, the onnxruntime-swift-package-manager tag should be `1.20.0`.


## masicai fork: releasing a repackaged ORT binary

This fork does not point the `onnxruntime` binary target at Microsoft's pod archive. The pod archive wraps static libraries in `.framework` bundles, and Xcode embeds framework-format SPM binary targets into the app bundle with a generated stub dylib, which App Store Connect validation rejects (ITMS-90208/90360/90530; see microsoft/onnxruntime#27396 and masicai/flutter_onnxruntime#71). Instead, the binary target points at a library-format xcframework (plain static libraries + headers) hosted as a GitHub release asset of this repo.

To release, after syncing `objectivec/` as described above:

1. Repackage Microsoft's pod archive:

   ```
   ./scripts/repackage_ort_spm_artifact.sh <ort-version>   # e.g. 1.23.0
   ```

   This downloads `pod-archive-onnxruntime-c-<ort-version>.zip` from Microsoft's CDN, converts it, writes `onnxruntime-libs-<ort-version>.zip`, and prints its SwiftPM checksum.

2. Pick the release tag. Fork tags must not collide with a version Microsoft could plausibly publish binaries for: for a packaging-only respin of ORT `x.y.0`, use the next free patch number (e.g. `1.23.1` for ORT 1.23.0 — upstream's 1.23 line only ever shipped 1.23.0).

3. Update the `onnxruntime` binary target in `Package.swift`: URL `https://github.com/masicai/onnxruntime-swift-package-manager/releases/download/<tag>/onnxruntime-libs-<ort-version>.zip` and the checksum printed in step 1.

4. Merge to `main`, tag the merge commit, then create the GitHub release for that tag and upload the zip.

   **Upload the exact file whose checksum went into `Package.swift`.** Re-running the script produces a byte-different zip (archive timestamps) with a different checksum; if you regenerate, update `Package.swift` before tagging.

5. Verify from a consumer (e.g. flutter_onnxruntime example app): pin the new tag, `flutter clean`, build for iOS, and confirm the app bundle's `Frameworks/` directory contains no `onnxruntime.framework`.
