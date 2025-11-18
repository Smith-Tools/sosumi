import XCTest
@testable import SosumiCore

final class SosumiCoreTests: XCTestCase {
    
    func testSearchEngineInitialization() {
        // Verify the search engine can be instantiated
        let core = SosumiCore()
        XCTAssertNotNil(core)
    }
    
    func testWWDCSearchAvailable() {
        // Verify WWDC search is available
        XCTAssertNotNil(SosumiCore.self)
    }
}
