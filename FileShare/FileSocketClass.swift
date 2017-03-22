//
//  FileSocketClass.swift
//  FileShare
//
//  Created by 吴子鸿 on 2016/12/27.
//  Copyright © 2016年 吴子鸿. All rights reserved.
//

import Foundation


class FileSocketClass:NSObject, GCDAsyncSocketDelegate {
    let serverPort:UInt16 = 9998        //服务器端口号
    var serverIP:String = ""
    var clientSocket:GCDAsyncSocket!    //tcp连接对象
    var isconnected:Bool = false
    
    var filename:String!
    var filesize:Int!
    var fileyuansize:Int = 0
    var filepath:String = ""
    var documentPath:String!
    var fileData:Data!
    
    var showAlert={       //显示提示窗口
        (msg:String) in
    }
    var setprogress={
        (x:Float) in
    }
    

    func fileSocketinit(filename:String,filesize:Int,serverIP:String)
    {
        self.filename = filename
        self.filesize = filesize
        self.fileyuansize = filesize
        self.serverIP = serverIP
        let documentPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        documentPath = documentPaths[0]
        self.filepath = documentPath + "/"+filename
        fileData = Data()
        fileData.removeAll()
        print(filepath)
    }
    
    func connectServer() {
        print("file测试连接开始")
        do {
            clientSocket = GCDAsyncSocket()
            clientSocket.delegate = self
            clientSocket.delegateQueue = DispatchQueue.global()
            try clientSocket.connect(toHost: serverIP, onPort: serverPort)
        }
        catch {
            print("error")
        }
    }

    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) -> Void {
        print("file连接成功")
        
        clientSocket.readData(withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print ("file与服务器断开连接")
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) -> Void {
        // 1 获取客户的发来的数据 ，把 NSData 转 NSString
        let readClientDataString:NSString? = NSString(data: data as Data, encoding:String.Encoding.utf8.rawValue)
        var str:String = ""
        if (readClientDataString != nil)
        {
            str=String(readClientDataString!)
            print("receive:\(str)"+"9998")
        }
        fileData.append(data)
        filesize=filesize-data.count
        print (filesize)
        let p = Float(fileyuansize-filesize)*1.0/Float(fileyuansize)
        setprogress(p)
        if (filesize == 0)
        {
            do {
                //try data.write(to: URL(fileURLWithPath: filepath), options: .atomicWrite)
                try fileData.write(to: URL(fileURLWithPath: filepath))
                self.showAlert("文件下载完成")
            } catch {
                // error异常的对象
                print(error)
            }

            self.clientSocket.disconnect()
        }
        else
        {
            // 4每次读完数据后，都要调用一次监听数据的方法
            clientSocket.readData(withTimeout: -1, tag:0)
        }
    }
    
    func sendMsg(msg:String) {        //发送数据
        // 1.处理请求，返回数据给客户端 ok
        let serviceStr:NSMutableString = NSMutableString()
        serviceStr.append(msg)
        print ("发送字符串:\(serviceStr)")
        clientSocket.write(serviceStr.data(using: String.Encoding.utf8.rawValue)!, withTimeout: -1, tag: 0)
        clientSocket.readData(withTimeout: -1, tag:0)
    }
    
}


