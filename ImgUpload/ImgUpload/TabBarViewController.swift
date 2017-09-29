//
//  TabBarViewController.swift
//  ImgUpload
//
//  Created by Jason Zhang on 9/9/17.
//  Copyright © 2017 Jason Zhang. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    let del: UITabBarControllerDelegate = ScrollingTabBarControllerDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = del
        // Do any additional setup after loading the view.
    }
}
