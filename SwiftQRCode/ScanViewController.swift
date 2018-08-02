//
//  ScanViewController.swift
//  Jax
//
//  Created by wangjh on 2018/6/26.
//  Copyright © 2018年 Flozy. All rights reserved.
//

import UIKit
import AVFoundation

class ScanViewController: UIViewController {

    var scanResClosure: ((_ message: String) -> Void)?
    
    let scanner = QRCode()
    lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        return backgroundView
    }()
    
    var scanFrame: CGRect!
    var rectOfInterest: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Scan"
        view.backgroundColor = UIColor.white
        
        let item = UIBarButtonItem(title: "Photo", style: .plain, target: self, action: #selector(didTapLibrary))
        navigationItem.rightBarButtonItem = item
        
        let w = view.bounds.width
        let h = view.bounds.height
        let width = w * 0.7
        let x = w * 0.15
        let y = (h - width) * 0.3
        rectOfInterest = CGRect(x: 0.15, y: y/h, width: 0.7, height: w/h)
        scanFrame = CGRect(x: x, y: y, width: width, height: width)
        
        checkAuthStatusAndScan()
    }
    
    func addMaskLayer() -> Void {
        backgroundView.frame = view.bounds
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.addSubview(backgroundView)
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = kCAFillRuleEvenOdd
        let basicPath = UIBezierPath(rect: view.frame)
        let maskPath = UIBezierPath(rect: scanFrame)
        basicPath.append(maskPath)
        maskLayer.path = basicPath.cgPath
        backgroundView.layer.mask = maskLayer
    }
    
    func addCodeCorners() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = 0.5
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.path = UIBezierPath(rect: scanFrame).cgPath
        backgroundView.layer.addSublayer(shapeLayer)
    }
    
    func checkAuthStatusAndScan() -> Void {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (allowed) in
                DispatchQueue.main.async {
                    if allowed {
                        self.startScan()
                    } else {
                        self.showError(message: NSLocalizedString("camera_open_failed", comment: ""))
                    }
                }
            }
        } else if status == .authorized {
            startScan()
        } else {
            self.showError(message: NSLocalizedString("camera_open_failed", comment: ""))
        }
    }
    
    func startScan() -> Void {
        addMaskLayer()
        addCodeCorners()
        
        scanner.prepareScan(view, rectOfInterest: rectOfInterest) { [weak self]  (content) in
            print("scan res: " + content)
            self?.handleCodeScanResult(content: content)
        }
        scanner.startScan()
    }
    
    func handleCodeScanResult(content: String) -> Void {
        print("xxxxxxxxxxxxxxxxxxxresult: \(content)")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            guard let closure = self.scanResClosure else { return }
            closure(content)
        }
    }
    
    func showError(message: String) -> Void {
        print(message)
    }
    
    @objc func didTapLibrary() -> Void {
        let imagepicker = UIImagePickerController()
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            return
        }
        imagepicker.sourceType = .photoLibrary
        imagepicker.delegate = self
        imagepicker.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        present(imagepicker, animated: true, completion: nil)
    }
}

extension ScanViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] else {
            print("xxxxxxxxxxxxxxxxxxxUIImagePickerControllerOriginalImage error")
            picker.dismiss(animated: true, completion: nil)
            return
        }
        let smallImageData = UIImageJPEGRepresentation(image as! UIImage, 0.5)
        let smallImage = UIImage(data: smallImageData!)
        guard let content = QRCode.decodeImage(smallImage ?? image as! UIImage) else {
            print("xxxxxxxxxxxxxxxxxxxQRCode.decodeImage error")
            picker.dismiss(animated: true, completion: nil)
            return
        }
        self.handleCodeScanResult(content: content)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ScanViewController: UINavigationControllerDelegate {
    
}


