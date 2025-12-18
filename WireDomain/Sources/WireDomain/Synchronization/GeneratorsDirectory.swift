//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

// sourcery: AutoMockable
public protocol GeneratorProtocol {
    func start() async
    func stop()
}

// sourcery: AutoMockable
/// Starts generating items during pulling pending events from backend
public protocol IncrementalGeneratorProtocol: GeneratorProtocol {}

// sourcery: AutoMockable
/// Starts generating items once the app is up to date (livesyncing)/
public protocol LiveGeneratorProtocol: GeneratorProtocol {}

/// Object that holds on all generators of WorkItem for WorkAgent

public final class GeneratorsDirectory {

    private let generators: [any GeneratorProtocol]
    private let syncStatePublisher: AnyPublisher<SyncState, Never>
    private var cancellables: Set<AnyCancellable> = []

    public init(generators: [any GeneratorProtocol], syncStatePublisher: AnyPublisher<SyncState, Never>) {
        self.generators = generators
        self.syncStatePublisher = syncStatePublisher
    }

    public func observeSyncState() {
        syncStatePublisher.sink { [weak self] state in
            switch state {
            case .idle, .initialSyncing:
                // make sure no generators are working here
                self?.stopGenerators()

            case .incrementalSyncing(.createPushChannel):
                self?.startIncrementalGenerators()

            case .incrementalSyncing:
                break // sync is ongoing, do nothing

            case .liveSyncing(.ongoing):
                self?.startLiveGenerators()

            case .suspended, .liveSyncing(.finished):
                self?.stopGenerators()
            }
        }.store(in: &cancellables)
    }

    private func startIncrementalGenerators() {
        for generator in generators where generator is IncrementalGeneratorProtocol {
            Task {
                await generator.start()
            }
        }
    }

    private func startLiveGenerators() {
        for generator in generators where generator is LiveGeneratorProtocol {
            Task {
                await generator.start()
            }
        }
    }

    private func stopGenerators() {
        for generator in generators {
            generator.stop()
        }
    }
}
