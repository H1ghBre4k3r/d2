import Sword

class CampusCommand: Command {
	let description = "Locates rooms on the CAU campus"
	let requiredPermissionLevel = PermissionLevel.basic
	
	func invoke(withMessage message: Message, args: String) {
		// message.channel.send([
		// 	DiscordMessageKey.file: MapQuestStaticMap(
		// 		latitude: 0,
		// 		longitude: 0
		// 	).url
		// ])
	}
}
