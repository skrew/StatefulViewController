import UIKit

/// Represents all possible states of a stateful view controller
public enum StatefulViewControllerState: String {
    case content
    case loading
    case error
    case empty
}

/// Protocol to provide a backing view for that stateful view controller
public protocol BackingViewProvider {
    /// The backing view, usually a UIViewController's view.
    /// All placeholder views will be added to this view instance.
    var backingView: UIView { get }
}

/// StatefulViewController protocol may be adopted by a view controller or a view in order to transition to
/// error, loading or empty views.
public protocol StatefulViewController: class, BackingViewProvider {
    /// The view state machine backing all state transitions
    var viewStateMachine: ViewStateMachine { get }

    /// The work item that is added to the queue for the loading transition
    var loadingWorkItem: DispatchWorkItem? { get set }

    /// A serial dispatch queue that executes the transitions between states
    var queue: DispatchQueue { get }

    /// The current transition state of the view controller.
    /// All states other than `Content` imply that there is a placeholder view shown.
    var currentState: StatefulViewControllerState { get }
    
    /// The last transition state that was sent to the state machine for execution.
    /// This does not imply that the state is currently shown on screen. Transitions are queued up and 
    /// executed in sequential order.
    var lastState: StatefulViewControllerState { get }
    
    
    // MARK: Views
    
    /// The loading view is shown when the `startLoading` method gets called
    var loadingView: UIView? { get set }
    
    /// The error view is shown when the `endLoading` method returns an error
    var errorView: UIView? { get set }
    
    /// The empty view is shown when the `hasContent` method returns false
    var emptyView: UIView? { get set }

    
    // MARK: Transitions

    /// Sets up the initial state of the view.
    /// This method should be called as soon as possible in a view or view controller's
    /// life cycle, e.g. `viewWillAppear:`, to transition to the appropriate state.
    func setupInitialViewState(_ completion: (() -> Void)?)
    
    /// Transitions the controller to the loading state and shows
    /// the loading view if there is no content shown already.
    ///
    /// - parameter animated: 	true if the switch to the placeholder view should be animated, false otherwise
    func startLoading(animated: Bool, completion: (() -> Void)?)
    
    /// Ends the controller's loading state.
    /// If an error occurred, the error view is shown.
    /// If the `hasContent` method returns false after calling this method, the empty view is shown.
    ///
    /// - parameter animated: 	true if the switch to the placeholder view should be animated, false otherwise
    /// - parameter error:		An error that might have occurred whilst loading
    func endLoading(animated: Bool, error: Error?, completion: (() -> Void)?)
    
    // MARK: Content and error handling
    
    /// Return true if content is available in your controller.
    ///
    /// - returns: true if there is content available in your controller.
    func hasContent() -> Bool
    
    /// This method is called if an error occurred, but `hasContent` returned true.
    /// You would typically display an unobstrusive error message that is easily dismissable
    /// for the user to continue browsing content.
    ///
    /// - parameter error:	The error that occurred
    func handleErrorWhenContentAvailable(_ error: Error)

    /// returns the transition delay to the loading state
    func toLoadingTransitionDelay() -> Double

    /// returns the transition delay from the loading state
    func fromLoadingTransitionDelay() -> Double
}
