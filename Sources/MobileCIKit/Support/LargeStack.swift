import Foundation

/// Runs recursive parsing on a thread with a known, large stack.
///
/// The YAML composer recurses once per nesting level (up to libyaml's limit of 1,000). The
/// threads of the Swift concurrency pool and of test runners have small stacks (512 KiB), so the
/// same document that parses on the main thread could overflow there. A dedicated thread makes
/// the outcome independent of the caller.
enum LargeStack {
    static let stackSize = 16 << 20

    static func run<Value>(_ work: @escaping @Sendable () -> Value) -> Value {
        let box = ResultBox<Value>()
        let done = DispatchSemaphore(value: 0)
        let thread = Thread {
            box.value = work()
            done.signal()
        }
        thread.stackSize = stackSize
        thread.start()
        done.wait()
        guard let value = box.value else {
            preconditionFailure("The worker thread finished without a result.")
        }
        return value
    }
}

/// Hands one value from the worker thread to the waiting thread; the semaphore orders the
/// write before the read.
private final class ResultBox<Value>: @unchecked Sendable {
    var value: Value?
}
