import UIKit


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
        let isLoading = (lastState == .loading)
        let error: NSError? = (lastState == .error) ? NSError(domain: "de.apploft.StatefulViewController.ErrorDomain", code: -1, userInfo: nil) : nil
        transitionViewStates(loading: isLoading, error: error, animated: false, completion: completion)
    }
    
    public func startLoading(animated: Bool = false, completion: (() -> Void)? = nil) {
        transitionViewStates(loading: true, animated: animated, completion: completion)
    }
    
    public func endLoading(animated: Bool = true, error: Error? = nil, completion: (() -> Void)? = nil) {
        transitionViewStates(loading: false, error: error, animated: animated, completion: completion)
    }
    
    public func transitionViewStates(loading: Bool = false, error: Error? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        // Update view for content (i.e. hide all placeholder views)
        var delay: Double = 0

        if hasContent() {
            if let e = error {
                // show unobstrusive error
                handleErrorWhenContentAvailable(e)
            }

            if viewStateMachine.currentState == .view("loading") {
                delay = fromLoadingTransitionDelay()
            } else {
                loadingWorkItem?.cancel()
                loadingWorkItem = nil
            }
            queue.asyncAfter(deadline: .now() + delay, execute: nextDispatchWorkItem(state: .none, animated: animated, completion: completion))
            return
        }
        
        // Update view for placeholder
        var newState: StatefulViewControllerState = .empty
        if loading {
            newState = .loading
            loadingWorkItem = nextDispatchWorkItem(state: .view(newState.rawValue), animated: animated, completion: completion)
            queue.asyncAfter(deadline: .now() + toLoadingTransitionDelay(), execute: loadingWorkItem!)
            return
        }

        if let _ = error {
            newState = .error
        }
        queue.async(execute: nextDispatchWorkItem(state: .view(newState.rawValue), animated: animated, completion: completion))
    }

    func nextDispatchWorkItem(state: ViewStateMachineState, animated: Bool = true, completion: (() -> Void)? = nil) -> DispatchWorkItem {
        return DispatchWorkItem { [weak self] in
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
