import Utils

struct FloorNode: ExpressionASTNode {
    let value: ExpressionASTNode
    let label: String = "floor"
    var occurringVariables: Set<String> { return value.occurringVariables }
    var childs: [ExpressionASTNode] { return [value] }

    func evaluate(with feedDict: [String: Double]) throws -> Double {
        return try value.evaluate(with: feedDict).rounded(.down)
    }
}
