//
//  ContentView.swift
//  CatvsDogApp
//
//  Created by Mohammad Azam on 3/30/23.
//

import SwiftUI
import CoreML

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

struct ContentView: View {
    
    let images = ["cat94", "cat95", "dog355", "cat96", "cat97", "dog356", "dog359", "dog358"]
    var imageClassifier: CatvsDogImageClassifier?
    @State private var classLabel: String = ""
    @State private var probLabel: String = ""
    @State private var currentIndex = 0
    
    init() {
        do {
            imageClassifier = try CatvsDogImageClassifier(configuration: MLModelConfiguration())
        } catch {
            print(error)
        }
    }
    
    // https://www.hackingwithswift.com/whats-new-in-ios-11
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    var body: some View {
        VStack {
            Image(images[currentIndex])
            Button("Predict") {
                
                guard let uiImage = UIImage(named: images[currentIndex]) else { return }
                
                // resize the image to
                let resizedImage = uiImage.resized(to: CGSize(width: 299, height: 299))
                print(resizedImage)
                
                // buffer function from https://www.hackingwithswift.com/whats-new-in-ios-11
                guard let cvPixelBuffer = buffer(from: resizedImage) else { return }
                
                do {
                    let result = try imageClassifier?.prediction(image: cvPixelBuffer)
                    print(result?.classLabelProbs)
                    classLabel = result?.classLabel ?? ""
                } catch {
                    print(error.localizedDescription)
                }
                
            }.buttonStyle(.borderedProminent)
            
            Text(classLabel)
                .font(.largeTitle)
            
            Button("Next") {
                currentIndex += 1
            }
           .padding()
    }
}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
