//
//  NavigationCoordinator.swift 
//
//  Created by Ilya Kuznetsov on 08/05/2023.
//

import Foundation
import SwiftUI

///Protocol for conforming by a screen in horizontal navigation flow
public protocol ScreenProtocol: Hashable { }

public protocol NavigationCoordinator: Coordinator {
    associatedtype Screen: ScreenProtocol
    associatedtype ScreenView: View
    
    @ViewBuilder func destination(for screen: Screen) -> ScreenView
}

public extension NavigationCoordinator {
    
    /// Navigate to a new screen in current navigation stack
    func present(_ screen: Screen) {
        state.path.append(screen)
    }
    
    /// Move back to a specified screen in current navigation
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
    
    /// Move back to a specified screen in current navigation
    @discardableResult
    func popTo(_ element: Screen) -> Bool {
        popTo(where: { $0 == element })
    }
}

@available(iOS 16.0, *)
public extension View {
    
    func withNavigation<C: NavigationCoordinator>(_ coordinator: C) -> some View {
        modifier(NavigationModifer(coordinator: coordinator)).environmentObject(coordinator)
    }
}

@available(iOS 16.0, *)
public extension NavigationCoordinator {
    
    func view(for screen: Screen) -> some View {
        destination(for: screen).withNavigation(self).withModal(self)
    }
}

@available(iOS 16.0, *)
private struct NavigationModifer<Coordinator: NavigationCoordinator>: ViewModifier {
    
    let coordinator: Coordinator
    @ObservedObject var state: NavigationState
    @State var currentPath: [AnyHashable] = [] // we cannot use navigation path in @Publiched because of bug in modal sheet, where the first push happens without animation
    @State private var appeared = false
    
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
        self.state = coordinator.state
    }
    
    public func body(content: Content) -> some View {
        NavigationStack(path: $currentPath) {
            content.navigationDestination(for: AnyHashable.self) {
                if let screen = $0 as? Coordinator.Screen {
                    coordinator.destination(for: screen)
                }
            }
        }.coordinateSpace(name: CoordinateSpace.navController)
            .navigationViewStyle(.stack)
            .onChange(of: state.path, perform: {
                if $0 != currentPath {
                    currentPath = $0
                }
            }).onChange(of: currentPath, perform: {
                if $0 != state.path {
                    state.path = $0
                }
            }).onAppear(perform: {
                if !appeared {
                    appeared = true
                    currentPath = coordinator.state.path
                }
            })
    }
}
