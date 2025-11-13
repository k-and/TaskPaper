//
//  File.swift
//  BirchOutline
//
//  Created by Jesse Grosjean on 7/6/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation
@preconcurrency import JavaScriptCore

// MainActor isolated - JSValue extension calls JavaScript dispose method
@MainActor
public protocol DisposableType: AnyObject {

    func dispose()

}

extension JSValue: DisposableType {

    public func dispose() {
        invokeMethod("dispose", withArguments: [])
    }
    
}
