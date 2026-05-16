import Foundation
import Combine
import StoreKit

enum StoreError: Error {
    case failedVerification
}

@MainActor
final class StoreManager: ObservableObject {
    static let productIds = [
        "org.masafy.TESOMIRU.premium.monthly",
        "org.masafy.TESOMIRU.premium.yearly",
    ]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var isLoadingProducts: Bool = false

    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let fetched = try await Product.products(for: Self.productIds)
            // 年間→月額の順で並べる（年間がデフォルト推奨）
            products = fetched.sorted { lhs, rhs in
                lhs.price > rhs.price
            }
        } catch {
            print("StoreManager: failed to load products — \(error)")
        }
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshEntitlements()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.productIds.contains(transaction.productID),
               transaction.revocationDate == nil {
                hasActive = true
                break
            }
        }
        isPremium = hasActive
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
