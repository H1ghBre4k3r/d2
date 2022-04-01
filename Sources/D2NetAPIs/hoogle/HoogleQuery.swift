import Utils

public struct HoogleQuery {
    private let term: String
    private let count: Int

    public init(term: String, count: Int = 4) {
        self.term = term
        self.count = count
    }

    public func perform() -> Promise<[HoogleResult], any Error> {
        Promise.catching { try HTTPRequest(host: "hoogle.haskell.org", path: "/", query: [
            "mode": "json",
            "hoogle": term,
            "start": "1",
            "count": "\(count)"
        ]) }
            .then { $0.fetchJSONAsync(as: [HoogleResult].self) }
    }
}
