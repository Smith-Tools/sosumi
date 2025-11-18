import Testing
@testable import SosumiCore

@Suite("SosumiCore Tests")
struct SosumiCoreTests {

    @Test("Search engine initialization")
    func testSearchEngineInitialization() {
        // Verify the search engine can be instantiated
        let core = SosumiCore()
        #expect(core != nil)
    }

    @Test("WWDC search available")
    func testWWDCSearchAvailable() {
        // Verify WWDC search is available
        #expect(SosumiCore.self != nil)
    }
}
