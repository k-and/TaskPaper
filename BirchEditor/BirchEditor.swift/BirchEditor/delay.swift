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
/// - Parameter duration: The duration to sleep
///
/// Example:
/// ```swift
/// await delay(.milliseconds(500))
/// updateUI()
/// ```
@MainActor
func delay(_ duration: Duration) async {
    try? await Task.sleep(for: duration)
}

/// Legacy GCD-based delay function for backwards compatibility.
/// Deprecated: Use async `delay(_ duration: Duration)` instead.
///
/// This will be removed after all call sites are migrated to async/await.
@available(*, deprecated, message: "Use async delay(_ duration: Duration) instead")
func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure
    )
}
