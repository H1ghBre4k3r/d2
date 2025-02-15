public class IOPlatformCommand: VoidCommand {
    public let info = CommandInfo(
        category: .meta,
        shortDescription: "Outputs the IO platform",
        presented: true,
        requiredPermissionLevel: .basic
    )

    public init() {}

    public func invoke(output: any CommandOutput, context: CommandContext) {
        output.append("You are talking with me via `\(context.client?.name ?? "?")`.")
    }
}
