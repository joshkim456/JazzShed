import Foundation

/// Loads and provides access to the tune library from bundled JSON files.
final class TuneLibrary {
    static let shared = TuneLibrary()

    private(set) var tunes: [Tune] = []

    private init() {
        loadBundledTunes()
    }

    /// Returns a tune by ID.
    func tune(id: String) -> Tune? {
        tunes.first { $0.id == id }
    }

    /// Returns tunes sorted by title.
    var tunesByTitle: [Tune] {
        tunes.sorted { $0.title < $1.title }
    }

    private func loadBundledTunes() {
        guard let tunesURL = Bundle.main.url(forResource: "Tunes", withExtension: nil) else {
            // Fall back: try loading individual files from root resources
            loadIndividualTuneFiles()
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: tunesURL,
                includingPropertiesForKeys: nil
            )
            let jsonFiles = contents.filter { $0.pathExtension == "json" }

            for file in jsonFiles {
                if let tune = loadTune(from: file) {
                    tunes.append(tune)
                }
            }
        } catch {
            loadIndividualTuneFiles()
        }
    }

    private func loadIndividualTuneFiles() {
        let tuneFiles = [
            "autumn-leaves", "blue-bossa", "all-the-things",
            "all-of-me", "beautiful-love", "blues-for-alice",
            "confirmation", "donna-lee", "solar", "fly-me-to-the-moon"
        ]

        for name in tuneFiles {
            if let url = Bundle.main.url(forResource: name, withExtension: "json"),
               let tune = loadTune(from: url) {
                tunes.append(tune)
            }
        }
    }

    private func loadTune(from url: URL) -> Tune? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Tune.self, from: data)
        } catch {
            print("Failed to load tune from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
}
