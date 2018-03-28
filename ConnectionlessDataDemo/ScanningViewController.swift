//
//  ViewController.swift
//  ConnectionlessDataDemo
//
//  Created by John on 3/21/18.
//  Copyright © 2018 KS Technologies, LLC. All rights reserved.
//

import UIKit

class ScanningViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
 
    var devices: [DemoDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BLEManager.shared.delegate = self
    }


    func reloadTable() {
        devices = Array(BLEManager.shared.discoveredDevices.values)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
}

extension ScanningViewController: BLEManagerDelegate {
    // MARK: - BLEManagerDelegate
    func didDiscover(device: DemoDevice) {
        reloadTable()
    }
}


extension ScanningViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - TableView Delegate/Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let thisDevice = devices[indexPath.row]
        cell.textLabel?.text = "\(thisDevice.peripheral.identifier)"
        cell.detailTextLabel?.text = "Accelerometer: \(thisDevice.latestAccelData?.description ?? "")"
        return cell
    }
}
