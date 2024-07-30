# Sourcery Plugin

The Sourcery Plugin is a Swift Package Manager plugin for using [`sourcery`](https://github.com/krzysztofzablocki/Sourcery). The official repository supports "command" type plugins, but not "build tool" type plugins. Therefore, we have implemented our own version that uses a binary to maintain low build times.

## Usage

### Package.swift

You can reference this plugin in your target:

```swift
dependencies: [
    .package(path: "../SourceryPlugin")
],
targets: [

    .target(name: "YourTarget"),
    .testTarget(
        name: "YourTargetTests",
        dependencies: ["YourTarget"]
    ),

    .target(
        name: "YourTargetSupport",
        dependencies: ["YourTarget"],
        plugins: [
            .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
        ]
    )
]
```

### Configuration

A configuration file named `sourcery.yml` is expected in one of the following locations:
1. The root of the package.
2. The target directory.
3. A subfolder named 'Sourcery' within the target directory.

### Environment

The plugin's environment provides three paths that can be used in the configuration:
1. `DERIVED_SOURCES_DIR`: The working directory in the sandbox that contains the results.
2. `PACKAGE_ROOT_DIR`: The package root directory.
3. `TARGET_DIR`: The target directory.


## Future ideas:
- Create a shared GitHub repository for `SourceryPlugin` instead of this local implementation.
- Implement `XcodePluginContext` to run the plugin as a "Run Build Tool Plug-ins" in other targets that are not Swift Packages, like WireDataModel.
- Share the `AutoMockable.stencil` file between all targets or deliver defaults from the plugin. Apple's documentation suggests that processing resources like assets might become easier in the future.
- Consider adding generated files to the Git repository instead of relying on implicit generation, especially on CI. This is currently challenging due to sandboxing requirements.
