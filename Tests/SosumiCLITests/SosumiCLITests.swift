import XCTest
@testable import SosumiCLI

final class SosumiCLITests: XCTestCase {

    func testCLIVersion() throws {
        // Test that the CLI can report its version
        let result = try shell("sosumi --version")
        XCTAssertTrue(result.contains("sosumi"))
        XCTAssertTrue(result.contains("version"))
    }

    func testCLIHelp() throws {
        // Test that the CLI shows help
        let result = try shell("sosumi --help")
        XCTAssertTrue(result.contains("Usage:"))
        XCTAssertTrue(result.contains("Options:"))
    }

    func testSearchCommand() throws {
        // Test basic search command structure
        let result = try shell("sosumi search --help")
        XCTAssertTrue(result.contains("search"))
    }

    func testPerformanceCommand() throws {
        // Test performance command exists
        let result = try shell("sosumi performance --help")
        XCTAssertTrue(result.contains("performance"))
    }

    private func shell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", command]
        task.standardOutput = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}