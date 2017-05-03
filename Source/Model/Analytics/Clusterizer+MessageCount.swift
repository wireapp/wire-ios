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
        ClusterRange(500, 1000),
        ClusterRange(1000, 2000),
        ClusterRange(2000, 3000),
        ClusterRange(3000, 4000),
        ClusterRange(4000, 5000),
        ClusterRange(5000, 7500),
        ClusterRange(7500, 10000),
        ClusterRange(10000, 15000),
        ClusterRange(15000, 20000),
        ClusterRange(20000, 30000),
        ClusterRange(30000, 40000),
        ClusterRange(40000, 75000)
    ])

    static let databaseSize = IntegerClusterizer(ranges: [
        ClusterRange(0, 5),
        ClusterRange(5, 10),
        ClusterRange(10, 25),
        ClusterRange(25, 50),
        ClusterRange(50, 100),
        ClusterRange(100, 200),
        ClusterRange(200, 500),
        ClusterRange(500, 1000),
        ClusterRange(1000, 2000),
        ClusterRange(2000, 3000),
        ClusterRange(3000, 4000),
        ClusterRange(4000, 5000),
        ClusterRange(5000, 10000),
        ClusterRange(10000, 15000),
        ClusterRange(15000, 20000)
        ])

}
