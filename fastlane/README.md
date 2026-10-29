fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android qa

```sh
[bundle exec] fastlane android qa
```

构建 Android Release APK，并在配置齐全时分发到 Firebase App Distribution

----


## iOS

### ios qa

```sh
[bundle exec] fastlane ios qa
```

构建 iOS Ad Hoc IPA，并在配置齐全时分发到 Firebase App Distribution

### ios beta

```sh
[bundle exec] fastlane ios beta
```

构建 App Store 包并上传 TestFlight（证书与 ASC Key 就绪后可用）

### ios testflight_check

```sh
[bundle exec] fastlane ios testflight_check
```

只检查 TestFlight 前置条件（不构建、不上传）

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
