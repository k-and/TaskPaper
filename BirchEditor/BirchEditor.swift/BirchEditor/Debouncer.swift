//
//  Debouncer.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/5/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

/// Actor-based debouncer using Swift Concurrency.
/// Ensures thread-safe debouncing with automatic cancellation of pending tasks.
///
/// Example:
/// ```swift
/// let debouncer = Debouncer(delay: 0.5) {
///     print("Debounced action")
/// }
/// await debouncer.call()
/// ```
actor Debouncer {
    private var task: Task<Void, Never>?
    private let callback: @Sendable @MainActor () -> Void
    private let delay: TimeInterval

    /// Creates a new debouncer with the specified delay and callback.
    /// - Parameters:
    ///   - delay: Time interval in seconds to wait before executing callback
    ///   - callback: Sendable closure to execute on MainActor after delay
    init(delay: TimeInterval, callback: @escaping @Sendable @MainActor () -> Void) {
        self.delay = delay
        self.callback = callback
    }

    /// Triggers the debouncer. Cancels any pending execution and schedules a new one.
    func call() {
        task?.cancel()
        task = Task { @MainActor [callback, delay] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                callback()
            }
        }
    }

    /// Cancels any pending execution.
    func cancel() {
        task?.cancel()
        task = nil
    }
}

/// Legacy Timer-based Debouncer for backwards compatibility.
/// Deprecated: Use Actor-based Debouncer with TimeInterval instead.
@available(*, deprecated, message: "Use Actor-based Debouncer(delay: TimeInterval, callback:) instead")
class LegacyDebouncer: NSObject {
    weak var timer: Timer?

    let callback: () -> Void
    let delay: Double

    init(delay: Double, callback: @escaping (() -> Void)) {
        self.delay = delay
        self.callback = callback
    }

    func call() {
        cancel()
        timer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(LegacyDebouncer.fire), userInfo: nil, repeats: false)
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }

    @objc func fire() {
        callback()
    }
}
