import StoreKit
import Utils

public enum FetchProdcutsError: Error {
    case general
}

public enum PurchaseProductError: Error {
    case general
}

public enum RestorePurchasesRepositoryError: Error {
    case general
    case userCancelation
}

public protocol InAppPurchasesRepository {
    var availableProducts: ProtectedPublisher<[Product]> { get }
    var userProductsIds: ProtectedPublisher<Set<String>> { get }
    func updateUserProducts() -> Completable<Never>
    func fetchAvailableProducts() -> Completable<FetchProdcutsError>
    func purchase(_ product: Product) -> Completable<PurchaseProductError>
    func restorePurchases() -> Completable<RestorePurchasesRepositoryError>
}
