import D2MessageIO
import D2Commands

extension Command {
	public func testInvoke(
		with input: RichValue = .none,
		output: any CommandOutput,
		context: CommandContext = CommandContext(client: nil, registry: CommandRegistry(), message: Message(content: ""), commandPrefix: "", subscriptions: SubscriptionSet())
	) {
		invoke(with: input, output: output, context: context)
	}

	public func testSubscriptionMessage(
		with content: String,
		output: any CommandOutput,
		context: CommandContext = CommandContext(client: nil, registry: CommandRegistry(), message: Message(content: ""), commandPrefix: "", subscriptions: SubscriptionSet())
	) {
		onSubscriptionMessage(with: content, output: output, context: context)
	}
}
