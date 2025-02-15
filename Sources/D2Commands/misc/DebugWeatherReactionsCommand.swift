import D2NetAPIs
import Logging

fileprivate let log = Logger(label: "D2Commands.DebugWeatherReactionsCommand")

public class DebugWeatherReactionsCommand: StringCommand {
    public let info = CommandInfo(
        category: .misc,
        shortDescription: "Reacts with a bunch of weather emojis for testing",
        requiredPermissionLevel: .vip
    )

    public init() {}

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        guard let client = context.client else {
            output.append(errorText: "No client available")
            return
        }
        guard let messageId = context.message.id else {
            output.append(errorText: "No message id available")
            return
        }
        guard let channelId = context.channel?.id else {
            output.append(errorText: "No channel id available")
            return
        }

        let weathers = [
            (main: "clear", description: ""),
            (main: "clouds", description: ""),
            (main: "clouds", description: "few"),
            (main: "clouds", description: "scattered"),
            (main: "clouds", description: "broken"),
            (main: "thunderstorm", description: ""),
            (main: "thunderstorm", description: "rain"),
            (main: "thunderstorm", description: "drizzle"),
            (main: "drizzle", description: ""),
            (main: "rain", description: ""),
            (main: "snow", description: ""),
            (main: "tornado", description: ""),
            (main: "mist", description: ""),
        ]

        for weather in weathers {
            if let emoji = OpenWeatherMapWeather.Weather.emojiFor(main: weather.main, description: weather.description) {
                client.createReaction(for: messageId, on: channelId, emoji: emoji)
            } else {
                log.warning("Weather \(weather) has no emoji representation")
            }
        }
    }
}
