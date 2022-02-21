import UIKit
import Flutter

struct PixelData {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: "samples.flutter.dev/image", binaryMessenger: controller.binaryMessenger)
        
        methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if call.method == "crop" {
                let arguments = call.arguments as! [Any]
                let byteData = (arguments[0] as! FlutterStandardTypedData).data
                let width = arguments[1] as! Int
                let height = arguments[2] as! Int
                let dx = arguments[3] as! Double
                let dy = arguments[4] as! Double
                let cropWidth = arguments[5] as! Double
                let cropHeight = arguments[6] as! Double
                
                var pixelDataArray = [PixelData]()
                var index = 0
                while (index + 3 < byteData.count) {
                    pixelDataArray.append(
                        .init(r: byteData[index],
                              g: byteData[index + 1],
                              b: byteData[index + 2],
                              a: byteData[index + 3])
                    )
                    index += 4
                }
                
                
                let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
                let bitsPerComponent = 8
                let bitsPerPixel = 32
                
                //                assert(pixels.count == Int(width * height))
                
                let providerRef = CGDataProvider(
                    data: NSData(bytes: &pixelDataArray, length: pixelDataArray.count * MemoryLayout<PixelData>.size)
                )
                guard let cgImage = CGImage(
                    width: width,
                    height: height,
                    bitsPerComponent: bitsPerComponent,
                    bitsPerPixel: bitsPerPixel,
                    bytesPerRow: width * MemoryLayout<PixelData>.size,
                    space: rgbColorSpace,
                    bitmapInfo: bitmapInfo,
                    provider: providerRef!,
                    decode: nil,
                    shouldInterpolate: true,
                    intent: .defaultIntent
                ) else {
                    return
                }
                
                var img = UIImage(cgImage: cgImage)
                try! img.pngData()?.write(to: URL.init(fileURLWithPath: "/tmp/test.png"))
                
                let cropCGImage = cgImage.cropping(to: .init(x: dx, y: dy, width: cropWidth, height: cropHeight))
                img = UIImage(cgImage: cropCGImage!)
                try! img.pngData()?.write(to: URL.init(fileURLWithPath: "/tmp/test2.png"))
                print(img)
                //                let data = (call.arguments as! FlutterStandardTypedData).data
                //                let image = UIImage(data: data)
                //                let cgImage = image?.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: 10, height: 10))
                //                guard let cgImage = cgImage else {
                //                    result(nil)
                //                    return
                //                }
                //                let newImage = UIImage(cgImage: cgImage)
                //                let typedData = FlutterStandardTypedData(bytes: newImage.pngData()!)
                //                result(typedData)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
