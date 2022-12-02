//
//  ImagePicker.swift
//  Fourier
//
//  Created by Jack Finnis on 28/08/2021.
//

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage?) -> Void
        
        init(_ completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }
    }
}
