//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

struct CallingContainerView: View {

    @ObservedObject var viewModel: CallingContainerViewModel
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0

    private var landscapePanelWidth: CGFloat {
        LandscapeCallPanelView.handleWidth + LandscapeCallPanelView.buttonsColumnWidth + LandscapeCallPanelView.participantsColumnWidth
    }
    private var landscapeCollapsedWidth: CGFloat {
        LandscapeCallPanelView.handleWidth + LandscapeCallPanelView.buttonsColumnWidth
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            VStack(spacing: 0) {
                CallHeaderBarRepresentable(viewModel: viewModel)
                    .fixedSize(horizontal: false, vertical: true)
                ZStack(alignment: .topLeading) {
                    CallViewControllerRepresentable(viewModel: viewModel)
                        .id(viewModel.voiceChannelRevision)
                        .ignoresSafeArea()
                    if isLandscape {
                        landscapePanel(geo: geo)
                    } else {
                        portraitSheet(geo: geo)
                    }
                }
            }
            .onChange(of: isLandscape) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                    dragOffset = 0
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Portrait bottom sheet

    private func portraitSheet(geo: GeometryProxy) -> some View {
        let maxHeight = geo.size.height * 0.7
        let peekHeight = viewModel.peekHeight
        let travel = maxHeight - peekHeight
        let currentOffset = isExpanded ? 0 : travel
        let effectiveDrag = viewModel.isPanEnabled ? dragOffset : 0

        return VStack(spacing: 0) {
            Spacer()
            CallingActionsInfoRepresentable(viewModel: viewModel, isExpanded: $isExpanded)
                .frame(height: maxHeight)
                .offset(y: currentOffset + effectiveDrag)
                .gesture(viewModel.isPanEnabled ? portraitDragGesture(travel: travel) : nil)
        }
    }

    private func portraitDragGesture(travel: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let t = value.translation.height
                dragOffset = isExpanded ? max(0, min(travel, t)) : max(-travel, min(0, t))
            }
            .onEnded { value in
                let t = value.translation.height
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let shouldExpand: Bool
                if isExpanded {
                    shouldExpand = t < travel / 2 && velocity < 1000
                } else {
                    shouldExpand = t < -(travel / 2) || velocity < -1000
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = shouldExpand
                    dragOffset = 0
                }
            }
    }

    // MARK: - Landscape right panel

    private func landscapePanel(geo: GeometryProxy) -> some View {
        // travel = participantsColumnWidth: dragging left reveals participants, right collapses
        let travel = LandscapeCallPanelView.participantsColumnWidth
        let currentOffset = isExpanded ? 0 : travel
        let effectiveDrag = viewModel.isPanEnabled ? dragOffset : 0

        return HStack(spacing: 0) {
            Spacer()
            LandscapeCallPanelView(viewModel: viewModel, isExpanded: $isExpanded)
                .frame(width: landscapePanelWidth, height: geo.size.height)
                .offset(x: currentOffset + effectiveDrag)
                .clipped()
                .gesture(viewModel.isPanEnabled ? landscapeDragGesture(travel: travel) : nil)
        }
        .ignoresSafeArea()
    }

    private func landscapeDragGesture(travel: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let t = value.translation.width
                dragOffset = isExpanded ? max(0, min(travel, t)) : max(-travel, min(0, t))
            }
            .onEnded { value in
                let t = value.translation.width
                let velocity = value.predictedEndTranslation.width - value.translation.width
                let shouldExpand: Bool
                if isExpanded {
                    shouldExpand = t < travel / 2 && velocity < 1000
                } else {
                    shouldExpand = t < -(travel / 2) || velocity < -1000
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = shouldExpand
                    dragOffset = 0
                }
            }
    }
}
