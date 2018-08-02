# SwiftQRCode
___

A Swift library for generation and decoding of QRCode.

## Feature

- Swift4
- Generate and decode
- Both camera and photo decoding are supported

## Usage

### Generate

	let content = "https://google.com"
	if let codeImage = QRCode.generateImage(content, avatarImage: nil) {
            codeImgView.image = code
	}

### Decode
	
	//form camera
	let scanner = QRCode()
	scanner.prepareScan(view, rectOfInterest: rectOfInterest) { (content) in
		print("scan res: " + content)
	}
	scanner.startScan()
	
	//form photo
	let content = QRCode.decodeImage(smallImage ?? image as! UIImage)
        
## License

IbanUtilSwift is available under the MIT license. See the LICENSE file for more info.