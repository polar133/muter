public struct MuterConfiguration: Equatable, Codable {
    let testCommandArguments: [String]
    let testCommandExecutable: String
    let excludeList: [String]
    let includeList: [String]

    enum CodingKeys: String, CodingKey {
        case testCommandArguments = "arguments"
        case testCommandExecutable = "executable"
        case excludeList = "exclude"
        case includeList = "include"
    }

    public init(executable: String, arguments: [String], excludeList: [String], includeList: [String] = []) {
        self.testCommandExecutable = executable
        self.testCommandArguments = arguments
        self.excludeList = excludeList
        self.includeList = includeList
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        testCommandExecutable = try container.decode(String.self, forKey: .testCommandExecutable)
        testCommandArguments = try container.decode([String].self, forKey: .testCommandArguments)

        let excludeList = try? container.decode([String].self, forKey: .excludeList)
        self.excludeList = excludeList ?? []

        let includeList = try? container.decode([String].self, forKey: .includeList)
        self.includeList = includeList ?? []
    }
}
