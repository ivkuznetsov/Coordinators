# Coordinators

Implementation of Coordinator pattern in Swift UI

Example of implementation:

```swift
final class SomeCoordinator: NavigationModalCoordinator {
    enum Screen: ScreenProtocol {
        case screen1
        case screen2
        case screen3
    }
    
    func destination(for screen: Screen) -> some View {
        switch screen {
            case .screen1: Screen1View()
            case .screen2: Screen2View()
            case .screen3: Screen3View()
        }
    }
    
    enum ModalFlow: ModalProtocol {
        case modalScreen1
        case modalFlow(ChildCoordinator = .init())
    }
    
    func destination(for flow: ModalFlow) -> some View {
        switch flow {
            case .modalScreen1: Modal1View()
            case .modalFlow(let coordinator): coordinator.view(for: .rootScreen)
        }
    }
}
```

SomeCoordinator contains a navigation controller that can push one of the 3 views defined by Screen enum.
Also it can present a modal view and a modal navigation flow with child navigation specified by ChildCoordinator.

Show view in SwiftUI hierarchy, with screen1 as root view:
```swift
coordinator.view(for: .screen1)
```

Push view in navigation stack:
```swift
coordinator.present(.screen1)
```

Present modal view:
```swift
coordinator.present(.modalFlow())
```

Current coordinator passed to child views as environment object:
```swift
@EnvironmentObject var coordinator: SomeCoordinator
```

## Meta

Ilya Kuznetsov – i.v.kuznecov@gmail.com

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/ivkuznetsov](https://github.com/ivkuznetsov)
