//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import SwiftUI

/// A small demo for implementing the split view with SwiftUI.
struct ThreeColumnSplitView: View {
    @State private var selectedTab: String? = "Tab 1"

    var body: some View {
        NavigationSplitView {
            // Sidebar Column
            List(selection: $selectedTab) {
                Text(verbatim: "Tab 1")
                    .tag("Tab 1")
                Text(verbatim: "Tab 2")
                    .tag("Tab 2")
                Text(verbatim: "Tab 3")
                    .tag("Tab 3")
            }
            .navigationTitle(Text(verbatim: "Sidebar"))
            .frame(minWidth: 100) // Width of the sidebar
        } content: {
            // Middle Content Column (Based on Tab Selection)
            TabView(selection: $selectedTab) {
                NavigationStack {
                    VStack {
                        Text(verbatim: "Tab 1 Content")
                        NavigationLink {
                            Text(verbatim: "Detail View 1")
                        } label: {
                            Text(verbatim: "Go to Detail 1")
                        }
                    }
                    .navigationTitle(Text(verbatim: "Tab 1"))
                }
                .tag("Tab 1")
                .tabItem {
                    Label {
                        Text(verbatim: "Tab 2")
                    } icon: {
                        Image(systemName: "2.circle")
                    }
                }

                NavigationStack {
                    VStack {
                        Text(verbatim: "Tab 2 Content")
                        NavigationLink {
                            Text(verbatim: "Detail View 2")
                        } label: {
                            Text(verbatim: "Go to Detail 2")
                        }
                    }
                    .navigationTitle(Text(verbatim: "Tab 2"))
                }
                .tag("Tab 2")
                .tabItem {
                    Label {
                        Text(verbatim: "Tab 2")
                    } icon: {
                        Image(systemName: "2.circle")
                    }
                }

                NavigationStack {
                    VStack {
                        Text(verbatim: "Tab 3 Content")
                        NavigationLink {
                            Text(verbatim: "Detail View 3")
                        } label: {
                            Text(verbatim: "Go to Detail 3")
                        }
                    }
                    .navigationTitle(Text(verbatim: "Tab 3"))
                }
                .tag("Tab 3")
                .tabItem {
                    Label {
                        Text(verbatim: "Tab 3")
                    } icon: {
                        Image(systemName: "3.circle")
                    }
                }
            }
            .frame(maxWidth: .infinity) // Allows the TabView to take up the space needed
        } detail: {
            // Right Column: Static or Detail Content
            Text(verbatim: "Right Column Text")
                .font(.title)
                .padding()
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct ThreeColumnSplitView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            ThreeColumnSplitView()
        } else {
            Text(verbatim: "")
        }
    }
}
