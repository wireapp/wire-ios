//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


extension IntegerClusterizer {
    static let messageCount = IntegerClusterizer(ranges: [
        ClusterRange(0, 100),
        ClusterRange(100, 250),
        ClusterRange(250, 500),
        ClusterRange(500, 1_000),
        ClusterRange(1_000, 2_000),
        ClusterRange(2_000, 3_000),
        ClusterRange(3_000, 4_000),
        ClusterRange(4_000, 5_000),
        ClusterRange(5_000, 7_500),
        ClusterRange(7_500, 10_000),
        ClusterRange(10_000, 15_000),
        ClusterRange(15_000, 20_000),
        ClusterRange(20_000, 30_000),
        ClusterRange(30_000, 40_000),
        ClusterRange(40_000, 75_000),
        ClusterRange(75_000, 150_000),
        ClusterRange(150_000, 300_000),
        ClusterRange(300_000, 500_000),
        ClusterRange(500_000, 1_000_000),
        ClusterRange(1_000_000, 2_000_000),
        ClusterRange(2_000_000, 5_000_000),
        ClusterRange(5_000_000, 10_000_000),
        ClusterRange(10_000_000, 50_000_000),
        ClusterRange(50_000_000, 100_000_000),
        ClusterRange(100_000_000, 1_000_000_000)
    ])

    static let databaseSize = IntegerClusterizer(ranges: [
        ClusterRange(0, 5),
        ClusterRange(5, 10),
        ClusterRange(10, 25),
        ClusterRange(25, 50),
        ClusterRange(50, 100),
        ClusterRange(100, 200),
        ClusterRange(200, 500),
        ClusterRange(500, 1_000),
        ClusterRange(1_000, 2_000),
        ClusterRange(2_000, 3_000),
        ClusterRange(3_000, 4_000),
        ClusterRange(4_000, 5_000),
        ClusterRange(5_000, 10_000),
        ClusterRange(10_000, 15_000),
        ClusterRange(15_000, 20_000)
        ])

}
