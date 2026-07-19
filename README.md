# Consumables

一款本地优先的 iOS 家庭消耗品管理 App，用于记录日用品的购买与启用时间，根据手动周期或历史使用间隔预测耗尽日期，并提示近期需要补货的物品。

## 当前能力

- 创建、编辑和归档消耗品
- 记录购买、启用时间、品牌和数量
- 为每个物品设置默认使用周期与提前提醒天数
- 历史不足时使用手动周期，历史充足时按最近三段周期加权预测
- 按紧急程度展示概览、物品列表和详情
- 使用 SwiftData 在设备本地持久化

当前版本尚未包含系统通知、云同步、多人家庭共享、库存数量扣减或账号体系。

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
