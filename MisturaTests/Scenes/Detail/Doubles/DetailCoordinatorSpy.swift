import Foundation
@testable import Mistura

final class DetailCoordinatorSpy: DetailCoordinatorDelegate {
    private(set) var openedLinks: [URL] = []

    func openExternalLink(_ url: URL) {
        openedLinks.append(url)
    }
}
