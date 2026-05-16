import SwiftUI

@main
struct TESOMIRUApp: App {
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
        }
    }
}
