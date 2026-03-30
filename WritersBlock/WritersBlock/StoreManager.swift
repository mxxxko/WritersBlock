import StoreKit
import Observation
import Combine

@Observable @MainActor
final class StoreManager {
    private(set) var isUnlocked = false
    private(set) var product: Product? = nil
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    private(set) var isLoadingProduct = true
    private(set) var purchaseError: String? = nil

    private let productID = "com.mwapps.WritersBlock.unlimitedMode"
    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = Task { await listenForTransactions() }
        Task { await loadProductAndCheckEntitlement() }
    }

    func purchase() async {
        guard !isPurchasing else { return }
        guard let product else {
            purchaseError = "Unlimited Mode is temporarily unavailable. Please check your connection and try again."
            return
        }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseError = "Your purchase could not be verified. Please contact support if this persists."
                    return
                }
                await transaction.finish()
                isUnlocked = true
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Your purchase is awaiting approval. It will be unlocked once approved."
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Something went wrong. Please try again."
        }
    }

    func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await checkEntitlement()
            if !isUnlocked {
                purchaseError = "No previous purchase found for this Apple ID."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func loadProductAndCheckEntitlement() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {}
        isLoadingProduct = false
        await checkEntitlement()
    }

    private func checkEntitlement() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                found = true
                break
            }
        }
        isUnlocked = found
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                if transaction.productID == productID { await checkEntitlement() }
            }
        }
    }
}
