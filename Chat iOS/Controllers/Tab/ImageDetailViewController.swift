//
//  ImageDetailViewController.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 9/7/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageDisplayed: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var imageToBeDisplayed : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageDisplayed.image = imageToBeDisplayed
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.delegate = self
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
    }
    

    @IBAction func shareTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Action", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save Photo", style: .default, handler: { _ in
            self.savePhoto() }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageDisplayed
    }
    
    func savePhoto() {
        guard let selectedImage = imageDisplayed.image else {
            print("Image not found!")
            return
        }
        UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            showAlertWith(title: "Save error", message: error.localizedDescription)
        } else {
            showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
        }
    }
    
    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

}
