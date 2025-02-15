import Utils

struct QuotientNode: ExpressionASTNode {
    let lhs: ExpressionASTNode
    let rhs: ExpressionASTNode
    let label: String = "/"
    var occurringVariables: Set<String> { return lhs.occurringVariables.union(rhs.occurringVariables) }
    var childs: [ExpressionASTNode] { return [lhs, rhs] }

    func evaluate(with feedDict: [String: Double]) throws -> Double {
        let numerator = try lhs.evaluate(with: feedDict)
        let denominator = try rhs.evaluate(with: feedDict)
        guard denominator != 0.0 else { throw ExpressionError.divisionByZero(numerator, denominator) }
        return numerator / denominator
    }
}
