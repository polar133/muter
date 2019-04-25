import Foundation
import Rainbow

func printHeader() {
   
    print(
        """
        
        \("""
         _____       _
        |     | _ _ | |_  ___  ___
        | | | || | ||  _|| -_||  _|
        |_|_|_||___||_|  |___||_|
        """.green)
        
        Automated mutation testing for Swift
        
        You are running version \("\(version)".bold)
        
        Want help?
        https://github.com/SeanROlszewski/muter/issues
        +----------------------------------------------+
        
        """)
}

func printMessage(_ message: String) {
    print("+-------------------+")
    print(message)
    print("")
}

func writeToFile(str: String) {

    guard let data = FileManager.default.contents(atPath: FileManager.default.currentDirectoryPath+"/muter.conf.json"),
        let configuration = try? JSONDecoder().decode(MuterConfiguration.self, from: data),
        configuration.outputFile != nil,
        !configuration.outputFile!.isEmpty else {
            print("Error writing file")
            return
    }

    let pathDirectory = getDocumentsDirectory()
    try? FileManager().createDirectory(at: pathDirectory, withIntermediateDirectories: true)
    let filePath = pathDirectory.appendingPathComponent(configuration.outputFile!)

    do {
        try str.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
    } catch {
        print("Failed to write data: \(error.localizedDescription)")
    }
}

private func getDocumentsDirectory() -> URL {
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}
