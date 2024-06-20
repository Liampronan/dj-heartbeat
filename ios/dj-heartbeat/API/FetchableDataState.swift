import Foundation

enum FetchableDataState<T> {
//    case unfetched // for now, we are using `loading` are both loading and unfetched.
    case loading
    case fetched(T)
    case error
}

extension FetchableDataState: Equatable where T: Equatable {
    static func == (lhs: FetchableDataState, rhs: FetchableDataState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.error, .error):
            return true
        case (.fetched(let leftValue), .fetched(let rightValue)):
            return leftValue == rightValue
        default:
            return false
        }
    }
}
