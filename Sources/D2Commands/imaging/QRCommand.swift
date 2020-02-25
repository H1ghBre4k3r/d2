import SwiftDiscord
import D2Graphics
import D2Utils
import QRCodeGenerator

public class QRCommand: StringCommand {
    public let info = CommandInfo(
        category: .imaging,
        shortDescription: "Generates a QR code",
        longDescription: "Generates a QR code from given text",
        requiredPermissionLevel: .basic
    )
    
    public init() {}
    
    public func invoke(withStringInput input: String, output: CommandOutput, context: CommandContext) {
        do {
            let qr = try QRCode.encode(text: input, ecl: .medium)
            let scale = 4
            let width = qr.size * scale
            let height = qr.size * scale
            let image = try Image(width: width, height: height)
            var graphics = CairoGraphics(fromImage: image)
            
            for y in 0..<qr.size {
                for x in 0..<qr.size {
                    let module = qr.getModule(x: x, y: y)
                    let color = module ? Colors.white : Colors.transparent
                    graphics.draw(Rectangle(fromX: Double(x * scale), y: Double(y * scale), width: Double(scale), height: Double(scale), color: color, isFilled: true))
                }
            }

            try output.append(image)
        } catch {
            output.append(error, errorText: "An error occurred while converting the QR code SVG to an image")
        }
    }
}
