# Consumables 目标架构

- 状态：已实施
- 日期：2026-07-19
- 适用基线：iOS 17、SwiftUI、SwiftData、Swift 5.10

## 1. 目标

Consumables 是一款本地优先的个人库存生命周期管理 App。用户按类别组织消耗品，通过模板或手工录入真实库存，并手动标记库存开始使用和用尽。

本架构优先满足以下目标：

- 模型语义清晰，库存、模板和使用记录各自只有一个职责；
- 保持实现精简，不引入当前产品不需要的抽象；
- 所有业务写入经过可测试的统一入口；
- 为后续 schema 迁移、结构化规格和个人 iCloud 同步保留演进空间；
- 不让未来方向增加首版复杂度。

## 2. 已确认的产品边界

首版支持：

- 添加、编辑、归档和删除类别；
- 在类别下添加、编辑和删除库存模板；
- 使用模板预填库存，或完全手工添加库存；
- 一次添加多个相同库存时，生成多个独立库存项；
- 将某项库存标记为使用中；
- 由用户手动标记某项库存已用尽；
- 同一类别允许多项库存同时使用；
- 查看类别下待使用、使用中和已用尽的库存；
- 编辑库存快照和生命周期日期；
- 永久删除错误的库存记录。

首版不支持：

- 耗尽预测、提醒阈值或通知；
- 库存批次和批次内数量拆分；
- 结构化容量、单位换算或单价比较；
- 通用操作日志、审计日志或 undo/redo 历史；
- 账号、家庭共享、CloudKit 或其他同步；
- 照片、条码、商家、存放位置和保质期。

## 3. 核心概念

### 3.1 库存类别 `InventoryCategory`

类别是用户组织模板和库存的主要入口，例如“洗发水”“卷纸”。

建议字段：

```swift
id: UUID
name: String
sortOrder: Int
archivedAt: Date?
createdAt: Date
updatedAt: Date
```

有模板或库存的类别不能永久删除，只能归档。空类别可以永久删除。

### 3.2 库存模板 `InventoryTemplate`

模板只是可复用的表单预设，不是库存项的身份来源。模板属于一个类别，但库存项不保存模板引用。

建议字段：

```swift
id: UUID
category: InventoryCategory
name: String
brand: String?
specificationText: String?
referencePriceAmount: Decimal?
referenceCurrencyCode: String?
note: String?
createdAt: Date
updatedAt: Date
```

用模板添加库存时，模板值会被复制到新库存项。之后编辑或删除模板，不影响任何既有库存。

### 3.3 库存项 `InventoryItem`

库存项表示一件可独立使用的真实物品。一瓶洗发水或一整包卷纸都可以是一项库存；不存在批次实体。

建议字段：

```swift
id: UUID
category: InventoryCategory
name: String
brand: String?
specificationText: String?
actualPriceAmount: Decimal?
actualCurrencyCode: String?
stockedAt: Date
note: String?
usageRecord: UsageRecord?
createdAt: Date
updatedAt: Date
```

库存项保存创建时的独立快照，但允许用户后续编辑纠错。编辑库存不会修改模板或其他库存项。

### 3.4 使用记录 `UsageRecord`

使用记录描述一项库存从开始使用到最终用尽的完整生命周期。每项库存最多有一条使用记录。

建议字段：

```swift
id: UUID
inventoryItem: InventoryItem
startedAt: Date
depletedAt: Date?
createdAt: Date
updatedAt: Date
```

使用记录不重复保存名称、品牌、规格或价格。这些信息来自所关联的库存快照。

## 4. 关系与状态

```text
InventoryCategory
├── InventoryTemplate *
└── InventoryItem *
    └── UsageRecord 0...1
```

库存状态不持久化，由关系和日期派生：

```swift
enum InventoryState: Sendable {
    case stocked
    case inUse
    case depleted
}

func state(usageRecord: UsageRecord?) -> InventoryState {
    guard let usageRecord else { return .stocked }
    return usageRecord.depletedAt == nil ? .inUse : .depleted
}
```

不保存独立的 `status` 字段，避免状态字段与使用记录互相矛盾。

## 5. 价格与规格

价格是金额与 ISO 4217 币种的组合：

```swift
struct Money: Equatable, Sendable {
    let amount: Decimal
    let currencyCode: String
}
```

持久化时将金额和币种拆成可查询字段，不保存为不可查询的 transformable blob。模板保存参考价格，库存项保存本次实际价格。

首版规格使用自由文本，例如：

- `500ml`
- `12 卷`
- `3 × 100 抽`

