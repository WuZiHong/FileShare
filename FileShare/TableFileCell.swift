//
//  TableFileCell.swift
//  FileShare
//
//  Created by 吴子鸿 on 2016/12/27.
//  Copyright © 2016年 吴子鸿. All rights reserved.
//

import UIKit

class TableFileCell: UITableViewCell {

    @IBOutlet weak var fileImage: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var fileSize: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        fileImage.contentMode = UIViewContentMode.scaleAspectFit
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
