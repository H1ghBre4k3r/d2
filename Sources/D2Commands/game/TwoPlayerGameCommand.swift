import SwiftDiscord
import D2Permissions
import D2Utils

fileprivate let actionMessageRegex = try! Regex(from: "^(\\S+)(?:\\s+(.+))?")

/**
 * Provides a base layer of functionality for a turn-based 
 * two-player game.
 */
public class TwoPlayerGameCommand<G: Game>: StringCommand {
	public let requiredPermissionLevel = PermissionLevel.basic
	public let subscribesToNextMessages = true
	
	private let game: G
	private var currentState: G.State? = nil
	private let defaultActions: [String: (G.State, String) throws -> ActionResult<G.State>] = [
		"cancel": { state, _ in ActionResult(cancelsMatch: true, onlyCurrentPlayer: false) }
	]
	
	public var description: String { return "Plays \(game.name) against someone" }
	
	public init() {
		game = G.init()
	}
	
	public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
		guard currentState == nil else {
			output.append("Wait for the current match to finish before creating a new one.")
			return
		}
		
		guard let opponent = context.message.mentions.first else {
			output.append("Mention an opponent to play against.")
			return
		}
		
		startMatch(between: GamePlayer(from: context.author), and: GamePlayer(from: opponent), output: output)
	}
	
	private func sendHandsAsDMs(fromState state: G.State, to output: CommandOutput) {
		if game.onlySendHandToCurrentRole, let player = state.playerOf(role: state.currentRole) {
			if let hand = state.hands[state.currentRole] {
				output.append(hand.discordMessageEncoded, to: .userChannel(player.id))
			}
		} else {
			for (role, hand) in state.hands {
				if let player = state.playerOf(role: role) {
					output.append(hand.discordMessageEncoded, to: .userChannel(player.id))
				}
			}
		}
	}
	
	func startMatch(between firstPlayer: GamePlayer, and secondPlayer: GamePlayer, output: CommandOutput) {
		let state = G.State.init(firstPlayer: firstPlayer, secondPlayer: secondPlayer)
		
		currentState = state
		
		if game.renderFirstBoard {
			output.append(state.board.discordMessageEncoded)
		}
		
		output.append("Playing new match: \(state.playersDescription)\nAvailable game actions: `\(game.actions.keys)`\nAvailable default actions: `\(defaultActions.keys)`\nType `[action] [...]` to begin!")
		sendHandsAsDMs(fromState: state, to: output)
	}
	
	public func onSubscriptionMessage(withContent content: String, output: CommandOutput, context: CommandContext) -> CommandSubscriptionAction {
		let author = GamePlayer(from: context.author)
		
		if let actionArgs = actionMessageRegex.firstGroups(in: content) {
			return perform(actionArgs[1], withArgs: actionArgs[2], output: output, author: author)
		} else {
			return .continueSubscription
		}
	}
	
	/** Performs a game action if present, otherwise does nothing. */
	@discardableResult
	func perform(_ actionKey: String, withArgs args: String, output: CommandOutput, author: GamePlayer) -> CommandSubscriptionAction {
		guard let state = currentState else { return .continueSubscription }
		guard let action = game.actions[actionKey] ?? defaultActions[actionKey] else { return .continueSubscription }
		
		do {
			let actionResult = try action(state, args)
			
			if actionResult.onlyCurrentPlayer {
				guard state.rolesOf(player: author).contains(state.currentRole) else {
					output.append("It is not your turn, `\(author.username)`")
					return .continueSubscription
				}
			}
			
			if actionResult.cancelsMatch {
				currentState = nil
				output.append("Cancelled match: \(state.playersDescription)")
				return .cancelSubscription
			}
			
			if let next = actionResult.nextState {
				// Output next board and user's hands
				output.append(next.board.discordMessageEncoded)
				output.append("\(actionResult.text ?? "")\nIt is now `\(next.playerOf(role: next.currentRole).map { $0.username } ?? "?")`'s turn")
				
				// print("Next possible moves: \(next.possibleMoves)")
				sendHandsAsDMs(fromState: next, to: output)
				
				if let winner = next.winner {
					// Game won
					
					var embed = DiscordEmbed()
					embed.title = ":crown: Winner"
					embed.description = "\(winner.discordStringEncoded)\(state.playerOf(role: winner).map { " aka. `\($0.username)`" } ?? "") won the game!"
					
					output.append(embed)
					currentState = nil
					return .cancelSubscription
				} else if next.isDraw {
					// Game over due to a draw
					
					var embed = DiscordEmbed()
					embed.title = ":crown: Game Over"
					embed.description = "The game resulted in a draw!"
					
					output.append(embed)
					currentState = nil
					return .cancelSubscription
				} else {
					// Advance the game
					
					currentState = next
				}
			} else if let text = actionResult.text {
				output.append(text)
			}
		} catch GameError.invalidMove(let msg) {
			output.append("Invalid move by \(state.currentRole.discordStringEncoded): \(msg)")
		} catch {
			output.append("Error while attempting move")
			print(error)
		}
		
		return .continueSubscription
	}
}
