import PackageDescription

let package = Package(
    targets: [
        Target(name: "Utility"),
        Target(name: "Model",
			dependencies: [.Target(name:"Utility")]
		),
        Target(name: "Parser",
			dependencies: [.Target(name:"Model")]
		),
        Target(name: "Sepro",
			dependencies: [.Target(name:"Parser")]
		),
        Target(name: "sepro-tool",
            dependencies: [.Target(name:"Sepro")]
        )
    ],
    dependencies: [
        .Package(url: "../ParserCombinator", majorVersion:0)
    ]
)


