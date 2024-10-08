//
//  NavigationCoordinator.swift 
//
//  Created by Ilya Kuznetsov on 08/05/2023.
//

import Foundation
import SwiftUI

///Protocol for conforming by a screen identifier in horizontal navigation flow
public protocol ScreenProtocol: Hashable { }

///Protocol that defines navigation-specific behavior
public protocol NavigationCoordinator: Coordinator {
    associatedtype Screen: ScreenProtocol
    associatedtype ScreenView: View
    
    ///A method that returns the destination view for a given screen identifier
    @ViewBuilder func destination(for screen: Screen) -> ScreenView
}

public extension NavigationCoordinator {
    
    ///Navigate to a new screen in current navigation stack
    func present(_ screen: Screen) {
        state.path.append(screen)
    }
    
    ///Move back in the navigation stack to the first screen that meets the specified condition, returns True if the screen has been found
    @discardableResult
    func popTo(where condition: (Screen) -> Bool) -> Bool {
        if let index = state.path.firstIndex(where: {
            if let screen = $0 as? Screen {
                return condition(screen)
            }
            return false
        }) {
            state.path.removeLast(state.path.count - index - 1)
            return true
        }
        return false
    }
    
    ///Move back in the navigation stack to a specific screen, returns True if the screen has been found
    @discardableResult
    func popTo(_ element: Screen) -> Bool {
        popTo(where: { $0 == element })
    }
}

@available(iOS 16.0, *)
public extension View {
    
    ///Extend the view with navigation capabilities using the specified Coordinator
    func withNavigation<C: NavigationCoordinator>(_ coordinator: C) -> some View {
        modifier(NavigationModifer(coordinator: coordinator))
    }
}

@available(iOS 16.0, *)
public extension NavigationCoordinator {
    
    /// Creates a view for the given screen identifier and applies both navigation and modal capabilities
    func view(for screen: Screen) -> some View {
        destination(for: screen).withNavigation(self).withModal(self)
    }
}

///A `ViewModifier` that adds navigation functionality to views managed by a `NavigationCoordinator`
@available(iOS 16.0, *)
private struct NavigationModifer<Coordinator: NavigationCoordinator>: ViewModifier {
    
    let coordinator: Coordinator
    @ObservedObject var state: NavigationState
    
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        self.state = coordinator.state
    }
    
    public func body(content: Content) -> some View {
        NavigationStack(path: $state.path) { [weak coordinator] in
            content.navigationDestination(for: AnyHashable.self) {
                if let screen = $0 as? Coordinator.Screen {
                    coordinator?.destination(for: screen)
                }
            }
        }.coordinateSpace(name: CoordinateSpace.navController)
    }
}
