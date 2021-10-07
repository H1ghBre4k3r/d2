import D2MessageIO
import D2Commands

public struct SubscriptionInteractionHandler: InteractionHandler {
    public let commandPrefix: String
    private let registry: CommandRegistry
    private let manager: SubscriptionManager

    public init(commandPrefix: String, registry: CommandRegistry, manager: SubscriptionManager) {
        self.commandPrefix = commandPrefix
        self.registry = registry
        self.manager = manager
    }

    public func handle(interaction: Interaction, client: MessageClient) -> Bool {
        guard
            interaction.type == .messageComponent,
            let customId = interaction.customId,
            let channelId = interaction.channelId,
            let member = interaction.member else { return false }
        // TODO: Query the actual message here
        let message = Message(content: "Dummy", channelId: channelId, id: MessageID("", clientName: client.name))
        let user = member.user
        manager.notifySubscriptions(on: channelId, isBot: user.bot) {
            let context = CommandContext(
                client: client,
                registry: registry,
                message: message,
                commandPrefix: commandPrefix,
                subscriptions: $1
            )
            registry[$0]?.onSubscriptionInteraction(with: customId, by: user, output: MessageIOOutput(context: context), context: context)
        }
        return true
    }
}
