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

import ActivityKit
import WidgetKit
import SwiftUI



struct BookedCabActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AssetAttributes.self) { context in
            // For devices that don't support the Dynamic Island.
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(context.attributes.name)")
                                .font(.headline)
                            Spacer()
                            Text("\(context.state.remainingTime)")
                                .font(.title)
                                .bold()
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.secondary)
                            HStack {
                                RoundedRectangle(cornerRadius: 15).fill(.blue).frame(width: 70)
                            }
                        }
                    }
                    Spacer()
                }.padding(5)
            }.padding(15)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {

                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.remainingTime)")
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing:10) {
                        Link(destination: URL(string: "tel:0000000000")!) {
                                                     Label("Contact driver", systemImage: "phone.circle.fill").padding()
                                                 }.background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 15)).font(.headline)
                        Button(action: { /*LiveActivityManager().CancelCab()*/ }) {
                            HStack {
                                Spacer()
                                Image(systemName: "xmark.circle.fill")
                                Text("Update Cab").font(.headline)
                                Spacer()
                            }.frame(height: 50)
                        }.tint(.white).background(.red).cornerRadius(15)
                    }.frame(maxWidth: UIScreen.main.bounds.size.width)
                }
            } compactLeading: {
                Label {
                    Text("\(context.state.remainingTime)")
                } icon: {
                    Image(systemName: "car")
                }
                .font(.caption2)
            } compactTrailing: {
                HStack(alignment: .center){

                }

            } minimal: {
                VStack(alignment: .center) {
                

                }
            }
            .keylineTint(.accentColor)
        }
    }
}

//@available(iOSApplicationExtension 16.2, *)
//struct BookACabLiveActivity_Previews: PreviewProvider {
//    static let attributes = AssetAttributes(customerName: "Deeksha", totalAmount: "Rs. 450")
//    static let contentState = AssetAttributes.ContentState(driverName: "Anmol", vechileNumber: "UP2456", estimatedReachTime: Date()...Date().addingTimeInterval(15 * 60))
//
//    static var previews: some View {
//        attributes
//            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
//            .previewDisplayName("Island Compact").previewDevice("iPhone 14 Pro Max")
//        attributes
//            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
//            .previewDisplayName("Island Expanded").previewDevice("iPhone 14 Pro Max")
//        attributes
//            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
//            .previewDisplayName("Minimal").previewDevice("iPhone 14 Pro Max")
//        attributes
//            .previewContext(contentState, viewKind: .content)
//            .previewDisplayName("Notification").previewDevice("iPhone 14 Pro Max")
//    }
//}

