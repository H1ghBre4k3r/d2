import Foundation
import D2NetAPIs
import D2MessageIO
import Utils
import Graphics
import SwiftPlot
import AGGRenderer

public class StockCommand: StringCommand {
    public let info = CommandInfo(
        category: .finance,
        shortDescription: "Plots the price of a stock",
        requiredPermissionLevel: .basic
    )

    public init() {}

    public func invoke(with input: String, output: any CommandOutput, context: CommandContext) {
        guard !input.isEmpty else {
            output.append(errorText: "Please mention a stock name!")
            return
        }

        let name = input.uppercased()
        let days = 30
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"

        YahooFinanceQuery(stock: name, from: start, to: end).perform().listen {
            do {
                let values = try $0.get()
                guard !values.isEmpty else {
                    output.append(errorText: "No values found!")
                    return
                }

                let image = try self.presentStock(name: name, values: values)
                let rising = values.first.flatMap { f in values.last.map { l in f.close <= l.close } } ?? true
                let emoji = rising ? ":chart_with_upwards_trend:" : ":chart_with_downwards_trend:"

                output.append(.compound([
                    .image(image),
                    .embed(Embed(
                        title: "\(emoji) \(name) over the last \(days) \("day".pluralized(with: days)) (\(formatter.string(from: start)) - \(formatter.string(from: end)))",
                        url: URL(string: "https://de.finance.yahoo.com/quote/\(name)/history"),
                        fields: [
                            values.first.map { self.presentDay(label: "\(days) \("day".pluralized(with: days)) ago", value: $0) },
                            values[safely: values.count - 2].map { self.presentDay(label: "Yesterday", value: $0) },
                            values.last.map { self.presentDay(label: "Today", value: $0) },
                        ].compactMap { $0 }
                    ))
                ]))
            } catch {
                output.append(error, errorText: "Could not query/present stock")
            }
        }
    }

    private func presentDay(label: String, value: YahooFinanceStockDataPoint) -> Embed.Field {
        Embed.Field(
            name: "\(label)",
            value: """
                High: \(format(price: value.high))
                Low: \(format(price: value.low))
                Volume: \(value.volume)
                """,
            inline: true
        )
    }

    private func format(price: Double) -> String {
        String(format: "USD %.2f", price)
    }

    private func presentStock(name: String, values: [YahooFinanceStockDataPoint]) throws -> Image {
        var graph = LineGraph<Double, Double>(enablePrimaryAxisGrid: true)
        graph.addSeries(
            (0..<values.count).map(Double.init),
            values.map(\.close),
            label: name
        )
        graph.plotLineThickness = 3
        return try render(plot: graph)
    }

    private func render<P>(plot: P) throws -> Image where P: Plot {
        let renderer = AGGRenderer()
        plot.drawGraph(renderer: renderer)

        guard let pngData = Data(base64Encoded: renderer.base64Png()) else {
            throw AdventOfCodeError.noPlotImageData
        }

        return try Image(fromPng: pngData)
    }
}
