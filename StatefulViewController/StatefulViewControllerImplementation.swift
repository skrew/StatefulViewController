import UIKit
import os


// MARK: Default Implementation BackingViewProvider

extension BackingViewProvider where Self: UIViewController {
    public var backingView: UIView {
        return view
    }
}

extension BackingViewProvider where Self: UIView {
    public var backingView: UIView {
        return self
    }
}

fileprivate let log = OSLog(subsystem: "de.apploft.StatefulViewControllerImplementation", category: "General")

// MARK: Default Implementation StatefulViewController

/// Default implementation of StatefulViewController for UIViewController
extension StatefulViewController {
    
    public var viewStateMachine: ViewStateMachine {
        return associatedObject(self, key: &stateMachineKey) { [unowned self] in
            return ViewStateMachine(view: self.backingView)
        }
    }

    public var loadingWorkItem: DispatchWorkItem? {
        get {
            return objc_getAssociatedObject(self, &loadingWorkItemKey) as? DispatchWorkItem
        }
        set {
            objc_setAssociatedObject(self, &loadingWorkItemKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    public var queue: DispatchQueue {
        return associatedObject(self, key: &queueKey) {
            return DispatchQueue(label: "de.apploft.StatefulViewController.serialQueue")
        }
    }
    
    public var currentState: StatefulViewControllerState {
        switch viewStateMachine.currentState {
        case .none: return .content
        case .view(let viewKey): return StatefulViewControllerState(rawValue: viewKey)!
        }
    }
    
    public var lastState: StatefulViewControllerState {
        switch viewStateMachine.lastState {
        case .none: return .content
        case .view(let viewKey): return StatefulViewControllerState(rawValue: viewKey)!
        }
    }
    
    
    // MARK: Views
    
    public var loadingView: UIView? {
        get { return placeholderView(.loading) }
        set { setPlaceholderView(newValue, forState: .loading) }
    }
    
    public var errorView: UIView? {
        get { return placeholderView(.error) }
        set { setPlaceholderView(newValue, forState: .error) }
    }
    
    public var emptyView: UIView? {
        get { return placeholderView(.empty) }
        set { setPlaceholderView(newValue, forState: .empty) }
    }
    
    
    // MARK: Transitions
    
    public func setupInitialViewState(_ completion: (() -> Void)? = nil) {
        var vms = ViewStateMachineState.none

        if hasContent() {
            vms = .view(StatefulViewControllerState.content.rawValue)
        }
        queue.async(execute: nextDispatchWorkItem(state: vms, animated: false, completion: completion))
    }
    
    public func startLoading(animated: Bool = false, completion: (() -> Void)? = nil) {
        var newState: StatefulViewControllerState = .loading
        if hasContent() {
            newState = .content
            queue.async(execute: nextDispatchWorkItem(state: .view(newState.rawValue), animated: animated, completion: completion))
        } else {
            newState = .loading
            loadingWorkItem = nextDispatchWorkItem(state: .view(newState.rawValue), animated: animated, completion: completion)
            queue.asyncAfter(deadline: .now() + toLoadingTransitionDelay(), execute: loadingWorkItem!)
        }
    }
    
    public func endLoading(animated: Bool = true, error: Error? = nil, completion: (() -> Void)? = nil) {
        var delay: Double = 0
        var newState: StatefulViewControllerState = .empty

        if let _ = error {
            newState = .error
        }

        if hasContent() {
            newState = .content
            if let error = error {
                handleErrorWhenContentAvailable(error)
            }
        }

        if currentState == .loading {
            delay = fromLoadingTransitionDelay()
        } else {
           os_log("cancel loading work item", log: log, type: .debug, "")
           loadingWorkItem?.cancel()
           loadingWorkItem = nil
        }

        let newViewStateMachineState: ViewStateMachineState = (newState == .content) ? .none : .view(newState.rawValue)
        queue.asyncAfter(deadline: .now() + delay, execute: nextDispatchWorkItem(state: newViewStateMachineState, animated: animated, completion: completion))
    }

    func nextDispatchWorkItem(state: ViewStateMachineState, animated: Bool = true, completion: (() -> Void)? = nil) -> DispatchWorkItem {
        return DispatchWorkItem { [weak self] in
            os_log("transition to state %@", log: log, type: .debug, state.description)
            self?.viewStateMachine.transitionToState(state)
        }
    }
    
    
    // MARK: Content and error handling
    
    public func hasContent() -> Bool {
        return true
    }
    
    public func handleErrorWhenContentAvailable(_ error: Error) {
        // Default implementation does nothing.
    }
    
    
    // MARK: Helper
    
    fileprivate func placeholderView(_ state: StatefulViewControllerState) -> UIView? {
        return viewStateMachine[state.rawValue]
    }
    
    fileprivate func setPlaceholderView(_ view: UIView?, forState state: StatefulViewControllerState) {
        viewStateMachine[state.rawValue] = view
    }


    // MARK: Loading transition delay

    public func toLoadingTransitionDelay() -> Double {
        return 1
    }

    public func fromLoadingTransitionDelay() -> Double {
        return 1
    }
}


// MARK: Association

private var stateMachineKey: UInt8 = 0
private var loadingWorkItemKey: UInt8 = 1
private var queueKey: UInt8 = 2

private func associatedObject<T: AnyObject>(_ host: AnyObject, key: UnsafeRawPointer, initial: () -> T) -> T {
    var value = objc_getAssociatedObject(host, key) as? T
    if value == nil {
        value = initial()
        objc_setAssociatedObject(host, key, value, .OBJC_ASSOCIATION_RETAIN)
    }
    return value!
}
