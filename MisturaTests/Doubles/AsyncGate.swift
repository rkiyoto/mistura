final class AsyncGate {
    var isHeld = false

    private(set) var waitCount = 0
    private(set) var cancelledCount = 0

    private var pendingWaits: [AsyncStream<Void>.Continuation] = []

    func wait() async throws {
        waitCount += 1

        if isHeld {
            let stream = AsyncStream<Void> { pendingWaits.append($0) }
            for await _ in stream {}
        }

        do {
            try Task.checkCancellation()
        } catch {
            cancelledCount += 1
            throw error
        }
    }

    func release() {
        isHeld = false
        pendingWaits.forEach { $0.finish() }
        pendingWaits.removeAll()
    }
}
