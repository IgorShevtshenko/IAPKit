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
    func updateUserProducts() async
    func fetchAvailableProducts() async -> CompletableResult<FetchProdcutsError>
    func purchase(_ product: Product) async -> CompletableResult<PurchaseProductError>
    func restorePurchases() async  -> CompletableResult<RestorePurchasesRepositoryError>
}

