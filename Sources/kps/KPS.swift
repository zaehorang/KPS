import ArgumentParser

@main
struct KPS: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kps",
        abstract: "Korean Problem Solving - 알고리즘 문제 풀이 추적 CLI",
        version: "0.1.0",
        subcommands: [
            InitCommand.self,
            NewCommand.self,
            ConfigCommand.self,
            SolveCommand.self,
            OpenCommand.self
        ]
    )
}
