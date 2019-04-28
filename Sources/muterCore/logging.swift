import Foundation
import Rainbow
import Files

var path: Folder = Folder.current

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
    path = Folder.current
}

func printMessage(_ message: String, _ toOutputFile: Bool = false) {
    print(message)
    print("")
    if toOutputFile == true {
        writeToFile(str: message)
    }

}

func writeToFile(str: String) {

    guard let data = FileManager.default.contents(atPath: FileManager.default.currentDirectoryPath+"/muter.conf.json"),
        let configuration = try? JSONDecoder().decode(MuterConfiguration.self, from: data),
        configuration.outputFile != nil,
        !configuration.outputFile!.isEmpty else {
            print("no output file")
            return
    }
    do {
        let folder = path

        let outputFolder = try folder.createSubfolderIfNeeded(withName: "output")
        let file = try outputFolder.createFileIfNeeded(withName: configuration.outputFile!)
        if configuration.outputFile!.contains(".json") {
            let jsonData = str.data(using: .utf8)
            let pathAsURL = URL(fileURLWithPath: file.path)
            try jsonData!.write(to: pathAsURL)
        } else {
            try file.write(string: str)
        }
    } catch {
        print("Failed to write data: \(error.localizedDescription)")
        return
    }
}

