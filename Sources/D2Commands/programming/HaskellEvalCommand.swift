import Logging
import D2MessageIO
import Utils

fileprivate let log = Logger(label: "D2Commands.HaskellEvalCommand")

public class HaskellEvalCommand: StringCommand {
    public let info = CommandInfo(
        category: .programming,
        shortDescription: "Evaluates a Haskell expression",
        longDescription: "Computes the result of a (pure) Haskell expression using Mueval",
        presented: true,
        requiredPermissionLevel: .basic
    )
    public let outputValueType: RichValueType = .code
    private let timeout: Int = 4

    public init() {}

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        do {
            let value = try Shell().utf8Sync(for: "mueval", args: ["-e", input, "-t", String(timeout)]) ?? "No output"
            output.append(.code(value, language: "haskell"))
        } catch {
            output.append(error, errorText: "Could not evaluate expression.")
        }
    }
}
