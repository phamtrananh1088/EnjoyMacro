import SwiftCompilerPlugin
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}
@available(iOS 15, *)
@available(macOS 12, *)
public struct DateBuildedMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        let date = ISO8601DateFormatter().string(from: .now)

        return "\"\(raw: date)\""
    }
}

public struct RecordChangeMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        return [DeclSyntax("mutating func recordChange() {"),
                DeclSyntax("    sync = SyncStatus.changed.rawValue"),
                DeclSyntax("}")]
    }
}

public struct SyncMacro:  MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        return [DeclSyntax("var sync: Int = SyncStatus.pending.rawValue")]
    }
}

public struct TableNameMacro:  MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard case .argumentList(let args) = node.arguments,
        let argument = args.first?.expression else {
            fatalError("Missing argument for parameter of tableNameMacro")
        }
        return [DeclSyntax("static let tableName: String = \(argument)")]
    }
}

public struct CreateTableMacro: MemberMacro {
    
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard case .argumentList(let args) = node.arguments,
        let argument = args.first?.expression.as(StringLiteralExprSyntax.self) else {
            fatalError("Missing argument for parameter of createTableMacro")
        }
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            fatalError("createTableMacro: invalidSyntax")
        }
        var properties: [(name: String, type: String)] = []
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                       let type = binding.typeAnnotation?.type.description {
                        properties.append((name: identifier.identifier.text, type: map(type)))
                    }
                }
            }
        }

        var ds = [DeclSyntax("static func createTable() -> String {"),
                  DeclSyntax("  return \"\"\""),
                  DeclSyntax("  CREATE TABLE IF NOT EXISTS \(raw: argument.representedLiteralValue!)(")
        ]
        for property in properties {
            ds.append(DeclSyntax("  \(raw: property.name) \(raw: property.type),"))
        }
        if case .argumentList(let args) = node.arguments,
           args.count > 1 {
            var arguments: [StringLiteralExprSyntax?] = []
            for argument in args {
                arguments.append(argument.expression.as(StringLiteralExprSyntax.self))
            }
            ds.append(DeclSyntax("  PRIMARY KEY (\(raw: arguments[1]!.representedLiteralValue!))"))
        }
        ds.append(DeclSyntax("  );"))
        ds.append(DeclSyntax("  \"\"\""))
        ds.append(DeclSyntax("}"))
        return ds
    }
    static func map(_ argument: String) -> String {
        switch argument {
        case "String":
            return "TEXT"
        case "Int", "Bool":
            return "INTERGER"
        case "Double", "Float":
            return "REAL"
        case "Date":
            return "TEXT"
        case "Data":
            return "BLOB"
        default:
            return "TEXT"
        }
    }
}

public struct CombineFutureMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let f = declaration.as(FunctionDeclSyntax.self) else {
            fatalError("this macro apply only on func")
        }
        var fu: [String] = [
        ]
        let throwsSpec = f.signature.effectSpecifiers?.throwsSpecifier?.text

        for p in f.signature.parameterClause.parameters {
            fu.append("\(p.firstName): \(p.firstName)")
        }
        return [
"""
func \(f.name)Future\(f.signature.parameterClause)-> Future<\(raw: f.signature.returnClause?.type.description.trimmingCharacters(in: CharacterSet(charactersIn: " ")) ?? "Void"), Error> {
    return Future { promise in
        Task {\(raw: throwsSpec == nil ? "" : """
            try {
""")
            let data = \(raw: throwsSpec == nil ? " " : "try ")self.\(f.name)(\(raw: fu.joined(separator: ",")))
            promise(.success(data))\(raw: throwsSpec == nil ? "" : """
            } catch {
                promise(.failure(error))
            }
""")
        }
    }
}
"""
        ]
    }
}

@available(iOS 15, *)
@available(macOS 12, *)
@main
struct EnjoyMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        DateBuildedMacro.self,
        RecordChangeMacro.self,
        SyncMacro.self,
        TableNameMacro.self,
        CreateTableMacro.self,
        CombineFutureMacro.self
    ]
}
