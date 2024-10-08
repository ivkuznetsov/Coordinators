//
//  CustomCoordinator.swift
//
//
//  Created by Ilya Kuznetsov on 09/10/2023.
//

import Foundation
import SwiftUI

public protocol CustomCoordinator: Coordinator {
    associatedtype DestinationView: View
    
    func destination() -> DestinationView
}

public extension CustomCoordinator {
    
    var rootView: some View { destination().withModal(self) }
}
