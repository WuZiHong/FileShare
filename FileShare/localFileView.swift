//
//  localFileView.swift
//  FileShare
//
//  Created by 吴子鸿 on 2016/12/28.
//  Copyright © 2016年 吴子鸿. All rights reserved.
//

import UIKit

class localFileView: UIViewController,UITableViewDataSource,UITableViewDelegate,UIDocumentInteractionControllerDelegate {
    
    var uploadFile={       //文件上传
        (filename:String,filesize:Int) in
    }
    
    var upfilesocket:UpFileSocketClass!
    
    @IBOutlet weak var filepresentview: UIProgressView! //文件上传／下载进度条
    @IBOutlet weak var progresslabel: UILabel!


    @IBOutlet weak var localFileTable: UITableView!
    
    var fileArray:[String]!
    var filesizeArray:[Int] = []
    
    let fileManager = FileManager.default
    
    let documentPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)   //documentPath目录
    
    var documentController:UIDocumentInteractionController!  //文件查看
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //进度条设置
        filepresentview.setProgress(0, animated: true)  //初始进度0
        filepresentview.isHidden = true
        progresslabel.text = ""
    
        upfilesocket.showAlert = self.showAlert
        upfilesocket.setprogress = self.setprogress
        
        //注册cell到tableview中
        let cellNib = UINib(nibName: "TableFileCell", bundle: nil)
        localFileTable.register(cellNib, forCellReuseIdentifier: "TableFileCell")
        
        //文件查看设置
        documentController = UIDocumentInteractionController()
        //设置代理 --本应用内预览必须要添加代理UIDocumentInteractionControllerDelegate
        documentController.delegate = self;
        
        
        
        updateTabelView()   //刷新tableview
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setprogress(x:Float)
    {
        DispatchQueue.main.async(execute: { () -> Void in
            print ("yes\(x)")
            self.filepresentview.setProgress(x, animated: true)
        })
    }
    
    func updateTabelView()
    {
        fileArray = fileManager.subpaths(atPath:  documentPaths[0] )    //将documents路径下的东西给filearray
        print (fileArray.count)
        filesizeArray = []
        for i in 0..<fileArray.count
        {
            if fileArray[i] == "Inbox"
            {
                fileArray.remove(at: i)
                break
            }
        }
        for i in 0..<fileArray.count    //获取文件大小
        {
            let filePath = self.documentPaths[0]+"/"+fileArray[i]
            var fileSize : UInt64 = 0
            do {
                //return [FileAttributeKey : Any]
                let attr = try FileManager.default.attributesOfItem(atPath: filePath)
                fileSize = attr[FileAttributeKey.size] as! UInt64
                
                //if you convert to NSDictionary, you can get file size old way as well.
                let dict = attr as NSDictionary
                fileSize = dict.fileSize()
            } catch {
                print("Error: \(error)")
            }
            filesizeArray.append(Int(fileSize))
        }
        self.localFileTable.reloadData()
    }
    
    func showAlert(msg:String)
    {
        DispatchQueue.main.async(execute: { () -> Void in
            //上传进度隐藏
            self.progresslabel.text = ""
            self.filepresentview.isHidden = true
            self.filepresentview.setProgress(0, animated: true)
            let alert = UIAlertController(title: msg, message:nil, preferredStyle: UIAlertControllerStyle.alert)
            let acOK = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            alert.addAction(acOK)
            self.present(alert, animated: true, completion: nil)
        })
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ((fileArray) != nil)
        {
            return fileArray.count
        }
        else
        {
            return 0
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.localFileTable.dequeueReusableCell(withIdentifier: "TableFileCell") as! TableFileCell
        cell.fileName.text = fileArray[indexPath.row]
        var nams = "Byte"
        var size = Float(filesizeArray[indexPath.row])
        if (size > 1024)
        {
            size = size/1024
            nams = "KB"
        }
        if (size > 1024)
        {
            size = size/1024
            nams = "MB"
        }
        cell.fileSize.text = String(format:"%.2f",size)+nams
        cell.fileImage.image = #imageLiteral(resourceName: "file")
        return cell
    }
    //选择某一行后调用
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.localFileTable.deselectRow(at: indexPath, animated: true)
        documentController.url = URL(fileURLWithPath: self.documentPaths[0]+"/\(fileArray[indexPath.row])")
        //当前APP打开  需实现协议方法才可以完成预览功能
        if !documentController.presentPreview(animated: true)
        {
            print ("没有打开")
            documentController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let upload = UITableViewRowAction(style: .normal, title: "分享") { action, index in
            print("上传 button tapped")
            
            self.progresslabel.text = "上传进度:"
            self.filepresentview.isHidden = false
            print ("文件名称:\(self.fileArray[indexPath.row]),文件大小:\(self.filesizeArray[indexPath.row])")
            self.uploadFile(self.fileArray[indexPath.row], self.filesizeArray[indexPath.row])
            //self.testfile.test()
            self.upfilesocket.fileSocketinit(filename: self.fileArray[indexPath.row], filesize: self.filesizeArray[indexPath.row])
            self.upfilesocket.connectServer()
            
        }
        upload.backgroundColor = UIColor.lightGray
        
        let delete = UITableViewRowAction(style: .normal, title: "删除") { action, index in
            print("删除 button tapped")
            let cell = tableView.visibleCells[indexPath.row] as! TableFileCell
            let filepath = self.documentPaths[0]+"/"+cell.fileName.text!
            print (filepath)
            do {
                try self.fileManager.removeItem(atPath: filepath)
                self.updateTabelView()      //删除后更新视图
                print ("文件删除成功")
            } catch {
                // error异常的对象
                print(error)
            }
        }
        delete.backgroundColor = UIColor.red
        
        return [upload, delete]
    }

    @IBAction func backBtnClick(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    //文件预览需要实现如下代理方法
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        //这个地方需要返回给一个控制器用于展现documentController在其上面，所以我们就返回当前控制器self
        return self
    }
    
}
