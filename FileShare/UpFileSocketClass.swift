//
//  UpFileSocketClass.swift
//  FileShare
//
//  Created by 吴子鸿 on 2016/12/30.
//  Copyright © 2016年 吴子鸿. All rights reserved.
//

import Foundation
import EMFileStream

class UpFileSocketClass:NSObject, GCDAsyncSocketDelegate {
    let serverPort:UInt16 = 9997        //服务器端口号
    var serverIP:String = ""
    var clientSocket:GCDAsyncSocket!    //tcp连接对象
    var mainQueue = DispatchQueue.main  //主线程
    var isconnected:Bool = false
    
    var filename:String!
    var filesize:Int!
    var filepath:String = ""
    var documentPath:String!
    var fileData:Data!
    
    var showAlert={       //显示提示窗口
        (msg:String) in
    }
    
    var setprogress={
        (x:Float) in
    }
    
    func setIP(serverIP:String)
    {
        self.serverIP = serverIP
    }
    func fileSocketinit(filename:String,filesize:Int)
    {
        self.filename = filename
        self.filesize = filesize
        let documentPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        documentPath = documentPaths[0]
        self.filepath = documentPath + "/"+filename
        fileData = Data()
        fileData.removeAll()
        print(filepath)
        
        do {
            try fileData = Data(contentsOf: URL(fileURLWithPath: filepath))
            print ("文件读取成功，大小为\(fileData.count)")
            
        } catch {
            // error异常的对象
            print(error)
        }

    }
    
    func connectServer() {
        print("upfile测试连接开始")
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
        print("upfile连接成功")
        beginSend()
        clientSocket.readData(withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print ("upfile与服务器断开连接")
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) -> Void {
        // 1 获取客户的发来的数据 ，把 NSData 转 NSString
        let readClientDataString:NSString? = NSString(data: data as Data, encoding:String.Encoding.utf8.rawValue)
        var str:String = ""
        if (readClientDataString != nil)
        {
            str=String(readClientDataString!)
            print("receive:\(str)"+"port:9997")
        }
        clientSocket.readData(withTimeout: -1, tag:0)
    }
    
    func sendMsg(data:Data,isend:Bool) {        //发送数据
        clientSocket.write(data, withTimeout: -1, tag: 0)
        if (isend)
        {
            //clientSocket.disconnect()
            self.showAlert("文件上传完成")
        }
        clientSocket.readData(withTimeout: -1, tag:0)
    }
    
    func beginSend()    //发送文件数据
    {
        
        var lastsize:Int = filesize
        var beginindex:Int = 0
        var endindex:Int = 0
        var nowdata:Data = Data()
        while (lastsize>0)
        {
            if (lastsize>1000)
            {
                endindex = fileData.index(beginindex, offsetBy: 1000)
                nowdata=fileData.subdata(in: Range.init(uncheckedBounds: (lower: beginindex, upper: endindex)))
                
                sendMsg(data: nowdata,isend: false)
                //fileData.removeFirst(endindex-fileData.startIndex)
                lastsize = lastsize-nowdata.count
                print ("发送大小"+String(nowdata.count)+"  剩余大小"+String(lastsize))
                beginindex = beginindex + 1000
                print ("begin\(beginindex),end\(endindex)")
            }
            else
            {
                endindex = fileData.endIndex
                print ("last\(endindex)")
                nowdata=fileData.subdata(in: Range.init(uncheckedBounds: (lower: beginindex, upper: endindex)))
                sendMsg(data: nowdata,isend: true)
                lastsize = 0
            }
            let x=Float(filesize-lastsize)*1.0/Float(filesize)
            setprogress(x)
            
        }

        
    }
    
}
