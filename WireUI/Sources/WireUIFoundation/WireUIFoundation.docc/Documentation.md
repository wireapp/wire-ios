# ``WireUIFoundation``

Structural UI types like main container view controllers, the main coordinator
and more.

## Overview

This target is responsible for the navigation and user interface management
within the application after successfully logging in. It contains key classes
that coordinate the app's main flow and structure, including handling tab-based
and split-view navigation patterns.

## Concept

On large screens the application is presented using a split view layout. The
primary (left) column contains a sidebar with various menu items:
- Account Image (allows navigation to the self profile view controller) 
- All Conversations
- Filtered conversations (favorites, groups, 1:1 conversations)
- Archived conversations
- Connect/New Conversation
- Settings

The supplementary (middle) column will show the list of conversations, the
connect/new conversation or the settings view.

The secondary (right) column will host the conversation content.

When presented on less horizontal space (horizontal compact size class) the
split view controller collapses to presenting only a single view controller at
the time. It could theoretically be any of the three columns or another separate
column, the `compact` column.
However, since the `UISplitViewController` will host a `UITabBarController` only
in the `compact` column, handling the navigation and layout changes must be done
manually.
In order to pursue a clean approach the required logic has been extracted into
the class ``MainCoordinator``.

The application's default view after a successful authentication is the list of
conversations. The `UISplitViewController`'s default state is expanded.
For these two reasons the ``MainCoordinator`` expects the conversation list view
controller to be installed in the provided ``MainSplitViewController`` instance
and all other view controllers contained in the ``MainTabBarController`` object.

When navigating between the conversation archive, the settings or the start
conversation, the currently presented view controller will be moved into the tab
bar controller and the requested view controller moved from the tab bar
controller into the split view controller.

When the layout collapses, the currently presented view controller will also be
moved to the tab bar controller. The start conversation view controller will be
presented modally.

## Topics
