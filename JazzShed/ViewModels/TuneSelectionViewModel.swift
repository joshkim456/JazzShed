import Foundation
import Observation

@Observable
@MainActor
final class TuneSelectionViewModel {
    private(set) var tunes: [Tune] = []
    var searchText = ""

    init() {
        tunes = TuneLibrary.shared.tunesByTitle
    }

    var filteredTunes: [Tune] {
        if searchText.isEmpty { return tunes }
        return tunes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.composer.localizedCaseInsensitiveContains(searchText)
        }
    }
}
