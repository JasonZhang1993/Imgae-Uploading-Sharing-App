
import UIKit
import AWSS3
import AWSCore
import AWSCognito
import AWSSNS
import ImageFormatInspector

class UploadViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate {
    
    var fileURL = URL(string: "")
    var ImgLink = URL(string: "")
    
    // initialize the cognito identity group
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ImgName.delegate = self
        self.ScrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        
        self.View_Button.isEnabled = false
        self.Progress_Bar.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        let point = CGPoint(x: 0, y: 100)
        
        ScrollView.setContentOffset(point, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        
        let point = CGPoint(x: 0, y: 0)
        
        ScrollView.setContentOffset(point, animated: true)
    }
    
    func dismissKeyboard() {
        self.ImgName.resignFirstResponder()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.status.text = "No image selected"
        self.Img_Sample.image = nil
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) { // get file directory

        if let url = info[UIImagePickerControllerReferenceURL] as? NSURL {
            let path = url.path!
            fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(path)
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                if let data = UIImageJPEGRepresentation(image, 0.8) {
                    do {
                        try data.write(to: fileURL!)
                    }
                    catch {}
                }
                else if let data = UIImagePNGRepresentation(image) {
                    do {
                        try data.write(to: fileURL!)
                    }
                    catch {}
                }
                else {
                    self.Img_Sample.image = nil
                    print("image MIME type unknown")
                    self.status.text = "No image selected"
                    return
                }
                
//                print("show image")
                self.Img_Sample.image = image
                print(fileURL!.absoluteString) // testing file diretory
                self.status.text = "Image Selected"
                
            }
            else {
                self.Img_Sample.image = nil
                print("image not obtained")
                self.status.text = "No image selected"
            }
        }
        else {
            self.Img_Sample.image = nil
            print("file directory not obtained")
            self.status.text = "No image selected"
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var ScrollView: UIScrollView!
    
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var Upload_Button: UIButton!
    
    @IBOutlet weak var View_Button: UIButton!
    
    @IBOutlet weak var ImgName: UITextField!
    
    @IBOutlet weak var Img_Sample: UIImageView!
    
    @IBOutlet weak var Progress_Bar: UIProgressView!
    
    
    @IBAction func Choose_Img_Action(_ sender: UIButton) { // choose the image from file system
        
        fileURL = URL(string: "")
        let image = UIImagePickerController()
        image.delegate = self
        
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        
        self.present(image, animated: true, completion: nil)
    }
    
    @IBAction func Upload_Action(_ sender: UIButton) { // upload the image through aws S3
        
        if self.fileURL == nil || self.fileURL!.absoluteString == "" {
            self.status.text = "No image choosen, please select an image."
            return
        }
        
        Upload_Button.isEnabled = false
        View_Button.isEnabled = false
        Progress_Bar.progress = 0.0
        Progress_Bar.isHidden = false
        self.status.text = "Uploading to S3..."
        ImgLink = URL(string: "")
        
        // get content type, key name, and bucket name
        let path = fileURL!.absoluteString
        let idx = path.range(of: ".", options: .backwards)?.lowerBound
        let type = path.substring(from: path.index(after: idx!)).lowercased()
        
        var key = self.ImgName.placeholder!
        if self.ImgName.text != nil && self.ImgName.text != "" {
            key = self.ImgName.text!
        }
        let keyPath = "\(AppInfo.prefix)/\(key).\(type)"
        let bucket = AppInfo.bucket_name
        let contentType = "image/\(type)"
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = { (task, progress) in
            DispatchQueue.main.async {
                self.Progress_Bar.progress = Float(progress.fractionCompleted)
            }
        }
        
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
            DispatchQueue.main.async {
                if let err = error {
                    print("error: \(err)")
                }
                else if self.Progress_Bar.progress != 1.0 {
                    print("Failed")
                }
                else {
                    self.view.showToast("Upload Success", position: .bottom, popTime: 2.0, dismissOnTap: true)
                    self.status.text = "Upload success, press \"View Image\" to view the image."
                    self.View_Button.isEnabled = true
                }
                self.Upload_Button.isEnabled = true
                self.Progress_Bar.isHidden = true
            }
        }
        
        // transfer utility
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.uploadFile(fileURL!, bucket: bucket, key: keyPath, contentType: contentType, expression: expression, completionHandler: completionHandler).continueWith {
            (task) -> AnyObject! in if let error = task.error {
                self.status.text = "error: localizedDescription"
                print("Error: \(error.localizedDescription)")
            }
            
            if let _ = task.result {
                // Do something with uploadTask.
                let url = AWSS3.default().configuration.endpoint.url
                self.ImgLink = url!.appendingPathComponent(bucket).appendingPathComponent(keyPath)
                
                self.push_Notification(image: "\(key).\(type)")
            }

            return nil;
        }
    }
    
    func push_Notification(image: String) {
        
        let pub = AWSSNSPublishInput.init()
        pub?.targetArn = AppInfo.myArn
        pub?.subject = "A New Image Shared To You!"
        
        let message = "A new image is uploaded to S3: \(image).\n You can view and download the image through: \n \(self.ImgLink!)"
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

    @IBAction func View_Img_Action(_ sender: UIButton) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(ImgLink!, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(ImgLink!)
        }
    }
}
