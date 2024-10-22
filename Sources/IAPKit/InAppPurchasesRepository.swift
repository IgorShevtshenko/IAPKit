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

@MainActor
public protocol InAppPurchasesRepository {
    var availableProducts: ProtectedPublisher<[Product]> { get }
    var userProductsIds: ProtectedPublisher<Set<String>> { get }
    func updateUserProducts() async
    func fetchAvailableProducts() async throws(FetchProdcutsError)
    func purchase(_ product: Product) async throws(PurchaseProductError)
    func restorePurchases() async throws(RestorePurchasesRepositoryError)
}