结构化数量与单位是明确的后续方向。未来 schema 可增加 `amountValue` 和 `unitCode`，同时保留 `specificationText` 用于原样展示和兼容迁移。

## 6. 业务规则

所有规则必须位于纯领域类型或命令服务中，不能散落在 SwiftUI `body` 内。

### 6.1 通用校验

- 名称清理首尾空白后不能为空；
- 可选文本清理后为空则保存为 `nil`；
- 金额不能为负数；
- 有金额时必须有合法币种代码；
- 所有业务实体使用稳定 UUID；
- 业务日期与系统时间戳分开保存。

### 6.2 库存生命周期

- `stockedAt <= startedAt`；
- 存在 `depletedAt` 时，`startedAt <= depletedAt`；
- 每项库存最多创建一条使用记录；
- 同一类别可以有任意多项使用中的库存；
- 开始使用会创建 `UsageRecord`；
- 标记用尽会填写 `depletedAt`；
- 恢复为使用中会清空 `depletedAt`；
- 退回待使用会删除 `UsageRecord`；
- 直接录入正在使用的物品时，在同一事务内创建库存项和使用记录。

### 6.3 模板囤货

- 模板只负责预填表单；
- 库存项不保存 `templateID`；
- 名称、品牌、规格和参考价格复制后成为库存快照；
- 用户可以为本次库存调整实际价格、入库日期和备注；
- 一次添加 `count` 件时，在一个事务内创建 `count` 个独立库存项；
- 每项库存的价格表示该物品自身价格，不表示整次购买总价。

### 6.4 删除与归档

- 有内容的类别只能归档，可恢复；
- 空类别可以永久删除；
- 模板可以永久删除，不影响库存；
- 库存项可以永久删除；
- 删除库存项时，在同一事务内级联删除使用记录；
- 已用尽库存默认保留在历史中，只有用户明确删除时才移除。

## 7. 应用架构

采用“功能切片 + 共享领域规则 + SwiftData 持久化”的结构：

```text
Consumables/
├── App/
│   ├── ConsumablesApp.swift
│   ├── AppBootstrap.swift
│   └── RootView.swift
├── Domain/
│   ├── InventoryState.swift
│   ├── InventoryRules.swift
│   ├── Money.swift
│   └── ValidationError.swift
├── Persistence/
│   ├── Schema/
│   │   └── V1/
│   │       ├── InventoryCategory.swift
│   │       ├── InventoryTemplate.swift
│   │       ├── InventoryItem.swift
│   │       ├── UsageRecord.swift
│   │       └── ConsumablesSchemaV1.swift
│   ├── ConsumablesMigrationPlan.swift
│   └── InventoryCommands.swift
├── Features/
│   ├── Categories/
│   ├── CategoryDetail/
│   ├── Templates/
│   ├── InventoryEditor/
│   ├── Usage/
│   └── History/
├── Shared/
│   ├── Components/
│   └── Formatting/
└── PreviewSupport/
```

继续保持一个 App target 和一个测试 target。当前规模不拆独立 Swift Package，不引入第三方运行时依赖。

### 7.1 数据读取

- 功能入口视图使用 `@Query` 获取 SwiftData 数据；
- 查询尽量在持久化层过滤归档状态和类别范围；
- 纯展示组件接收已经准备好的数据，不自行查询；
- 不为简单展示视图机械创建 ViewModel。

### 7.2 表单状态

编辑器使用独立 Draft，不直接绑定 SwiftData 实体：

```text
@Query → Feature View → Editor Draft → InventoryCommands → ModelContext
```

建议 Draft：

- `CategoryDraft`
- `TemplateDraft`
- `InventoryDraft`
- `UsageDraft`

用户点击保存后才把 Draft 提交给命令服务，取消时直接丢弃 Draft，避免 SwiftData autosave 写入半成品。

### 7.3 数据写入

使用一个具体的 `@MainActor InventoryCommands` 作为全部业务写入入口，不创建没有替代实现的 Repository 协议。

建议命令：

```swift
createCategory
updateCategory
archiveCategory
restoreCategory
deleteEmptyCategory

createTemplate
updateTemplate
deleteTemplate

stockManually
stockFromTemplate
updateInventoryItem
deleteInventoryItem

startUsing
markDepleted
reopen
returnToStock
```

SwiftUI 不直接修改持久化字段。多对象操作在完成所有校验后统一保存；任何一步失败都不能留下部分结果。

## 8. 信息架构

首版使用单一 `NavigationStack`，不保留预测总览、物品和设置三 Tab：

