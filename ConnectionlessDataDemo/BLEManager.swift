//
//  BLEManager.swift
//  ConnectionlessDataDemo
//
//  Created by John on 3/21/18.
//  Copyright © 2018 KS Technologies, LLC. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BLEManagerDelegate: class {
    func didDiscover(device: DemoDevice)
}

class BLEManager: NSObject {
    // The advertised Unity service.
    static let unityService = CBUUID(string: "9AEF")

    // We use the Singleton pattern since it is necessary to interact with only one instance of CBCentralManager.
    static let shared = BLEManager()
    
    weak var delegate: BLEManagerDelegate?
    private let centralManager: CBCentralManager
    public var discoveredDevices: [UUID: DemoDevice] = [:]
    
    private override init() {
        let centralQueue = DispatchQueue(label: "com.kstechnologies.blequeue")
        centralManager = CBCentralManager(delegate: nil, queue: centralQueue)
        super.init()
        centralManager.delegate = self
    }
    
    // For demo purposes, we're calling this automatically once the central's state changes to poweredOn
    public func startScanning() {
        // We don't need to allow duplicates since the peripheral's advertised packet is dynamic. The default value of this key is false,
        // but we leave it here for convenience, in case we need to allow duplicates.
        let scanOptions: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        centralManager.scanForPeripherals(withServices: [BLEManager.unityService], options: scanOptions)
    }

}

extension BLEManager: CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            break
        case .poweredOff:
            break
        case .poweredOn:
            startScanning()
            break
        }
    }
    
    /*
     We're processing the peripheral in 3 steps:
     1. Get the didDiscover delegate callback.
     2. Unwrap the service data, check to see if the device type and packet type match what we're looking for. If so, unwrap the
        manufacturer data and call the next process function.
     3. Process the manufacturer data, then call our delegate function to pass the peripheral along with its latest data.
     */
    
    // 1
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        process(peripheral: peripheral, advData: advertisementData)
        
    }
    
    // 2
    func process(peripheral: CBPeripheral, advData: [String: Any]) {
        // Unwrap the service data dict, then the service data specific to 9AEF
        guard let serviceData = advData[CBAdvertisementDataServiceDataKey] as? [CBUUID: NSData],
            let unityServiceData = serviceData[BLEManager.unityService] as Data? else {
                return
        }
        // We have 9AEF service data. For this example, we're only going to process the devices with a GAP packet.
        guard unityServiceData.count > 7 else { return }
        // We all know that using '!' in production code is usually a bad idea, right?
        let deviceType: UInt8 = unityServiceData.value(atOffset: 6)!
        let packetType: UInt8 = unityServiceData.value(atOffset: 7)!
        // We're looking for device type 0, packet type 0
        guard deviceType == 0 && packetType == 0 else {
            return
        }
        // We know that this peripheral is they type we're looking for, so we can look for the manufacturer data now.
        if let unityManufacturerData = advData[CBAdvertisementDataManufacturerDataKey] as? Data {
            // We have manufacturer data
            process(manufacturerData: unityManufacturerData, for: peripheral)
        }
    }
    
    // 3
    func process(manufacturerData data: Data, for peripheral: CBPeripheral) {
        // Since we're using `!` below, let's at least make sure we have enough bytes
        guard data.count > 4 else { return }
        let accelX: Int16 = data.value(atOffset: 0)!
        let accelY: Int16 = data.value(atOffset: 2)!
        let accelZ: Int16 = data.value(atOffset: 4)!
        
        let accel = AccelerometerData(x: accelX, y: accelY, z: accelZ)
        print("Accel x: \(accelX) y: \(accelY) z: \(accelZ)")
        
        if let thisDevice = discoveredDevices[peripheral.identifier] {
            thisDevice.latestAccelData = accel
            delegate?.didDiscover(device: thisDevice)
        } else {
            let newDevice = DemoDevice(with: peripheral)
            newDevice.latestAccelData = accel
            discoveredDevices[peripheral.identifier] = newDevice
            delegate?.didDiscover(device: newDevice)
        }
    }
}

class DemoDevice: CBPeripheral {
    let peripheral: CBPeripheral
    var latestAccelData: AccelerometerData?
    
    init(with peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
}

struct AccelerometerData: CustomStringConvertible {
    let x: Double
    let y: Double
    let z: Double
    
    init(x: Int16, y: Int16, z: Int16) {
        self.x = AccelerometerData.processAccel(x)
        self.y = AccelerometerData.processAccel(y)
        self.z = AccelerometerData.processAccel(z)
    }
    
    static func processAccel(_ value: Int16) -> Double {
        let accelD = Double(value) / 16384.0
        return accelD
    }
    
    var description: String {
        return String(format: "x:%.2f y:%.2f z:%.2f", x, y, z)
    }
}



