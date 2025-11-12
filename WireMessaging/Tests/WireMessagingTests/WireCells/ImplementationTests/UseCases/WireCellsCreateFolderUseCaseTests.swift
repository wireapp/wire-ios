final class WireCellsCreateFolderUseCaseTests {

    private let repository = MockWireCellsNodesRepositoryProtocol()
    private let sut: WireCellsCreateFolderUseCase

    init() {
        self.sut = WireCellsCreateFolderUseCase(
            nodesRepository: repository