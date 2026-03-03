// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "HTTPClientNIO",
  platforms: [
    .macOS(.v12),
    .iOS(.v15)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "HTTPClientNIO",
      targets: ["HTTPClientNIO"]
    )
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(path: "../HTTPClientCore"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.32.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "HTTPClientNIO",
      dependencies: [
        .product(name: "HTTPClientCore", package: "HTTPClientCore"),
        .product(name: "AsyncHTTPClient", package: "async-http-client")
      ]
    ),
    .testTarget(
      name: "HTTPClientNIOTests",
      dependencies: ["HTTPClientNIO"]
    )
  ]
)
