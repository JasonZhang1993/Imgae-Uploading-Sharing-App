//
//  DownloadViewController.swift
//  ImgUpload
//
//  Created by Jason Zhang on 9/8/17.
//  Copyright © 2017 Jason Zhang. All rights reserved.
//

import UIKit
import AWSS3
import SwiftSpinner
import EasyToast

class DownloadViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var keySets = [String]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.Progress_Bar.isHidden = true
        self.status.text = "Choose imgae to download."
        refresh()
    }
    
    @IBOutlet weak var ListTable: UITableView!
    
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var Progress_Bar: UIProgressView!
    
    @IBAction func Refresh_Action(_ sender: UIButton) {
        refresh()
    }
    
    func refresh() {
        SwiftSpinner.show("Retieve data...")
        let s3 = AWSS3.s3(forKey: "USWest2s3")
        let listRequest = AWSS3ListObjectsRequest()
        listRequest?.bucket = AppInfo.bucket_name
        listRequest?.prefix = AppInfo.prefix + "/"
        
        s3.listObjects(listRequest!).continueWith { (task) -> AnyObject? in
            
            if let error = task.error {
                print("error: \(error)")
            }
            if let res = task.result?.contents {
                DispatchQueue.main.async {
                    self.dislpayData(objects: res)
                }
            }
            return nil
        }
        SwiftSpinner.hide()
    }
    
    func dislpayData(objects: [AWSS3Object]) {
        let len = AppInfo.prefix.characters.count + 1
        keySets = []
        for obj in objects {
            let path = obj.key!
            if path.characters.count == len {
                continue
            }
            let index = path.index(path.startIndex, offsetBy: len)
            let key = path.substring(from: index)
            keySets.append(key)
        }
        ListTable.reloadData()
    }
    
    func viewImage(sender: UIButton) {

        let indexPath = NSIndexPath(row: sender.tag, section: 0) as IndexPath
        let cell = ListTable.cellForRow(at: indexPath) as! FileListTableViewCell
        AppInfo.targetKey = cell.keyName.text!
        
        print(AppInfo.targetKey) // testing
    }
    
    func downloadImage(sender: UIButton) {
        
        self.Progress_Bar.progress = 0.0
        self.Progress_Bar.isHidden = false
        
        let indexPath = NSIndexPath(row: sender.tag, section: 0) as IndexPath
        let cell = self.ListTable.cellForRow(at: indexPath) as! FileListTableViewCell
        
        let key = AppInfo.prefix + "/" + cell.keyName.text!
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = { (task, progress) in
            DispatchQueue.main.async {
                self.Progress_Bar.progress = Float(progress.fractionCompleted)
            }
        }
        
        let completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { (task, location, data, error) -> Void in
            if let err = error {
                print("error: \(err)")
            }
            else if let data = data {
                let image = UIImage(data: data)
                UIImageWriteToSavedPhotosAlbum(image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.downloadData(fromBucket: AppInfo.bucket_name, key: key, expression: expression, completionHandler: completionHandler).continueWith { (task) -> AnyObject! in
            if let error = task.error {
                print("error: \(error)")
            }
            if let _ = task.result {
                print("download successfully")
            }
            return nil
        }
        
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Saving error: \(error)")
        }
        else {
            print("Saved")
            DispatchQueue.main.async {
                self.status.text = "Download success. Image is saved in the album."
                self.Progress_Bar.isHidden = true
                self.view.showToast("Image Saved to Photos Album!", position: .bottom, popTime: 2.0, dismissOnTap: true)
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keySets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileListTableViewCell") as! FileListTableViewCell
        cell.keyName.text = self.keySets[indexPath.row]
        cell.View_Button.tag = indexPath.row
        cell.View_Button.addTarget(self, action: #selector(self.viewImage), for: .touchUpInside)
        cell.Download_Button.tag = indexPath.row
        cell.Download_Button.addTarget(self, action: #selector(self.downloadImage), for: .touchUpInside)
        
        return cell
    }

}
