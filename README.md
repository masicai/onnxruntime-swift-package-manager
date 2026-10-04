# Swift Package Manager for ONNX Runtime

A light-weight repository for providing [Swift Package Manager (SPM)](https://www.swift.org/package-manager/) support for [ONNXRuntime](https://github.com/microsoft/onnxruntime). The ONNX Runtime native package is included as a binary dependency of the SPM package.


SPM is the alternative to CocoaPods when desired platform to consume is mobile iOS.

## masicai fork

This fork serves [flutter_onnxruntime](https://github.com/masicai/flutter_onnxruntime). It pins an ORT release that Microsoft's SPM repo has no tag for, and it ships the ORT binary as a library-format xcframework instead of the framework-format pod archive, which Xcode embeds into the app and App Store Connect then rejects (ITMS-90208, [flutter_onnxruntime#71](https://github.com/masicai/flutter_onnxruntime/issues/71)). The artifact is produced by `scripts/repackage_ort_spm_artifact.sh <ort-version>` and attached to the GitHub release of the tag.

Fork tags do not always match the ORT version they ship. In the case of 1.23.1, we use that version to fix the packaging of ORT 1.23.0:

| Fork tag | ORT version | Release asset |
|---|---|---|
| `1.28.0` | 1.28.0 | `onnxruntime-libs-1.28.0.zip` |
| `1.23.1` | 1.23.0 | `onnxruntime-libs-1.23.0.zip` |
| `1.23.0` | 1.23.0 | Microsoft's framework-format pod archive (affected by ITMS-90208) |

## Note

The `objectivec/` directory is copied from the [ORT repo](https://github.com/microsoft/onnxruntime/tree/main/objectivec) and it's expected to match. It will be updated periodically/before release to merge new changes.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
