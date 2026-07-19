import SwiftData
import SwiftUI

@main
struct ConsumablesApp: App {
    private let containerResult: Result<ModelContainer, Error>
    init() { containerResult = Result { try AppBootstrap.makeModelContainer() } }
    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case let .success(container): RootView().modelContainer(container)
            case let .failure(error):
                ContentUnavailableView("无法打开本地数据", systemImage: "externaldrive.badge.exclamationmark", description: Text("数据没有被删除。请重新启动 App；若问题持续存在，请保留此设备上的数据并联系支持。\n\n\(error.localizedDescription)"))
            }
        }
    }
}
