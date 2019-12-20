// swift-tools-version:5.1
import PackageDescription

let package = Package(
	name: "key-cast",
	platforms: [
		.macOS(.v10_12)
	],
	dependencies: [
		.package(url: "https://github.com/jakeheis/SwiftCLI", from: "6.0.0")
	],
	targets: [
		.target(
			name: "key-cast",
			dependencies: [
				"SwiftCLI"
			]
		)
	]
)