import Foundation
import D2MessageIO
import Graphics
import GIF
import Utils
import Logging

public class PatCommand: Command {
    public let info = CommandInfo(
        category: .fun,
        shortDescription: "Creates a pat animation",
        presented: true,
        requiredPermissionLevel: .basic
    )
    public let inputValueType: RichValueType = .image
    public let outputValueType: RichValueType = .gif

    private let frameCount: Int
    private let delayTime: Int
    private let patOffset: Vec2<Double>
    private let patScale: Double
    private let patPower: Int

    private let inventoryManager: InventoryManager

    public init(
        frameCount: Int = 25,
        delayTime: Int = 3,
        patOffset: Vec2<Double> = .init(x: -10),
        patScale: Double = -10,
        patPower: Int = 2,
        inventoryManager: InventoryManager
    ) {
        self.frameCount = frameCount
        self.delayTime = delayTime
        self.patOffset = patOffset
        self.patScale = patScale
        self.patPower = patPower
        self.inventoryManager = inventoryManager
    }

    public func invoke(with input: RichValue, output: any CommandOutput, context: CommandContext) {
        guard let user = input.asMentions?.first else {
            output.append(errorText: "Please mention someone!")
            return
        }
        guard let author = context.author else {
            output.append(errorText: "No author")
            return
        }
        guard let avatarUrl = context.client?.avatarUrlForUser(user.id, with: user.avatar, size: 128, preferredExtension: "png") else {
            output.append(errorText: "Could not fetch avatar URL")
            return
        }

        context.channel?.triggerTyping()

        Promise(.success(HTTPRequest(url: avatarUrl)))
            .then { $0.runAsync() }
            .listen {
                do {
                    let data = try $0.get()
                    guard !data.isEmpty else {
                        output.append(errorText: "No avatar available")
                        return
                    }

                    let patHand = try Image(fromPngFile: "Resources/fun/patHand.png")
                    let avatarImage = try Image(fromPng: data)
                    let width = avatarImage.width
                    let height = avatarImage.height
                    let radiusSquared = (width * height) / 4
                    var gif = GIF(quantizingImage: avatarImage)

                    // Cut out round avatar
                    for y in 0..<height {
                        for x in 0..<width {
                            let cx = x - (width / 2)
                            let cy = y - (height / 2)
                            if (cx * cx) + (cy * cy) > radiusSquared {
                                avatarImage[y, x] = Colors.transparent
                            }
                        }
                    }

                    // Render the animation
                    for i in 0..<self.frameCount {
                        let frame = try Image(width: width, height: height)
                        let percent = Double(i) / Double(self.frameCount)
                        let graphics = CairoGraphics(fromImage: frame)

                        graphics.draw(avatarImage)
                        graphics.draw(patHand, at: self.patOffset + Vec2(y: self.patScale * (1 - abs(pow(2 * percent - 1, Double(self.patPower))))))

                        gif.frames.append(.init(image: frame, delayTime: self.delayTime))
                    }

                    output.append(.gif(gif))

                    // Place the pat in the recipient's inventory
                    self.inventoryManager[user].append(item: .init(id: "pat-\(author.username)", name: "Pat by \(author.username)"), to: "Pats")
                } catch {
                    output.append(errorText: "The avatar could not be fetched \(error)")
                }
            }
    }
}
