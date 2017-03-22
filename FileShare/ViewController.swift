//
//  ViewController.swift
//  FileShare
//
//  Created by 吴子鸿 on 2016/12/27.
//  Copyright © 2016年 吴子鸿. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var fileshowTable: UITableView!
    var refreshControl:UIRefreshControl = UIRefreshControl()    //刷新控件
    
    @IBOutlet weak var filepresentview: UIProgressView! //文件上传／下载进度条
    @IBOutlet weak var progresslabel: UILabel!
    
    let serverIP = "192.168.1.1"
    var msgsocket:SocketClass!
    var downfilesocket:FileSocketClass!
    var upfilesocket:UpFileSocketClass!
    var jshandle:JsonHandles!
    var tableData:[(String,Int)] = []       //表数据
    var nowpath:String=""
    var pathstack:[String] = [""]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        //进度条设置
        filepresentview.setProgress(0, animated: true)  //初始进度0
        filepresentview.isHidden = true
        progresslabel.text = ""
        //上传文件类初始化
        upfilesocket = UpFileSocketClass()
        upfilesocket.setIP(serverIP: serverIP)
        //注册cell到tableview中
        let cellNib = UINib(nibName: "TableFileCell", bundle: nil)
        fileshowTable.register(cellNib, forCellReuseIdentifier: "TableFileCell")
        
        jshandle = JsonHandles()
        jshandle.fileMsg = self.updateTableview
        msgsocket = SocketClass()
        msgsocket.socketinit(jshandle: jshandle,serverIP: serverIP)
        msgsocket.connectServer()
        
        
        self.downfilesocket = FileSocketClass()
        self.downfilesocket.showAlert = self.showAlert
        self.downfilesocket.setprogress = self.setprogress
        
        refreshControl.addTarget(self, action: #selector(refreshTable), for: UIControlEvents.valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "松手刷新")
        fileshowTable.addSubview(refreshControl)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshTable()
    {
        print ("刷新视图")
        self.msgsocket.updateLS(path: self.nowpath) //更新路径
        self.refreshControl.endRefreshing()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let num = indexPath.row
        let cell = self.fileshowTable.dequeueReusableCell(withIdentifier: "TableFileCell") as! TableFileCell
        cell.fileName.text = tableData[num].0
        if (tableData[num].1 >= 0)
        {
            //文件大小转处理
            var nams = "Byte"
            var size = Float(tableData[num].1)
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
        }
        else if (tableData[num].1 == -1)
        {
            cell.fileSize.text = "文件夹"
            cell.fileImage.image = #imageLiteral(resourceName: "folder")
        }
        else
        {
            cell.fileSize.text = "..."
            cell.fileImage.image = #imageLiteral(resourceName: "folder")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.fileshowTable.deselectRow(at: indexPath, animated: true)
        print (indexPath.row)
        let row = indexPath.row
        if (tableData[row].1 == -2) //返回上一级
        {
            pathstack.removeLast()
            nowpath = pathstack.last!
            self.msgsocket.updateLS(path: self.nowpath) //同时更新路径
        }
        else if (tableData[row].1 == -1)    //文件夹，进入下一级
        {
            nowpath = nowpath+"/"+tableData[row].0
            pathstack.append(nowpath)
            self.msgsocket.updateLS(path: self.nowpath) //同时更新路径
            
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let download = UITableViewRowAction(style: .normal, title: "同步到本地") { action, index in
            print("下载 button tapped")
            self.progresslabel.text = "下载进度:"
            self.filepresentview.isHidden = false
            let downloadjson:[String:Any] = [
                "TYPE": "DOWNLOAD",
                "PATH": self.nowpath,
                "NAME":"\(self.tableData[indexPath.row].0)"
            ]
            self.msgsocket.sendMsg(msg: self.jshandle.strToJson(jsondata: downloadjson))   //发送删除字符串
            
            
            self.downfilesocket.fileSocketinit(filename: self.tableData[indexPath.row].0,filesize:self.tableData[indexPath.row].1,serverIP: self.serverIP)
            self.downfilesocket.connectServer()
            //self.downfilesocket.test()
            
            
        }
        download.backgroundColor = UIColor.lightGray
        
        let delete = UITableViewRowAction(style: .normal, title: "删除") { action, index in
            print("删除 button tapped")
            
            let deletejson:[String:Any] = [
                "TYPE": "RMDIR",
                "PATH": self.nowpath,
                "NAME":"\(self.tableData[indexPath.row].0)"
            ]
            self.msgsocket.sendMsg(msg: self.jshandle.strToJson(jsondata: deletejson))   //发送删除字符串
            self.msgsocket.updateLS(path: self.nowpath) //同时更新路径
        }
        delete.backgroundColor = UIColor.red
        
        return [download, delete]
    }
    
    func uploadFile(filename:String,fileSize:Int)       //上传文件
    {
        var s = filename
        var index = s.characters.index(of: "/")
        if (index != nil)
        {
            index = s.characters.index(after: index!)
            s = s.substring(from: index!)
        }
        let uploadjson:[String:Any] = [
            "TYPE": "UPLOAD",
            "PATH":self.nowpath,
            "NAME":s,
            "SIZE":fileSize
        ]
        self.msgsocket.sendMsg(msg: self.jshandle.strToJson(jsondata: uploadjson))   //发送上传文件消息
        
    }
    
    
    @IBAction func localFileButton(_ sender: UIButton) {        //展示本地文件
        //实例化一个登陆界面
        let loginView = localFileView()
        loginView.uploadFile = uploadFile
        loginView.upfilesocket = self.upfilesocket
        //从下弹出一个界面作为登陆界面，completion作为闭包，可以写一些弹出loginView时的一些操作
        self.present(loginView, animated: true, completion: nil)

        
    }
    
    //新建文件夹
    @IBAction func newFileButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "请输入文件夹名称!", message:"", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (tField:UITextField!) -> Void in
            
            tField.placeholder = "输入文件夹名称"
            
        }
        let acOK = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (alertAction:UIAlertAction!) -> Void in
            print (1)
            let filename = alert.textFields![alert.textFields!.startIndex].text!
            if (filename != "")
            {
                let newjson:[String:Any] = [
                    "TYPE": "NEWDIR",
                    "PATH": self.nowpath,
                    "NAME": filename
                ]
                self.msgsocket.sendMsg(msg: self.jshandle.strToJson(jsondata: newjson))   //发送新建文件夹字符串
                self.msgsocket.updateLS(path: self.nowpath) //同时更新路径
                
            }
        }
        let acCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alertAction:UIAlertAction!) -> Void in
            print ("2")
        }
        alert.addAction(acOK)
        alert.addAction(acCancel)
        self.present(alert, animated: true, completion: nil)

    }
    
    func updateTableview(str:[(String,Int)])    //更新tableview中的数据
    {
        print ("刷新")
        tableData = str
        if nowpath != ""    //当前的tableview所属路径
        {
            tableData.insert(("返回上一级",-2), at: 0)
        }
        DispatchQueue.main.async(execute: { () -> Void in
            self.fileshowTable.reloadData()
        })
    }
    
    func showAlert(msg:String)
    {
        DispatchQueue.main.async(execute: { () -> Void in
            //下载进度隐藏
            self.progresslabel.text = ""
            self.filepresentview.isHidden = true
            self.filepresentview.setProgress(0, animated: true)
            let alert = UIAlertController(title: msg, message:nil, preferredStyle: UIAlertControllerStyle.alert)
            let acOK = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            alert.addAction(acOK)
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    func setprogress(x:Float)
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.filepresentview.setProgress(x, animated: true)
        })
    }

}

