import Combine
import Utils
import StoreKit
import IAPKit

public final class InAppPurchasesRepositoryImpl: InAppPurchasesRepository {

    public var availableProducts: ProtectedPublisher<[Product]> {
        _availableProducts.eraseToAnyPublisher()
    }

    public var userProductsIds: ProtectedPublisher<Set<String>> {
        _userProductsIds.eraseToAnyPublisher()
    }

    private let _userProductsIds = CurrentValueSubject<Set<String>, Never>([])
    private let _availableProducts = CurrentValueSubject<[Product], Never>([])

    private var updates: Task<Void, Never>? = nil

    private let productIds: [String]

    public init(productIds: [String]) {
        self.productIds = productIds
        updates = observeTransactionUpdates()
    }

    deinit {
        updates?.cancel()
    }

    public func fetchAvailableProducts() async throws(FetchProdcutsError) {
        do {
            let products = try await Product.products(for: productIds)
            _availableProducts.send(products)
        } catch {
            throw .general
        }
    }

    public func updateUserProducts() async {
        var purchasedProductsIds = _userProductsIds.value
        for await result in Transaction.currentEntitlements {
            updateProductIds(productIds: &purchasedProductsIds, with: result)
        }
        _userProductsIds.send(purchasedProductsIds)
    }

    public func purchase(_ product: Product) async throws(PurchaseProductError) {
        do {
            let result = try await product.purchase()
            switch result {
            case let .success(.verified(transaction)):
                await transaction.finish()
                await updateUserProducts()
            case .success, .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            throw .general
        }
    }

    public func restorePurchases() async throws(RestorePurchasesRepositoryError) {
        do {
            try await AppStore.sync()
        } catch {
            switch error {
            case StoreKitError.userCancelled:
                throw .userCancelation
            default:
                throw .general
            }
        }
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task {
            var purchasedProductIDs = _userProductsIds.value
            for await result in Transaction.updates {
                updateProductIds(productIds: &purchasedProductIDs, with: result)
                updateProductIds(with: purchasedProductIDs)
            }
        }
    }
    
    private func updateProductIds(
        productIds: inout Set<String>,
        with result: VerificationResult<Transaction>
    ) {
        guard case .verified(let transaction) = result else {
            return
        }
        if transaction.revocationDate == nil {
            productIds.insert(transaction.productID)
        } else {
            productIds.remove(transaction.productID)
        }
    }

    private func updateProductIds(with purchasedProductIDs: Set<String>) {
        _userProductsIds.send(purchasedProductIDs)
    }
}
