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

import Combine
import SwiftUI
import UIKit

struct CallingContainerView: View {

    @ObservedObject var viewModel: CallingContainerViewModel
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var panelSide: HorizontalEdge = UIDevice.current.twoDimensionOrientation == .landscapeRight ? .leading : .trailing
    @State private var isReactionsTrayOpen = false

    private var landscapePanelWidth: CGFloat {
        let base = CallPanelView.handleWidth + CallPanelView.buttonsColumnWidth + CallPanelView.participantsColumnWidth
        return base + (isReactionsTrayOpen ? CallPanelView.buttonsColumnWidth : 0)
    }
    private var landscapeCollapsedWidth: CGFloat {
        CallPanelView.handleWidth + CallPanelView.buttonsColumnWidth
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            VStack(spacing: 0) {
                CallHeaderBar(
                    configuration: viewModel.callInfoConfiguration,
                    onMinimize: viewModel.onHideCallView
                )
                ZStack(alignment: .topLeading) {
                    CallViewControllerRepresentable(viewModel: viewModel)
                        .id(viewModel.voiceChannelRevision)
                        .ignoresSafeArea()
                    if isLandscape {
                        landscapePanel(geo: geo)
                    } else {
                        portraitPanel(geo: geo)
                    }
                }
            }
            .onChange(of: isLandscape) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                    dragOffset = 0
                    isReactionsTrayOpen = false
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            panelSide = UIDevice.current.twoDimensionOrientation == .landscapeRight ? .leading : .trailing
        }
    }

    // MARK: - Portrait panel

    private func portraitPanel(geo: GeometryProxy) -> some View {
        let peekHeight = CallPanelView.handleHeight + CallPanelView.buttonsRowHeight + geo.safeAreaInsets.bottom
        let maxHeight = geo.size.height * 0.7
        let travel = maxHeight - peekHeight
        let trayShift = isReactionsTrayOpen ? CallPanelView.emojiTrayHeight : 0
        let currentOffset = isExpanded ? 0 : (travel - trayShift)
        let effectiveDrag = viewModel.isPanEnabled ? dragOffset : 0

        return VStack(spacing: 0) {
            Spacer()
            CallPanelView(viewModel: viewModel, isExpanded: $isExpanded, isReactionsTrayOpen: $isReactionsTrayOpen, layout: .portrait)
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

    // MARK: - Landscape panel

    private func landscapePanel(geo: GeometryProxy) -> some View {
        let travel = CallPanelView.participantsColumnWidth
        let currentOffset = isExpanded ? 0 : (panelSide == .trailing ? travel : -travel)
        let effectiveDrag = viewModel.isPanEnabled ? dragOffset : 0

        return HStack(spacing: 0) {
            if panelSide == .trailing { Spacer() }
            CallPanelView(viewModel: viewModel, isExpanded: $isExpanded, isReactionsTrayOpen: $isReactionsTrayOpen, layout: .landscape(side: panelSide))
                .frame(width: landscapePanelWidth, height: geo.size.height)
                .offset(x: currentOffset + effectiveDrag)
                .clipped()
                .gesture(viewModel.isPanEnabled ? landscapeDragGesture(travel: travel) : nil)
            if panelSide == .leading { Spacer() }
        }
        .ignoresSafeArea()
    }

    private func landscapeDragGesture(travel: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let t = value.translation.width
                if panelSide == .trailing {
                    dragOffset = isExpanded ? max(0, min(travel, t)) : max(-travel, min(0, t))
                } else {
                    dragOffset = isExpanded ? max(-travel, min(0, t)) : max(0, min(travel, t))
                }
            }
            .onEnded { value in
                let t = value.translation.width
                let velocity = value.predictedEndTranslation.width - value.translation.width
                let shouldExpand: Bool
                if panelSide == .trailing {
                    shouldExpand = isExpanded ? (t < travel / 2 && velocity < 1000) : (t < -(travel / 2) || velocity < -1000)
                } else {
                    shouldExpand = isExpanded ? (t > -(travel / 2) && velocity > -1000) : (t > travel / 2 || velocity > 1000)
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = shouldExpand
                    dragOffset = 0
                }
            }
    }
}
