# ``WireUIFoundation``

Structural UI types like main container view controllers, the main coordinator
and more.

## Overview

This target is responsible for the navigation and user interface management
within the application after successfully logging in. It contains key classes
that coordinate the app's main flow and structure, including handling tab-based
and split-view navigation patterns.

## Concept

On large screens, the application utilizes a split view layout to optimize the
user interface. This layout consists of three primary columns:

1. **Primary (Left) Column:** This column contains a sidebar with various menu
items:
   - Account Image (navigates to the user's profile view)
   - All Conversations
   - Filtered Conversations (favorites, groups, 1:1 conversations)
   - Archived Conversations
   - Connect/Start Conversation
   - Settings

2. **Supplementary (Middle) Column:** This column displays content related to
the selected menu item from the sidebar, such as the list of conversations, the
connect/start conversation interface, or the settings view.

3. **Secondary (Right) Column:** This column hosts the conversation content,
showing the details of the selected conversation.

### Adaptive Layout for Compact Screens

When the application is presented on screens with less horizontal space
(compact horizontal size class), the split view controller automatically
collapses to display only a single view controller at a time. Depending on the
user's interaction, this view controller could be any of the three columns or a
separate "compact" column.

However, since the `UISplitViewController` in this scenario hosts a
`UITabBarController` exclusively in the compact column, navigation and layout
adjustments must be managed manually. To maintain a clean and organized
approach, this logic has been encapsulated within the ``MainCoordinator`` class.

### Navigation and Layout Behavior

Upon successful authentication, the application defaults to displaying the
conversation list. Accordingly, the `UISplitViewController` starts in an
expanded state. The ``MainCoordinator`` is designed with this in mind, expecting
the conversation list view controller to be initialized within the provided
``MainSplitViewController``, while all other view controllers are managed by the
``MainTabBarController``.

When navigating between different sections such as the conversation archive,
settings, or starting a new conversation, the ``MainCoordinator`` handles the
transition by moving the currently displayed view controller into the tab bar
controller. The requested view controller is then moved from the tab bar
controller into the split view controller, ensuring a smooth transition between
different sections.

During a layout collapse (when the app transitions to a compact horizontal size
class), the ``MainCoordinator`` will move the currently active view controller
to the tab bar controller. Additionally, the start conversation view controller
will be presented modally to maintain user accessibility and workflow
continuity. 

This design ensures a seamless user experience across various device sizes and
orientations, with the `MainCoordinator` effectively managing the complex
transitions and layout changes required by the application.

## Topics
