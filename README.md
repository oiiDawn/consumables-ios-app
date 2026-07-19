# Consumables

一款本地优先的 iOS 个人库存生命周期管理 App。用户按类别组织消耗品，通过模板或手工录入库存，并手动标记开始使用和用尽。

## 当前能力

- 创建、编辑、归档和恢复类别
- 管理用于快速录入的库存模板
- 从模板或手工添加独立库存项
- 管理待使用、使用中和已用尽的生命周期
- 查看按类别组织的当前库存与历史
- 使用 SwiftData 在设备本地持久化

当前版本不包含耗尽预测、通知、云同步、多人共享或账号体系。完整设计见 [`docs/architecture.md`](docs/architecture.md)。

## 技术栈

- SwiftUI
- SwiftData
- iOS 17+
- Swift 5.10
- XcodeGen
- XCTest

## 开始开发

需要 Xcode 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。XcodeGen 版本固定在 `.xcodegen-version`，项目结构以 `project.yml` 为准。

```sh
xcodegen generate
open Consumables.xcodeproj
```

查看可用的 Simulator：

```sh
xcodebuild -showdestinations \
  -project Consumables.xcodeproj \
  -scheme Consumables
```

运行测试（Simulator 名称可按本机环境调整）：

```sh
xcodebuild test \
  -project Consumables.xcodeproj \
  -scheme Consumables \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/DerivedData
```

协作约定和仓库结构见 `AGENTS.md`。

## 持续集成

GitHub Actions 会在 pull request 以及推送到 `main` 时执行：

1. 重新生成 Xcode 工程并检查是否存在未提交的工程漂移；
2. 为 iOS Simulator 构建测试产物；
3. 运行 XCTest 单元测试。

CI 不执行代码签名、归档、发布或 TestFlight 上传。
CI 会下载 `.xcodegen-version` 指定的官方 XcodeGen release，并在执行前校验下载文件的 SHA-256。
