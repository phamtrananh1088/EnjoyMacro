// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "EnjoyMacroMacros", type: "StringifyMacro")

@available(macOS 12,*)
@freestanding(expression)
public macro dateBuilded() -> String = #externalMacro(module: "EnjoyMacroMacros", type: "DateBuildedMacro")

@attached(member, names: named(recordChange))
public macro recordChange() = #externalMacro(module: "EnjoyMacroMacros", type: "RecordChangeMacro")

@attached(member, names: named(sync))
public macro sync() = #externalMacro(module: "EnjoyMacroMacros", type: "SyncMacro")

@attached(member, names: named(tableName))
public macro tableName(_ argument: String) = #externalMacro(module: "EnjoyMacroMacros", type: "TableNameMacro")

@attached(member, names: named(createTable))
public macro createTable(_ tableName: String, _ primaryKey: String?) = #externalMacro(module: "EnjoyMacroMacros", type: "CreateTableMacro")

@attached(peer, names: arbitrary)
public macro combineFuture() = #externalMacro(module: "EnjoyMacroMacros", type: "CombineFutureMacro")
