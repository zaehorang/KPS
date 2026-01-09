/// Configuration keys for KPS project settings
enum ConfigKey: String, CaseIterable {
    case author
    case sourceFolder
    case projectName

    var description: String {
        switch self {
        case .author:
            return "Author name for file headers"
        case .sourceFolder:
            return "Source folder path (e.g., 'Sources')"
        case .projectName:
            return "Project name"
        }
    }
}
