//
//  FileListTableViewCell.swift
//  ImgUpload
//
//  Created by Jason Zhang on 9/8/17.
//  Copyright © 2017 Jason Zhang. All rights reserved.
//

import UIKit

class FileListTableViewCell: UITableViewCell {

    @IBOutlet weak var keyName: UILabel!
    
    @IBOutlet weak var View_Button: UIButton!
    
    @IBOutlet weak var Download_Button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
