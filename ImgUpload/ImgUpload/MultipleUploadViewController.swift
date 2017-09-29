//
//  MultipleUploadViewController.swift
//  ImgUpload
//
//  Created by Jason Zhang on 9/18/17.
//  Copyright © 2017 Jason Zhang. All rights reserved.
//

import UIKit
import YangMingShan
import AWSS3
import AWSSNS
import ImageFormatInspector

class MultipleUploadViewController: UIViewController, YMSPhotoPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    var images: NSArray! = []
    var data: NSArray! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.CollectionView.register(UINib.init(nibName: "ImageViewCell", bundle: nil), forCellWithReuseIdentifier: "ImageCellIdentifier")
        
        self.status.text = "Please choose images to be uploaded. (Maximum of 5 images can be chosen)"
        self.Upload_Button.isEnabled = false
        self.Progress_Bar.isHidden = true
    }
    
    @IBOutlet weak var CollectionView: UICollectionView!
    
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var Upload_Button: UIButton!
    
    @IBOutlet weak var Progress_Bar: UIProgressView!
    
    
    @IBAction func Pick_Images_Action(_ sender: UIButton) {
        
        let pickerViewController = YMSPhotoPickerViewController.init()
        pickerViewController.numberOfPhotoToSelect = 5
        
        
        let customColor = UIColor.init(red: 64.0/255.0, green: 0.0, blue: 144.0/255.0, alpha: 1.0)
        let customCameraColor = UIColor.init(red: 86.0/255.0, green: 1.0/255.0, blue: 236.0/255.0, alpha: 1.0)
        
        pickerViewController.theme.titleLabelTextColor = UIColor.white
        pickerViewController.theme.navigationBarBackgroundColor = customColor
        pickerViewController.theme.tintColor = UIColor.white
        pickerViewController.theme.orderTintColor = customCameraColor
        pickerViewController.theme.cameraVeilColor = customCameraColor
        pickerViewController.theme.cameraIconColor = UIColor.white
        pickerViewController.theme.statusBarStyle = .lightContent
        
        self.yms_presentCustomAlbumPhotoView(pickerViewController, delegate: self)
    }
    
    @IBAction func Upload_Action(_ sender: UIButton) {
        
        self.Progress_Bar.progress = 0.0
        self.Progress_Bar.isHidden = false
        self.Upload_Button.isEnabled = false
        self.status.text = "Uploading to S3..."
        
        let bucket = AppInfo.bucket_name
        
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        
        let timeStamp = "\(year)_\(month)_\(day)_\(hour)_\(minute)_\(second)"
        
        let transferUtility = AWSS3TransferUtility.default()
        var ImageURLs = [URL]()
        
        for i in 0 ..< data.count {
            
            let imageData = data.object(at: i) as? Data
            let format = imageFormatForImageData(imageData!)
            var type = ""
            
            if format == ImageFormat.JPEG {
                type = "jpeg"
            }
            else if format == ImageFormat.PNG {
                type = "png"
            }
            else if format == ImageFormat.TIF {
                type = "tif"
            }
            else {
                print("MIME type not inspected")
                return
            }
            
            let contentType = "image/\(type)"
            let key = "\(AppInfo.prefix)/\(timeStamp)_Img\(i + 1).\(type)"
            
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = { (task, progress) in
                DispatchQueue.main.async {
                    self.Progress_Bar.progress += Float(progress.fractionCompleted) / Float(self.data.count)
                }
            }
            
            let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
                DispatchQueue.main.async {
                    if let err = error {
                        print("error: \(err)")
                        self.Progress_Bar.isHidden = true
                        self.Upload_Button.isEnabled = true
                    }
                    else {
                        print("upload sucess \(key)")
                        
                        let url = AWSS3.default().configuration.endpoint.url
                        ImageURLs.append(url!.appendingPathComponent(bucket).appendingPathComponent(key))
                        
                        if ImageURLs.count == self.data.count {
                            self.status.text = "Upload \(self.data.count) images successfully."
                            self.Progress_Bar.isHidden = true
                            self.Upload_Button.isEnabled = true
                            
                            self.push_Notification(urls: ImageURLs)
                        }
                    }
                }
            }
            
            transferUtility.uploadData(imageData!, bucket: bucket, key: key, contentType: contentType, expression: expression, completionHandler: completionHandler).continueWith {
                (task) -> AnyObject! in if let error = task.error {
                    self.status.text = "error: localizedDescription"
                    print("Error: \(error.localizedDescription)")
                }
                
                if let _ = task.result {
                    // Do something with uploadTask.
                }
                
                return nil;
            }
        }
        
    }
    
    func push_Notification(urls: [URL]) {
        
        var links = String();
        for url: URL in urls {
            links.append(url.absoluteString)
            links.append("\n\n")
        }
        
        let pub = AWSSNSPublishInput.init()
        pub?.targetArn = AppInfo.myArn
        pub?.subject = "New Images Shared To You!"
        
        let message = "\(urls.count) new images are uploaded to S3.\n You can view and download the image through: \n\n\(links)"
        pub?.message = message
        
        let SNSClient = AWSSNS.default()
        SNSClient.publish(pub!).continueWith { (task) -> AnyObject! in
            if let error = task.error {
                print("error: \(error)")
            }
            if let _ = task.result {
                
            }
            return nil
        }
        
    }
    
    func photoPickerViewControllerDidReceivePhotoAlbumAccessDenied(_ picker: YMSPhotoPickerViewController!) {
        let alertController = UIAlertController(title: "Allow photo album access?", message: "Need your permission to access photo albums", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
        self.status.text = "No image are chosen."
        self.Upload_Button.isEnabled = false
    }
    
    func photoPickerViewControllerDidReceiveCameraAccessDenied(_ picker: YMSPhotoPickerViewController!) {
        let alertController = UIAlertController(title: "Allow camera album access?", message: "Need your permission to take a photo", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        }
        alertController.addAction(dismissAction)
        alertController.addAction(settingsAction)
        
        // The access denied of camera is always happened on picker, present alert on it to follow the view hierarchy
        picker.present(alertController, animated: true, completion: nil)
        self.status.text = "No image are chosen."
        self.Upload_Button.isEnabled = false
    }
    
    func photoPickerViewControllerDidCancel(_ picker: YMSPhotoPickerViewController!) {
        self.status.text = "No image are chosen."
        self.Upload_Button.isEnabled = false
        self.dismiss(animated: true, completion: nil)
    }
    
    func photoPickerViewController(_ picker: YMSPhotoPickerViewController!, didFinishPickingImages photoAssets: [PHAsset]!) {
        // Remember images you get here is PHAsset array, you need to implement PHImageManager to get UIImage data by yourself
        picker.dismiss(animated: true) {
            let imageManager = PHImageManager.init()
            let options = PHImageRequestOptions.init()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isSynchronous = true
            
            let mutableImages: NSMutableArray! = []
            let mutableData: NSMutableArray! = []
            
            for asset: PHAsset in photoAssets
            {
                let scale = UIScreen.main.scale
                let targetSize = CGSize(width: (self.CollectionView.bounds.width - 20 * 2) * scale, height: (self.CollectionView.bounds.height - 20 * 2) * scale)
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (image, infor) in
                    mutableImages.add(image!)
                })
                imageManager.requestImageData(for: asset, options: options, resultHandler: {
                    (data, _, _, info) in
                    mutableData.add(data!)
                })
                
            }
            // Assign to Array with images
            self.images = mutableImages.copy() as? NSArray
            self.data = mutableData.copy() as? NSArray
            
            self.status.text = "\(self.images.count) images are chosen. Press Upload to upload."
            self.Upload_Button.isEnabled = true
            
            self.CollectionView.reloadData()
        }
    }
    
    func deleteImage(_ sender: UIButton) {
        let mutableImages: NSMutableArray! = NSMutableArray.init(array: images)
        mutableImages.removeObject(at: sender.tag)
        
        let mutableData: NSMutableArray! = NSMutableArray.init(array: data)
        mutableData.removeObject(at: sender.tag)
        
        self.images = NSArray.init(array: mutableImages)
        self.data = NSArray.init(array: mutableData)
        
        if images.count == 0 {
            self.status.text = "No image are chosen."
            self.Upload_Button.isEnabled = false
        }
        else {
            self.status.text = "\(self.images.count) images are chosen. Press Upload to upload."
            self.Upload_Button.isEnabled = true
        }
        
        self.CollectionView.performBatchUpdates({
            self.CollectionView.deleteItems(at: [IndexPath.init(row: sender.tag, section: 0)])
        }, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ImageViewCell! = CollectionView.dequeueReusableCell(withReuseIdentifier: "ImageCellIdentifier", for: indexPath) as! ImageViewCell
        cell.ImageView.image = self.images.object(at: indexPath.row) as? UIImage
        
        cell.Delete_Button.tag = indexPath.row
        cell.Delete_Button.addTarget(self, action: #selector(self.deleteImage(_:)), for: .touchUpInside)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: CollectionView.bounds.width, height: CollectionView.bounds.height)
    }

}
