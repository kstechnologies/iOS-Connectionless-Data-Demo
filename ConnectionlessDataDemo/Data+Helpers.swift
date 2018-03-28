//
//  Data+Helpers.swift
//  ConnectionlessDataDemo
//
//  Created by John on 3/26/18.
//  Copyright © 2018 KS Technologies, LLC. All rights reserved.
//

import Foundation

extension Data {
    /// Initializes an integer value starting from the offset with the number of bytes in the given type.
    /// Returns nil if there aren't enough bytes to initialize the given type.
    /// Example:
    ///
    /// let newInt16: Int16? = data.value(atOffset: 0) // returns an Int16? starting at byte index 0
    /// let newUInt8: UInt8? = data.value(atOffset: 2) // returns a UInt8? starting at byte index 2
    func value<T: ExpressibleByIntegerLiteral>(atOffset offset: Int) -> T? {
        // Make sure we have enough bytes left to initialize this integer type.
        guard (offset + MemoryLayout<T>.size) <= self.count else {
            return nil
        }
        // Since we know the offset and the integer size, we can build the range
        let range: Range<Data.Index> = offset..<(offset + MemoryLayout<T>.size)
        var value: T = 0
        _ = self.copyBytes(to: UnsafeMutableBufferPointer(start: &value, count: 1), from: range)
        return value
    }
    
    // I find myself using .utf8 encoding 99% of the time, so I made a helper function to shorten up that call.
    func utf8Value() -> String? {
        return String(data: self, encoding: .utf8)
    }
    
    /// Returns a string representation of the bytes. This is useful for decoding things like MAC address.
    ///
    /// Example:
    /// let newData = Data([0xA1, 0xB2, 0xC3])
    /// let newStr = newData.hexString() // "a1b2c3"
    func hexString(toUpperCase: Bool = false) -> String {
        let format = toUpperCase ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension FixedWidthInteger {
    /// Returns a Data representation of an integer value.
    ///
    /// Example:
    /// let newInt: Int8 = 42
    /// let newData = newInt.toData() // returns Data([0x2A])
    func toData() -> Data {
        let count = MemoryLayout.size(ofValue: self)
        var copyOfSelf = self
        let data = withUnsafePointer(to: &copyOfSelf) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count, {
                UnsafeBufferPointer(start: $0, count: count)
            })
        }
        return Data(data)
    }
    
    /// Returns a byte array representing an integer value.
    ///
    /// Example:
    /// let newInt: Int8 = 42
    /// let newByteArray = newInt.toBytes() // [0x2A]
    func toBytes() -> [UInt8] {
        let count = MemoryLayout.size(ofValue: self)
        var copyOfSelf = self
        let data = withUnsafePointer(to: &copyOfSelf) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count, {
                UnsafeBufferPointer(start: $0, count: count)
            })
        }
        return Array(data)
    }
}
