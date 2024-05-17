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
    
    public func fetchAvailableProducts() -> Completable<FetchProdcutsError> {
        Future(
            asyncFunc: { [productIds] in
                try await Product.products(for: productIds)
            }
        )
        .mapError { _ in .general }
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveOutput: _availableProducts.send)
        .ignoreOutput()
        .eraseToAnyPublisher()
    }
    
    public func updateUserProducts() -> Completable<Never> {
        Future(
            asyncFunc: { [weak self] in
                await self?.updateUserProducts()
            }
        )
        .ignoreOutput()
        .ignoreFailure()
        .eraseToAnyPublisher()
    }
    
    public func purchase(_ product: Product) -> Completable<PurchaseProductError> {
        Future(
            asyncFunc: { [weak self] in
                let result = try await product.purchase()
                switch result {
                case let .success(.verified(transaction)):
                    await transaction.finish()
                    await self?.updateUserProducts()
                case .success, .pending, .userCancelled:
                    break
                @unknown default:
                    break
                }
            }
        )
        .ignoreOutput()
        .mapError { _ in .general }
        .eraseToAnyPublisher()
    }
    
    public func restorePurchases() -> Completable<RestorePurchasesRepositoryError> {
        Future(
            asyncFunc: {
                try await AppStore.sync()
            }
        )
        .mapError { error in
            switch error {
            case StoreKitError.userCancelled:
                .userCancelation
            default:
                .general
            }
        }
        .ignoreOutput()
        .eraseToAnyPublisher()
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self, _userProductsIds] in
            var purchasedProductIDs = _userProductsIds.value
            for await result in Transaction.updates {
                self?.updateProductIds(productIds: &purchasedProductIDs, with: result)
                await self?.updateProductIds(with: purchasedProductIDs)
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
    
    @MainActor
    private func updateProductIds(with purchasedProductIDs: Set<String>) {
        _userProductsIds.send(purchasedProductIDs)
    }
    
    @MainActor
    private func updateUserProducts() async {
        var purchasedProductsIds = _userProductsIds.value
        for await result in Transaction.currentEntitlements {
            updateProductIds(productIds: &purchasedProductsIds, with: result)
        }
        _userProductsIds.send(purchasedProductsIds)
    }
}
