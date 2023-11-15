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
            self.destination = { [unowned coordinator] in AnyView(destination().withModal(coordinator)) }
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
    
    struct Alert {
        let title: String
        let actions: ()->AnyView
        let message: ()->AnyView
        
        init<A: View, M: View>(title: String, actions: @escaping ()->A, message: @escaping ()->M) {
            self.title = title
            self.actions = { AnyView(actions()) }
            self.message = { AnyView(message()) }
        }
    }
    
    /// Currently presented alerts
    @Published var alerts: [Alert] = []
    
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
        UIApplication.shared.resignFirstResponder()
    }
}

