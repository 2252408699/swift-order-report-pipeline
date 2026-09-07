// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OrderReportPipeline",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "order-report-pipeline", targets: ["OrderReportPipeline"])
    ],
    targets: [
        .executableTarget(name: "OrderReportPipeline")
    ]
)

