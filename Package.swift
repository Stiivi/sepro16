import PackageDescription

let package = Package(
    name: "Sepro",
    targets: [
        Target(name: "Base"),
        Target(name: "Model",
			dependencies: [.Target(name:"Base")]
		),
        Target(name: "Constraints",
			dependencies: [.Target(name:"Model")]
		),
        Target(name: "Language",
			dependencies: [.Target(name:"Model")]
		),
        Target(name: "Engine",
			dependencies: [.Target(name:"Language")]
		),
        Target(name: "sepro-tool",
            dependencies: [.Target(name:"Engine")]
        )
    ],
    dependencies: [
        .Package(url: "../ParserCombinator", majorVersion:0)
    ]
)
