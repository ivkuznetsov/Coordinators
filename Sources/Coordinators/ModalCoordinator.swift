//
//  ModalCoordinator.swift
//
//  Created by Ilya Kuznetsov on 07/05/2023.
//

import Foundation
import SwiftUI

///Modal presentation stype of the Modal flow
public enum ModalStyle {
    
    ///Present as sheet, takes part of the screen and dimms screen below
    case sheet
    
    ///Presents as full screen cover
    case cover
    
    ///Presents screen over current navigation. This option is for customizing, it doesn't interfear with native navigation controller or modal presentation flow.
    case overlay
}

///Protocol for conforming by a modal navigation flow
public protocol ModalProtocol: Hashable, Identifiable {
    
    ///Modal flow presentation style
    var style: ModalStyle { get }
}

public extension ModalProtocol {
    
    var style: ModalStyle { .sheet }
    
    var id: Int { hashValue }
}

extension ModalProtocol {
    
    var coordinator: (any Coordinator)? {
        for child in Mirror(reflecting: self).children {
            if let value = child.value as? (any Coordinator) {
                return value
            }
        }
        return nil
    }
}

public protocol ModalCoordinator: Coordinator {
    associatedtype Modal: ModalProtocol
    associatedtype ModalView: View
    
    @ViewBuilder func destination(for modal: Modal) -> ModalView
}

///Resolution for the case when we're trying to present a modal flow over screen which already presents another screen
public enum PresentationResolve {
    
    ///Search for currently presented top screen and present our screen over it
    case overAll
    
    ///Dismiss currently presented screen and present our screen in replace
    case replaceCurrent
}

public extension ModalCoordinator {
    
    ///Present a flow modally over current navigation
    func present(_ modalFlow: Modal, resolve: PresentationResolve = .overAll) {
        present(.init(modalFlow: modalFlow,
                      destination: { AnyView(self.destination(for: modalFlow)) }),
                resolve: resolve)
    }
}

private struct ModalModifer: ViewModifier {
    
    @ObservedObject var state: NavigationState
    
    func isPresentedBinding(_ style: ModalStyle) -> Binding<Bool> {
        .init {
            state.modalPresented?.modalFlow.style == style
        } set: { _ in
            if let presented = state.modalPresented,
               let overlayPresented = presented.coordinator.state.modalPresented,
               overlayPresented.modalFlow.style == .overlay {
                presented.coordinator.state.modalPresented = nil
            } else {
                state.modalPresented = nil
            }
        }
    }
    
    func body(content: Content) -> some View {
        content.overlay {
            if let presented = state.modalPresented, presented.modalFlow.style == .overlay {
                presented.destination()
                    .coordinateSpace(name: CoordinateSpace.modal)
            }
        }.sheet(isPresented: isPresentedBinding(.sheet)) {
            
            state.modalPresented!.destination()
                .coordinateSpace(name: CoordinateSpace.modal)
            
        }.fullScreenCover(isPresented: isPresentedBinding(.cover)) {
            
            state.modalPresented!.destination()
                .coordinateSpace(name: CoordinateSpace.modal)
        }
    }
}

public extension View {
    
    ///Supply view with ability to present screens using specified coordinator
    func withModal<C: Coordinator>(_ coordinator: C) -> some View {
        modifier(ModalModifer(state: coordinator.state)).environmentObject(coordinator)
    }
}

