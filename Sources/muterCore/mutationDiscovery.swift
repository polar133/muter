import SwiftSyntax
import Foundation

func discoverMutationOperators(inFilesAt filePaths: [String]) -> [MutationOperator] {
    return filePaths.accumulate(into: []) { alreadyDiscoveredOperators, path in

        guard pathContainsDotSwift(path),
            let source = sourceCode(fromFileAt: path) else {
                return alreadyDiscoveredOperators
        }

        return alreadyDiscoveredOperators + newlyDiscoveredOperators(inFileAt: path, containing: source).sorted(by: filePositionOrder)
    }
}

private func newlyDiscoveredOperators(inFileAt path: String, containing source: SourceFileSyntax) -> [MutationOperator] {
    return MutationOperator.Id.allCases.accumulate(into: []) { newOperators, mutationOperatorId in

        let visitor = mutationOperatorId.rewriterVisitorPair.visitor()
        visitor.visit(source)

        return newOperators + visitor.positionsOfToken.map { position in

            return MutationOperator(id: mutationOperatorId,
                                    filePath: path,
                                    position: position,
                                    source: source,
                                    transformation: mutationOperatorId.transformation(for: position))

        }
    }
}

private func filePositionOrder(lhs: MutationOperator, rhs: MutationOperator) -> Bool {
    return lhs.position.line < rhs.position.line && lhs.position.column < rhs.position.column
}

private func pathContainsDotSwift(_ filePath: String) -> Bool {
    let url = URL(fileURLWithPath: filePath)
    return url.lastPathComponent.contains(".swift")
}
