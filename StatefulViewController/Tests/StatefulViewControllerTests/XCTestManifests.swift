import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(StatefulViewControllerTests.allTests),
    ]
}
#endif
