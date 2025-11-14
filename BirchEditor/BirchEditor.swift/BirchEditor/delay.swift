//
//  delay.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/7/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

/// Async delay function using structured concurrency.
/// Replaces legacy GCD-based delay with Swift Concurrency's Task.sleep.
///
/// - Parameter interval: The time interval in seconds to sleep
///
/// Example:
/// ```swift
/// await delay(0.5)
/// updateUI()
/// ```
@MainActor
func delay(_ interval: TimeInterval) async {
    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
}

/// Legacy GCD-based delay function for backwards compatibility.
/// Deprecated: Use async `delay(_ interval: TimeInterval)` instead.
///
/// This will be removed after all call sites are migrated to async/await.
@available(*, deprecated, message: "Use async delay(_ interval: TimeInterval) instead")
func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure
    )
}
