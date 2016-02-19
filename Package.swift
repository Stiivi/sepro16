import PackageDescription

let package = Package(
    targets: [
        Target(name: "SeproLang"),
        Target(name: "sepro",
            dependencies: [.Target(name:"SeproLang")]
        )
    ],
    dependencies: [
        .Package(url: "../ParserCombinator", majorVersion:0),
    ]
)
