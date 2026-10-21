import Foundation

/// Polls habits.json and calls `onChange` when it's edited, replaced or removed. Polling a
/// file's date and size also catches editors that save by swapping in a new file, which
/// breaks file-descriptor watchers.
final class ConfigWatcher {
    static let interval: Duration = .seconds(2)

    private let url: URL
    private let onChange: () -> Void
    private var task: Task<Void, Never>?

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    func start() {
        task?.cancel()
        task = Task { [weak self, url] in
            var last = FileSignature(of: url)
            while true {
                do {
                    try await Task.sleep(for: Self.interval)
                } catch {
                    return // cancelled
                }
                let current = FileSignature(of: url)
                guard current != last else { continue }
                last = current
                self?.onChange()
            }
        }
    }
}