```text
类别列表
└── 类别详情
    ├── 使用中
    ├── 待使用
    ├── 添加库存
    │   ├── 从模板添加
    │   └── 手工添加
    ├── 模板管理
    └── 历史记录
        └── 已用尽
```

类别列表展示每个类别的待使用、使用中和已用尽数量。类别详情默认只展示待使用和使用中；已用尽库存进入独立历史区域。

首版不需要设置页。价格录入默认使用系统地区币种，但每项价格仍保存明确的 ISO 币种。

## 9. SwiftData 策略

- 从新模型的第一版开始使用 `VersionedSchema`；
- 提供 `SchemaMigrationPlan`，即使 V1 暂时没有迁移阶段；
- 不迁移旧的预测模型数据；
- 使用新的本地 store 名称，让旧开发数据保持未使用状态，而不是在启动时自动删除数据库；
- 生产启动不写入示例数据；
- 示例数据只用于 Preview 和测试内存容器；
- 存储初始化失败时展示可恢复错误界面，不直接 `fatalError`，也不自动删除数据；
- 用户可见名称的唯一性由业务校验处理，不把名称当作实体身份；
- 保留稳定 UUID、`createdAt` 和 `updatedAt`，为未来同步和合并提供基础。

Apple 官方资料：

- [Preserving your app's model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches)
- [Adding and editing persistent data in your app](https://developer.apple.com/documentation/swiftdata/adding-and-editing-persistent-data-in-your-app)
- [VersionedSchema](https://developer.apple.com/documentation/swiftdata/versionedschema)
- [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)

## 10. 测试策略

### 10.1 纯领域测试

- 三种库存状态派生；
- 金额与币种校验；
- 文本标准化；
- 日期顺序校验；
- 状态回退规则。

### 10.2 SwiftData 内存集成测试

- 手工添加库存不依赖模板；
- 模板复制后与库存完全独立；
- 批量添加生成多个独立库存项；
- 同一库存不能拥有第二条使用记录；
- 同一类别允许多项同时使用；
- 直接创建使用中库存保持事务原子性；
- 删除库存级联删除使用记录；
- 非空类别不能永久删除；
- 归档和恢复类别；
- 写入失败不会留下部分数据。

### 10.3 UI 与 Preview 验证

至少覆盖：

- 空类别列表；
- 空类别详情；
- 同时存在待使用和多项使用中库存；
- 长名称、长品牌和长规格；
- 多币种价格；
- 已用尽历史；
- 已归档类别；
- 删除确认和保存失败。

## 11. 当前代码处置

实施新架构时：

- 删除全部预测、紧急程度、剩余百分比和提醒代码；
- 删除预测测试和预测专用 UI 组件；
- 用四个新实体替换 `ConsumableItem` 和 `PurchaseRecord`；
- 用 `InventoryCommands` 替换当前 mutation service；
- 拆分当前大型 Item Editor 和补货表单；
- 用类别优先的导航替换现有三 Tab；
- 删除当前预测设置页；
- 删除生产环境自动 seed；
- 保留 XcodeGen、CI、内存 Preview 容器和集中写入服务的思路。

## 12. 后续方向

### 12.1 结构化规格

这是明确方向，但不进入首版。立项时通过新 schema 增加数值、单位代码和换算规则，并保留原规格文本。

### 12.2 个人 iCloud 同步

当前只实现本地 SwiftData。未来确认个人 iCloud 同步后，再增加：

- CloudKit entitlement 与容器配置；
- schema 兼容性审核；
- 冲突解决规则；
- 删除传播和合并策略；
- 必要时的同步专用持久化接口。

当前不为尚未实施的同步引入账号、Repository 或网络层。

### 12.3 Swift 并发

保持 Swift 5.10 语言模式，先开启完整严格并发检查作为 warning。所有 UI 和主 `ModelContext` 写入保持主 actor 隔离；只有出现真实的大批量后台处理需求时才引入 `ModelActor`。

参考：[Swift 6 migration guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/enabledataracesafety/)

## 13. 架构原则摘要

1. 库存项是真实物品，模板只是预设。
2. 使用记录只描述库存生命周期，不复制产品信息。
3. 状态由事实派生，不重复持久化。
4. 业务规则不进入 View body。
5. 所有用户写入经过统一命令服务。
6. 不为不存在的后端创建 Repository。
7. 不为未来功能提前增加空字段和抽象。
8. 从 V1 开始版本化 schema。
9. 生产数据永不因初始化或验证被自动清除。
10. 架构复杂度必须由当前产品行为证明。
