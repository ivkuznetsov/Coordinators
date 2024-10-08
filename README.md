# Coordinators

This repository contains an implementation of the Coordinator pattern for SwiftUI, providing a structured way to manage complex navigation flows, including handling both navigation stacks and modal presentations.

## Overview

The Coordinator pattern helps manage navigation in a more structured and maintainable way by centralizing navigation logic. This implementation includes support for:

Navigation Stack: Navigate between different screens in a push/pop style.
Modal Presentation: Present modals, including entire navigation flows inside modal views.

## Example Usage

### 1. Defining a Coordinator
```swift
final class SomeCoordinator: NavigationModalCoordinator {
    
    // Enum to define the screens that can be navigated to
    enum Screen: ScreenProtocol {
        case screen1
        case screen2
        case screen3
    }
    
    // Define destination views for each screen
    func destination(for screen: Screen) -> some View {
        switch screen {
        case .screen1: Screen1View()
        case .screen2: Screen2View()
        case .screen3: Screen3View()
        }
    }
    
    // Enum to define modal flows that can be presented
    enum ModalFlow: ModalProtocol {
        case modalScreen1
        case modalFlow(ChildCoordinator = .init())
    }
    
    // Define destination views for each modal flow
    func destination(for flow: ModalFlow) -> some View {
        switch flow {
        case .modalScreen1: Modal1View()
        case .modalFlow(let coordinator): coordinator.view(for: .rootScreen)
        }
    }
}
```

### 2. Using the Coordinator
You can use the coordinator to push views onto the navigation stack or present modals.

Displaying a screen as the root view:
```swift
coordinator.view(for: .screen1)
```

Pushing a new screen onto the navigation stack:
```swift
coordinator.present(.screen1)
```

Presenting a modal flow:
```swift
coordinator.present(.modalFlow())
```

### 3. Accessing the Coordinator in Views

You can access the current coordinator inside any view by injecting it as an environment object:
```swift
@EnvironmentObject var coordinator: Navigation<SomeCoordinator>
```
This allows you to trigger navigation actions directly from views, maintaining a clean and decoupled architecture.

## Meta

Ilya Kuznetsov – i.v.kuznecov@gmail.com

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/ivkuznetsov](https://github.com/ivkuznetsov)
