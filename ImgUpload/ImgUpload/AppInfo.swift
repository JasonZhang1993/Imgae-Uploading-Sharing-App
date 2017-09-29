//
//  AppInfo.swift
//  ImgUpload
//
//  Created by Jason Zhang on 9/8/17.
//  Copyright © 2017 Jason Zhang. All rights reserved.
//

import Foundation
import UIKit

class AppInfo : NSObject {
    
    static var myArn = "arn:aws:sns:us-west-2:535760150693:Image_Upload"
    static var bucket_name = "image-uploading-storage"
    static var prefix = "ImgUpload"
    static var targetKey = String()
}
