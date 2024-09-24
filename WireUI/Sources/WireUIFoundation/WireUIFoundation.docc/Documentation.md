# ``WireUIFoundation``

Structural UI types like main container view controllers, the main coordinator and more.

## Overview

This target is responsible for the navigation and user interface management within the application after successfully logging in. It contains key classes that coordinate the app's main flow and structure, including handling tab-based and split-view navigation patterns.

## Topics

- ``MainCoordinator``

The MainCoordinator class manages the primary flow of the application. It is responsible for initializing and controlling the root view controllers, handling navigation between different sections, and ensuring that the correct view controllers are displayed based on user interactions or app state changes.

Key Responsibilities:

Initializing the main view controllers (e.g., MainTabBarController or MainSplitViewController).
Handling navigation logic, including transitioning between tabs or views.
Managing dependencies and passing data between view controllers.


MainTabBarController
The MainTabBarController class is a custom subclass of UITabBarController that manages the app's tab-based navigation interface. It handles the setup and configuration of multiple view controllers presented as tabs, allowing users to switch between different sections of the app.

Key Responsibilities:

Configuring the tab bar items and their associated view controllers.
Managing the tab bar appearance and behavior.
Handling user interaction with the tab bar and coordinating transitions between tabs.
MainSplitViewController
The MainSplitViewController class is a custom subclass of UISplitViewController designed to manage a split-view interface, typically used in apps that run on larger screen devices like iPads. This controller handles the master-detail relationship between view controllers, ensuring a responsive and adaptive user experience.

Key Responsibilities:

Configuring the primary and secondary view controllers for the split view.
Managing the display mode (e.g., collapsed, expanded) based on the device's size class.
Handling the transitions and interactions between the master and detail views.
Summary
Together, these classes form the backbone of the app's navigation and interface structure, providing a cohesive and responsive user experience. The MainCoordinator orchestrates the overall flow, while the MainTabBarController and MainSplitViewController provide the specific UI components for tab-based and split-view navigation, respectively.





### Conversations

- ``ConversationRepository``
- ``ConversationLocalStore``

### Repositories

- ``UserRepository``
- ``ConversationRepository``

### UseCases

- TBD
