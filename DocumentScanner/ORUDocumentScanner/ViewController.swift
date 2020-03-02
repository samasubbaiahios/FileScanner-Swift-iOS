//
//  ViewController.swift
//  ORUDocumentScanner
//
//  Created by Venkata Subbaiah Sama on 13/01/20.
//  Copyright © 2020 Venkata. All rights reserved.
//

import UIKit
import Vision
import VisionKit
import PDFKit

class ViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func reconizeText(_ sender: Any) {
        setupVision()
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)

    }
    @IBAction func scanHere(_ sender: Any) {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
        
    }
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                
                detectedText += topCandidate.string
                detectedText += "\n"
            }
            
        }
        
        textRecognitionRequest.recognitionLevel = .accurate
    }
     private func recognizeTextInImage(_ image: UIImage) {
         guard let cgImage = image.cgImage else { return }
         
         textRecognitionWorkQueue.async {
             let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
             do {
                 try requestHandler.perform([self.textRecognitionRequest])
             } catch {
                 print(error)
             }
         }
     }

    private func processImage(_ image: UIImage) {
//        imageView.image = image
//        recognizeTextInImage(image)
    }
    
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        print("Found \(scan.pageCount)")
        let pdfDocument = PDFDocument()

        for i in 0 ..< scan.pageCount {
            let img = scan.imageOfPage(at: i)
            // ... your code here
            let pdfPage = PDFPage(image: img)
            pdfDocument.insert(pdfPage!, at: i)
        }
        let data = pdfDocument.dataRepresentation()
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let docURL = documentDirectory.appendingPathComponent("Scanned-Docs.pdf")
        do{
            print("Documet: \(docURL)")
            try data?.write(to: docURL)
        }catch(let error){
            print("error is \(error.localizedDescription)")
        }

//        let originalImage = scan.imageOfPage(at: 0)
//        let newImage = compressedImage(originalImage)
        controller.dismiss(animated: true)
//        processImage(newImage)
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
}

