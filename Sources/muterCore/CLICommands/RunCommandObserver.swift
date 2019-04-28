import Foundation
import Darwin.C

extension Notification.Name {
    static let muterLaunched = Notification.Name("muterLaunched")
    static let projectCopyStarted = Notification.Name("projectCopyStarted")
    static let projectCopyFinished = Notification.Name("projectCopyFinished")
    static let projectCopyFailed = Notification.Name("projectCopyFailed")

    static let workingDirectoryCreated = Notification.Name("workingDirectoryCreated")

    static let sourceFileDiscoveryStarted = Notification.Name("sourceFileDiscoveryStarted")
    static let sourceFileDiscoveryFinished = Notification.Name("sourceFileDiscoveryFinished")

    static let mutationOperatorDiscoveryStarted = Notification.Name("mutationOperatorDiscoveryStarted")
    static let mutationOperatorDiscoveryFinished = Notification.Name("mutationOperatorDiscoveryFinished")
    static let noMutationOperatorsDiscovered = Notification.Name("noMutationOperatorsDiscovered")

    static let mutationTestingStarted = Notification.Name("mutationTestingStarted")
    static let mutationTestingFinished = Notification.Name("mutationTestingFinished")
    static let mutationTestingAborted = Notification.Name("mutationTestingAborted")

    static let newMutationTestOutcomeAvailable = Notification.Name("newMutationTestOutcomeAvailable")

    static let configurationFileCreated = Notification.Name("configurationFileCreated")
}

func flushStdOut() {
    fflush(stdout)
}

class RunCommandObserver {
    private let reporter: Reporter
    private let flushStdOut: () -> Void
    private let notificationCenter: NotificationCenter = .default
    private var notificationHandlerMappings: [(name: Notification.Name, handler: (Notification) -> Void)] {
       return [
            (name: .muterLaunched, handler: handleMuterLaunched),
            
            (name: .projectCopyStarted, handler: handleProjectCopyStarted),
            (name: .projectCopyFinished, handler: handleProjectCopyFinished),
            (name: .projectCopyFailed, handler: handleProjectCopyFailed),
            
            (name: .sourceFileDiscoveryStarted, handler: handleSourceFileDiscoveryStarted),
            (name: .sourceFileDiscoveryFinished, handler: handleSourceFileDiscoveryFinished),
            
            (name: .mutationOperatorDiscoveryStarted, handler: handleMutationOperatorDiscoveryStarted),
            (name: .mutationOperatorDiscoveryFinished, handler: handleMutationOperatorDiscoveryFinished),
            (name: .noMutationOperatorsDiscovered, handler: handleNoMutationOperatorsDiscovered),
            
            (name: .mutationTestingStarted, handler: handleMutationTestingStarted),
            (name: .newMutationTestOutcomeAvailable, handler: handleNewMutationTestOutcomeAvailable),
            (name: .mutationTestingAborted, handler: handleMutationTestingAborted),
            (name: .mutationTestingFinished, handler: handleMutationTestingFinished),
        ]
    }
    
    init(reporter: Reporter, flushHandler: @escaping () -> Void) {
        self.reporter = reporter
        self.flushStdOut = flushHandler
        
        for (name, handler) in notificationHandlerMappings {
            notificationCenter.addObserver(forName: name, object: nil, queue: nil, using: handler)
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
}

extension RunCommandObserver {    
    func handleMuterLaunched(notification: Notification) {
        if reporter != .xcode {
            printHeader()
        }
    }
    
    func handleProjectCopyStarted(notification: Notification) {
        if reporter != .xcode {
            printMessage("Copying your project to a temporary directory for testing")
        }
    }

    func handleProjectCopyFinished(notification: Notification) {
        if reporter != .xcode {
            printMessage("Finished copying your project to a temporary directory for testing")
        }
    }

    func handleProjectCopyFailed(notification: Notification) {
        fatalError("""
            Muter was unable to create a temporary directory,
            or was unable to copy your project, and cannot continue.

            If you can reproduce this, please consider filing a bug
            at https://github.com/SeanROlszewski/muter

            Please include the following in the bug report:
            *********************
            FileManager error: \(String(describing: notification.object))
            """)
    }

    func handleSourceFileDiscoveryStarted(notification: Notification) {
        if reporter != .xcode {
            printMessage("Discovering source code in:\n\n\(notification.object as! String)")
        }
    }

    func handleSourceFileDiscoveryFinished(notification: Notification) {
        if reporter != .xcode {
            let discoveredFilePaths = notification.object as! [String]
            let filePaths = discoveredFilePaths.joined(separator: "\n")
            printMessage("Discovered \(discoveredFilePaths.count) Swift files:\n\n\(filePaths)")
        }
    }

    func handleMutationOperatorDiscoveryStarted(notification: Notification) {
        if reporter != .xcode {
            printMessage("Discovering applicable Mutation Operators in:\n\n\(notification.object as! String)")
        }
    }

    func handleMutationOperatorDiscoveryFinished(notification: Notification) {
        if reporter != .xcode {
            let discoveredMutationOperators = notification.object as! [MutationOperator]

            printMessage("Discovered \(discoveredMutationOperators.count) mutants to introduce:\n")

            for (index, `operator`) in discoveredMutationOperators.enumerated() {
                let listPosition = "\(index+1))"
                let fileName = URL(fileURLWithPath: `operator`.filePath).lastPathComponent
                printMessage("\(listPosition) \(fileName)")
            }
        }
    }

    func handleNoMutationOperatorsDiscovered(notification: Notification) {
        printMessage("""

                    Muter wasn't able to discover any code it could mutation test.

                    This is likely caused by misconfiguring Muter, usually by excluding a directory that contains your code.

                    If you feel this is a bug, or want help figuring out what could be happening, please open an issue at
                    https://github.com/SeanROlszewski/muter/issues

        """)
        exit(1)
    }

    func handleMutationTestingStarted(notification: Notification) {
        if reporter != .xcode {
            printMessage("Mutation testing will now begin.\nRunning your test suite to determine a baseline for mutation testing")
        }
    }

    func handleNewMutationTestOutcomeAvailable(notification: Notification) {
        let values = notification.object as! (outcome: MutationTestOutcome, remainingOperatorsCount: Int)
        
        if reporter == .xcode {
            print(reporter.generateReport(from: [values.outcome]))
            flushStdOut()
        } else {
            let fileName = URL(fileURLWithPath: values.outcome.filePath).lastPathComponent

            printMessage("""
                Testing mutation operator in \(fileName)
                There are \(values.remainingOperatorsCount) left to apply
                """)
        }
    }

    func handleMutationTestingAborted(notification: Notification) {
        printMessage(notification.object as! String)
        exit(1)
    }

    func handleMutationTestingFinished(notification: Notification) {
        if reporter != .xcode { // xcode reports are generated in real-time, so don't report them once mutation testing has finished
            let outcomes = notification.object as! [MutationTestOutcome]
            let result = reporter.generateReport(from: outcomes)
            printMessage(result, true)
        }
    }
}
