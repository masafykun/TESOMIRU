import SwiftUI

@main
struct TESOMIRUApp: App {
    @StateObject private var storeManager = StoreManager()
    @StateObject private var readingStore = ReadingStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
                .environmentObject(readingStore)
        }
    }
}
