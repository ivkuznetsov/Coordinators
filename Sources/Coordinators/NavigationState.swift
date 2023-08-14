//
//  NavigationState.swift
//
//  Created by Ilya Kuznetsov on 28/07/2023.
//

import Foundation
import SwiftUI
import Combine

///Current modal presentation that stores parent coordinator
public struct ModalPresentation {
    
    private final class PlaceholderCoordinator: Coordinator { }
    
    public let modalFlow: any ModalProtocol
    
    let coordinator: any Coordinator
    let destination: ()->AnyView
    
    init(modalFlow: any ModalProtocol, destination: @escaping () -> AnyView) {
        self.modalFlow = modalFlow
        
        if let coordinator = modalFlow.coordinator {
            self.destination = destination
            self.coordinator = coordinator
        } else {
            let coordinator = PlaceholderCoordinator()
            self.destination = { AnyView(destination().withModal(coordinator)) }
            self.coordinator = coordinator
        }
    }
}

///Coordinator navigation state. Stores current navigation path and a reference to presented child navigation with reference to parent coordinator
public final class NavigationState: ObservableObject {
    
    /// Current navigation path
    @Published public var path: [AnyHashable] = []
    
    /// Modal flow presented over current navigation
    @Published public internal(set) var modalPresented: ModalPresentation?
    
    /// Parent coordinator presented current navigation modally
    public internal(set) weak var presentedBy: (any Coordinator)?
    private var observers: [AnyCancellable] = []
    
    public init() {
        $path.sink { [weak self] _ in
            self?.closeKeyboard()
        }.store(in: &observers)
        
        $modalPresented.sink { [weak self] _ in
            self?.closeKeyboard()
        }.store(in: &observers)
    }
    
    private func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

