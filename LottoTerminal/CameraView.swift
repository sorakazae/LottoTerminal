//
//  CameraView.swift
//  LottoTerminal
//
//  Created by sorak azae on 7/10/25.
//


import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var scannedCode: String

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }

    class Coordinator: NSObject, QRCodeScannerDelegate {
        @Binding var scannedCode: String

        init(scannedCode: Binding<String>) {
            _scannedCode = scannedCode
        }

        func didFind(code: String) {
            scannedCode = code
        }
    }
}