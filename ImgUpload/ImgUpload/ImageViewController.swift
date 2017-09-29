//
//  ImageViewController.swift
//  ImgUpload
//
//  Created by Jason Zhang on 9/9/17.
//  Copyright © 2017 Jason Zhang. All rights reserved.
//

import UIKit
import AWSS3

class ImageViewController: UIViewController {

    @IBOutlet weak var image: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title = "Image View"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let endpoint = AWSS3.default().configuration.endpoint.url
        let url = endpoint?.appendingPathComponent(AppInfo.bucket_name).appendingPathComponent(AppInfo.prefix).appendingPathComponent(AppInfo.targetKey)
        let data = NSData(contentsOf: url!)
        self.image.image = UIImage(data: data! as Data)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
