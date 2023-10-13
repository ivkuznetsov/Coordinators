//
//  Coordinator.swift
//
//  Created by Ilya Kuznetsov on 07/05/2023.
//

import Foundation
import SwiftUI

///Example of implementation:
///
///    final class SomeCoordinator: NavigationModalCoordinator {
///
///      enum Screen: ScreenProtocol {
///         case screen1
///         case screen2
///         case screen3
///      }
///
///      func destination(for screen: Screen) -> some View {
///         switch screen {
///             case .screen1: Screen1View()
///             case .screen2: Screen2View()
///             case .screen3: Screen3View()
///         }
///      }
///
///      enum ModalFlow: ModalProtocol {
///         case modalScreen1
///         case modalFlow(ChildCoordinator = .init())
///      }
///
///      func destination(for flow: ModalFlow) -> some View {
///         switch flow {
///            case .modalScreen1: Modal1View()
///            case .modalFlow(let coordinator): coordinator.view(for: .rootScreen)
///         }
///      }
///    }
///
///SomeCoordinator contains a navigation controller that can push one of the 3 views defined by Screen enum.
///Also it can present a modal view and a modal navigation flow with child navigation specified by ChildCoordinator
///
///Show view in SwiftUI hierarchy, with screen1 as root view:
///
///     coordinator.view(for: .screen1)
///
///Push view in navigation stack:
///
///     coordinator.present(.screen1)
///
///Present modal view:
///
///     coordinator.present(.modalFlow())
///

public final class Navigation<C: Coordinator>: ObservableObject {
    private(set) weak var object: C?
    
    public init(_ object: C) {
        self.object = object
    }
    
    public func callAsFunction() -> C { object! }
}

public protocol Coordinator: ObservableObject, Hashable { }

private var coordinatorStateKey = 0
private var coordinatorWeakReferenceKey = 0

public extension Coordinator {
    
    ///Coordinator state, encapsulates current navigation path and presented modal flow and reference to parent coordinator
    var state: NavigationState {
        get {
            if let state = objc_getAssociatedObject(self, &coordinatorStateKey) as? NavigationState {
                return state
            } else {
                let state = NavigationState()
                objc_setAssociatedObject(self, &coordinatorStateKey, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return state
            }
        }
    }
    
    var weakReference: Navigation<Self> {
        get {
            if let reference = objc_getAssociatedObject(self, &coordinatorWeakReferenceKey) as? Navigation<Self> {
                return reference
            } else {
                let reference = Navigation(self)
                objc_setAssociatedObject(self, &coordinatorWeakReferenceKey, reference, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return reference
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.hashValue == rhs.hashValue }
    
    ///Dismiss current modal navigation
    func dismiss() {
        state.presentedBy?.dismissPresented()
    }
    
    ///Dismiss modal navigation presented over current navigation
    func dismissPresented() {
        state.modalPresented = nil
    }
    
    ///Move to previous screen of the current navigation
    func pop() {
        state.path.removeLast()
    }
    
    ///Move to the first screen of the current navigation
    func popToRoot() {
        state.path.removeAll()
    }
}

extension Coordinator {
    
    func present(_ presentation: ModalPresentation, resolve: PresentationResolve = .overAll) {
        if let presentedCoordinator = state.modalPresented?.coordinator {
            switch resolve {
            case .replaceCurrent:
                dismissPresented()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.present(presentation, resolve: resolve)
                }
            case .overAll:
                presentedCoordinator.present(presentation, resolve: resolve)
            }
        } else {
            presentation.coordinator.state.presentedBy = self
            state.modalPresented = presentation
        }
    }
}

public extension Coordinator {
    static var defaultAlertTitle: String { Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary!["CFBundleName"] as? String ?? "" }
    
    func alert<A: View, M: View>(_ title: String = Self.defaultAlertTitle,
                                 @ViewBuilder _ message: @escaping ()->M,
                                 @ViewBuilder actions: @escaping ()->A) {
        state.alerts.append(.init(title: title, actions: actions, message: message))
    }
    
    func alert<M: View>(_ title: String = Self.defaultAlertTitle,
                        @ViewBuilder _ message: @escaping ()->M) {
        state.alerts.append(.init(title: title, actions: { Button("OK") {} }, message: message))
    }
    
    func alert(_ title: String = Self.defaultAlertTitle, message: String) {
        state.alerts.append(.init(title: title, actions: { Button("OK") {} }, message: { Text(message) }))
    }
    
    func alert<A: View>(_ title: String = Self.defaultAlertTitle,
                        message: String,
                        @ViewBuilder actions: @escaping ()->A) {
        state.alerts.append(.init(title: title, actions: actions, message: { Text(message) }))
    }
}

public typealias NavigationModalCoordinator = NavigationCoordinator & ModalCoordinator

public extension CoordinateSpace {
    
    ///Coordinated space related to navigation view
    static let navController = "CoordinatorSpaceNavigationController"
    
    ///Coordinated space related to modal presentation view
    static let modal = "CoordinatorSpaceModal"
}
