import XCTest
@testable import StatefulViewController

final class StatefulViewControllerTests: XCTestCase {

    lazy var stateMachine = ViewStateMachine(view: UIView())
       var errorView: UIView = UIView()
       var loadingView: UIView = UIView()
       var emptyView: UIView = UIView()

       override func setUp() {
           super.setUp()

           errorView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
           errorView.backgroundColor = UIColor.red

           loadingView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
           loadingView.backgroundColor = UIColor.blue

           emptyView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
           emptyView.backgroundColor = UIColor.gray

           stateMachine.addView(errorView, forState: "error")
           stateMachine.addView(loadingView, forState: "loading")
           stateMachine.addView(emptyView, forState: "empty")
       }

       override func tearDown() {
           // Put teardown code here. This method is called after the invocation of each test method in the class.
           super.tearDown()
       }

       func testStateMachine() {
           let errorTransition = expectation(description: "wait for error state transition")
           stateMachine.transitionToState(.view("error"), animated: true) {
               errorTransition.fulfill()
           }
           wait(for: [errorTransition], timeout: 0.1)
           XCTAssertTrue(self.errorView.superview?.superview === self.stateMachine.view, "")
           XCTAssertNil(self.loadingView.superview, "")
           XCTAssertNil(self.emptyView.superview, "")

           let loadingTransition = expectation(description: "wait for loading state transition")
           stateMachine.transitionToState(.view("loading"), animated: true) {
               loadingTransition.fulfill()
           }
           wait(for: [loadingTransition], timeout: 0.1)
           XCTAssertNil(self.errorView.superview, "")
           XCTAssertTrue(self.loadingView.superview?.superview === self.stateMachine.view, "")
           XCTAssertNil(self.emptyView.superview, "")

           let noneTransition = expectation(description: "wait for reset (no state) transition")
           stateMachine.transitionToState(.none, animated: true) {
               noneTransition.fulfill()
           }
           wait(for: [noneTransition], timeout: 0.1)
           XCTAssertNil(self.errorView.superview, "")
           XCTAssertNil(self.loadingView.superview, "")
           XCTAssertNil(self.emptyView.superview, "")

           let emptyTransition = expectation(description: "wait for empty state transition")
           stateMachine.transitionToState(.view("empty"), animated: true) {
               emptyTransition.fulfill()
           }
           wait(for: [emptyTransition], timeout: 0.1)
           XCTAssertNil(self.errorView.superview, "")
           XCTAssertNil(self.loadingView.superview, "")
           XCTAssertTrue(self.emptyView.superview?.superview === self.stateMachine.view, "")
       }






    static var allTests = [
        ("testStateMachine", testStateMachine),
    ]
}
