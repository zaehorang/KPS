// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser

@main
struct KPS: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Korean Problem Solving CLI Tool",
        subcommands: [Init.self, New.self, Solve.self, ConfigCommand.self]
    )
}
