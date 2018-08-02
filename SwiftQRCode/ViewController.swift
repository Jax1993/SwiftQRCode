//
//  ViewController.swift
//  SwiftQRCode
//
//  Created by wangjh on 2018/8/2.
//  Copyright © 2018年 wangjh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scan = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.plain, target: self, action: #selector(didTapScan))
        navigationItem.rightBarButtonItem = scan
    }

    @objc func didTapScan() -> Void {
        let vc = ScanViewController()
        vc.scanResClosure = { (message) in
            print("xxxxxxxxxxxxxxxxxxxin ViewController: \(message)")
        }
        navigationController?.pushViewController(vc, animated: true)
    }

}

