//
//  ModalCoordinator.swift
//
//  Created by Ilya Kuznetsov on 07/05/2023.
//

import Foundation
import SwiftUI

///Defines the modal presentation style for a modal flow
public enum ModalStyle {
    
    ///Presents the modal as a sheet, which occupies part of the screen and dims the background
    case sheet
    
    ///Presents the modal as a full-screen cover
    case cover
    
    /// Presents the modal as an overlay on top of the current navigation.
    /// This option is customizable and doesn't interfere with the native navigation controller or modal presentation flow.
    case overlay
}

///Protocol to be conformed by a modal navigation flow
public protocol ModalProtocol: Hashable, Identifiable {
    
    ///The presentation style of the modal flow
    var style: ModalStyle { get }
}

public extension ModalProtocol {
    
    ///Default presentation style for modals is `.sheet`
    var style: ModalStyle { .sheet }
    
    var id: Int { hashValue }
}

extension ModalProtocol {
    
    ///Returns a Coordinator If a modal flow contains one.
    ///It iterates through the properties of the modal flow using reflection.
    var coordinator: (any Coordinator)? {
        for child in Mirror(reflecting: self).children {
            if let value = child.value as? (any Coordinator) {
                return value
            }
        }
        return nil
    }
}

///Protocol for a Coordinator that manages modals
public protocol ModalCoordinator: Coordinator {
    associatedtype Modal: ModalProtocol
    associatedtype ModalView: View
    
    ///A method that returns the destination view for a given modal
    @MainActor @ViewBuilder func destination(for modal: Modal) -> ModalView
}

///Enum to define how to resolve situations where a modal is already presented by this Coordinator
public enum PresentationResolve {
    
    ///Present the new modal on top of the currently presented screen
    case overAll
    
    ///Dismiss the currently presented modal and replace it with the new one
    case replaceCurrent
}

@MainActor
public extension ModalCoordinator {
    
    ///Presents a modal flow over the current navigation using the specified `resolve` strategy
    func present(_ modalFlow: Modal, resolve: PresentationResolve = .overAll) {
        present(.init(modalFlow: modalFlow,
                      destination: { [unowned self] in AnyView(self.destination(for: modalFlow)) }),
                resolve: resolve)
    }
}

///A view modifier that manages the presentation of modal views based on the current navigation state
private struct ModalModifer: ViewModifier {
    
    @ObservedObject var state: NavigationState
    
    ///Creates a binding for checking if a modal of a specific style is currently presented
    func isPresentedBinding(_ style: ModalStyle) -> Binding<Bool> {
        let presented = state.modalPresented
        
        return .init {
            presented?.modalFlow.style == style
        } set: { [weak state] _ in
            guard state?.modalPresented == presented, state?.modalPresented != nil else { return }
            
            if let presented,
               let overlayPresented = presented.coordinator.state.modalPresented,
               overlayPresented.modalFlow.style == .overlay {
                presented.coordinator.state.modalPresented = nil
            } else {
                state?.modalPresented = nil
            }
        }
    }
    
    func body(content: Content) -> some View {
        content.overlay {
            if let presented = state.modalPresented, presented.modalFlow.style == .overlay {
                presented.destination()
                    .coordinateSpace(name: CoordinateSpace.modal)
            }
        }
        .sheet(isPresented: isPresentedBinding(.sheet)) { [weak state] in
            state?.modalPresented!.destination()
                .coordinateSpace(name: CoordinateSpace.modal)
        }.fullScreenCover(isPresented: isPresentedBinding(.cover)) { [weak state] in
            state?.modalPresented!.destination()
                .coordinateSpace(name: CoordinateSpace.modal)
        }.alert(state.alerts.last?.title ?? "",
                isPresented: Binding(get: { state.alerts.last != nil }, set: { _ in
            if state.alerts.count > 0 {
                state.alerts.removeLast()
            }
        } ), actions: state.alerts.last?.actions ?? { AnyView(EmptyView()) },
                message: state.alerts.last?.message ?? { AnyView(EmptyView()) })
    }
}

public extension View {
    
    ///Extends the current view to support modal presentation via a specified `Coordinator`
    @MainActor
    func withModal<C: Coordinator>(_ coordinator: C) -> some View {
        modifier(ModalModifer(state: coordinator.state))
            .environmentObject(coordinator.weakReference)
            .environmentObject(coordinator.anyWeakReference)
    }
}

