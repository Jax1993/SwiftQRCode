//
//  QRCode.swift
//  Jax
//
//  Created by wangjh on 2018/4/19.
//  Copyright © 2018年 Flozy. All rights reserved.
//

import UIKit
import AVFoundation

open class QRCode: NSObject {
    
    var completedCallBack: ((_ stringValue: String) -> ())?
    open var scanFrame: CGRect = CGRect.zero
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }()
    lazy var session = AVCaptureSession()
    lazy var videoInput: AVCaptureDeviceInput? = {
        if let device = AVCaptureDevice.default(for: AVMediaType.video) {
            return try? AVCaptureDeviceInput(device: device)
        }
        return nil
    }()
    lazy var dataOutput = AVCaptureMetadataOutput()
    
    public override init() {
        super.init()
    }
    
    deinit {
        if session.isRunning {
            session.stopRunning()
        }
        previewLayer.removeFromSuperlayer()
    }
}

// MARK: - Generate QRCode Image
extension QRCode {
    ///  generate image
    ///
    ///  - parameter stringValue: string value to encoe
    ///  - parameter avatarImage: avatar image will display in the center of qrcode image
    ///  - parameter avatarScale: the scale for avatar image, default is 0.25
    ///
    ///  - returns: the generated image
    class open func generateImage(_ stringValue: String, avatarImage: UIImage?, avatarScale: CGFloat = 0.25) -> UIImage? {
        return generateImage(stringValue, avatarImage: avatarImage, avatarScale: avatarScale, color: CIColor(color: UIColor.black), backColor: CIColor(color: UIColor.white))
    }
    
    ///  Generate Qrcode Image
    ///
    ///  - parameter stringValue: string value to encoe
    ///  - parameter avatarImage: avatar image will display in the center of qrcode image
    ///  - parameter avatarScale: the scale for avatar image, default is 0.25
    ///  - parameter color:       the CI color for forenground, default is black
    ///  - parameter backColor:   th CI color for background, default is white
    ///
    ///  - returns: the generated image
    class open func generateImage(_ stringValue: String, avatarImage: UIImage?, avatarScale: CGFloat = 0.25, color: CIColor, backColor: CIColor) -> UIImage? {
        
        // generate qrcode image
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
        qrFilter.setDefaults()
        qrFilter.setValue(stringValue.data(using: String.Encoding.utf8, allowLossyConversion: false), forKey: "inputMessage")
        
        let ciImage = qrFilter.outputImage
        
        // scale qrcode image
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(ciImage, forKey: "inputImage")
        colorFilter.setValue(color, forKey: "inputColor0")
        colorFilter.setValue(backColor, forKey: "inputColor1")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let transformedImage = qrFilter.outputImage!.transformed(by: transform)
        
        let image = UIImage(ciImage: transformedImage)
        
        if avatarImage != nil {
            return insertAvatarImage(image, avatarImage: avatarImage!, scale: avatarScale)
        }
        
        return image
    }
    
    class func insertAvatarImage(_ codeImage: UIImage, avatarImage: UIImage, scale: CGFloat) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: codeImage.size.width, height: codeImage.size.height)
        UIGraphicsBeginImageContext(rect.size)
        
        codeImage.draw(in: rect)
        
        let avatarSize = CGSize(width: rect.size.width * scale, height: rect.size.height * scale)
        let x = (rect.width - avatarSize.width) * 0.5
        let y = (rect.height - avatarSize.height) * 0.5
        avatarImage.draw(in: CGRect(x: x, y: y, width: avatarSize.width, height: avatarSize.height))
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result!
    }
}

// MARK: - Decode message from UIImage
extension QRCode {
    class func decodeImage(_ image: UIImage) -> String? {
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            print("decodeImage CIDetector init error")
            return nil
        }
        guard let cgImage = image.cgImage else {
            print("decodeImage cgImage error")
            return nil
        }
        let ciImage = CIImage(cgImage: cgImage)
        let featureArr = detector.features(in: ciImage)
        guard let feature = featureArr.first else {
            print("decodeImage feature error")
            return nil
        }
        if feature is CIQRCodeFeature {
            let f = feature as! CIQRCodeFeature
            return f.messageString
        }
        return nil
    }
}

// MARK: - Video Scan
extension QRCode {
    ///  prepare scan
    ///
    ///  - parameter view:       the scan view, the preview layer and the drawing layer will be insert into this view
    ///  - parameter completion: the completion call back
    open func prepareScan(_ view: UIView, rectOfInterest: CGRect, completion:@escaping (_ stringValue: String)->()) {
        
        let w = view.bounds.width
        let h = view.bounds.height
        let width = w * rectOfInterest.width
        let x = w * (1-rectOfInterest.width)/2
        let y = h * (1-rectOfInterest.height)/2
        scanFrame = CGRect(x: x, y: y, width: width, height: width)
        dataOutput.rectOfInterest = rectOfInterest
        completedCallBack = completion
        setupSession()
        
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    /// start scan
    open func startScan() {
        if session.isRunning {
            print("the  capture session is running")
            
            return
        }
        session.startRunning()
    }
    
    /// stop scan
    open func stopScan() {
        if !session.isRunning {
            print("the capture session is not running")
            
            return
        }
        session.stopRunning()
    }
    
    func setupSession() {
        if session.isRunning {
            print("the capture session is running")
            return
        }
        
        if !session.canAddInput(videoInput!) {
            print("can not add input device")
            return
        }
        
        if !session.canAddOutput(dataOutput) {
            print("can not add output device")
            return
        }
        
        session.addInput(videoInput!)
        session.addOutput(dataOutput)
        
        dataOutput.metadataObjectTypes = dataOutput.availableMetadataObjectTypes;
        dataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRCode: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for dataObject in metadataObjects {
            
            guard let codeObject = dataObject as? AVMetadataMachineReadableCodeObject else { continue }
            guard let content = codeObject.stringValue else { continue }
            session.stopRunning()
            completedCallBack!(content)
        }
    }
}
