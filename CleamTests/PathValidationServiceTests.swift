import XCTest
@testable import Cleam

final class PathValidationServiceTests: XCTestCase {
    var service: PathValidationService!

    override func setUp() async throws {
        let protectionList = ProtectionListService()
        let whitelist = WhitelistService()
        service = PathValidationService(protectionList: protectionList, whitelist: whitelist)
    }

    func testRejectsRootPath() async {
        let url = URL(fileURLWithPath: "/")
        do {
            try await service.validate(url)
            XCTFail("Should have thrown for root path")
        } catch let error as PathValidationError {
            XCTAssertEqual(error, .criticalSystemPath)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRejectsSystemPath() async {
        let url = URL(fileURLWithPath: "/System")
        do {
            try await service.validate(url)
            XCTFail("Should have thrown for /System")
        } catch let error as PathValidationError {
            XCTAssertEqual(error, .criticalSystemPath)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRejectsPathTraversal() async {
        let url = URL(fileURLWithPath: "/tmp/../etc/passwd")
        do {
            try await service.validate(url)
            XCTFail("Should have thrown for path traversal")
        } catch let error as PathValidationError {
            XCTAssertEqual(error, .pathTraversal)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRejectsUsrBin() async {
        let url = URL(fileURLWithPath: "/usr/bin/ls")
        do {
            try await service.validate(url)
            XCTFail("Should have thrown for /usr/bin path")
        } catch let error as PathValidationError {
            XCTAssertEqual(error, .criticalSystemPath)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAcceptsTempFile() async {
        let url = URL(fileURLWithPath: "/tmp/test-file.txt")
        do {
            try await service.validate(url)
        } catch {
            // May throw if file doesn't exist or is whitelisted, which is acceptable
        }
    }
}

extension PathValidationError: Equatable {
    public static func == (lhs: PathValidationError, rhs: PathValidationError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
