import SwiftUI

extension View {
    func errorAlert(_ error: Binding<Error?>) -> some View {
        alert("操作失败", isPresented: Binding(get: { error.wrappedValue != nil }, set: { if !$0 { error.wrappedValue = nil } })) {
            Button("好", role: .cancel) { error.wrappedValue = nil }
        } message: { Text(error.wrappedValue?.localizedDescription ?? "未知错误") }
    }
}
