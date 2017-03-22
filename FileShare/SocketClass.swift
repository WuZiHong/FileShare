//
//  SocketClass.swift
//  FileShare
//
//  Created by 吴子鸿 on 2016/12/20.
//  Copyright © 2016年 吴子鸿. All rights reserved.
//

import Foundation

class SocketClass:NSObject, GCDAsyncSocketDelegate {
    let serverPort:UInt16 = 9999        //服务器端口号
    var serverIP:String = ""
    var clientSocket:GCDAsyncSocket!    //tcp连接对象
    var mainQueue = DispatchQueue.main  //主线程
    var isconnected:Bool = false
    
    var jshandle:JsonHandles!
    

    
    func socketinit(jshandle:JsonHandles,serverIP:String)
    {
        self.jshandle = jshandle
        self.serverIP = serverIP
    }
    
    func connectServer() {
        print("测试连接开始")
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
        print("连接成功")
        //发送初始数据
        let json:[String:Any] = [
            "TYPE": "LS",
            "PATH":""
        ]
        let msg = jshandle.strToJson(jsondata: json)
        let serviceStr:NSMutableString = NSMutableString()
        serviceStr.append(msg)
        print ("发送字符串:\(serviceStr)")
        clientSocket.write(serviceStr.data(using: String.Encoding.utf8.rawValue)!, withTimeout: -1, tag: 0)
        
        clientSocket.readData(withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print ("与服务器断开连接")
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) -> Void {
        // 1 获取客户的发来的数据 ，把 NSData 转 NSString
        
        let readClientDataString:NSString? = NSString(data: data as Data, encoding:String.Encoding.utf8.rawValue)
        if (readClientDataString != nil)
        {
            let str=String(readClientDataString!)
            print("receive:\(str)")
        }
        jshandle.getdata(data: data)
        // 4每次读完数据后，都要调用一次监听数据的方法
        clientSocket.readData(withTimeout: -1, tag:0)
    }
    
    func sendMsg(msg:String) {        //发送数据
        // 1.处理请求，返回数据给客户端 ok
        let serviceStr:NSMutableString = NSMutableString()
        serviceStr.append(msg)
        print ("发送字符串:\(serviceStr)")
        clientSocket.write(serviceStr.data(using: String.Encoding.utf8.rawValue)!, withTimeout: -1, tag: 0)
        clientSocket.readData(withTimeout: -1, tag:0)
    }
    
    func updateLS(path:String)      //更新路径
    {
        let json:[String:Any] = [
            "TYPE": "LS",
            "PATH": path
        ]
        let msg = jshandle.strToJson(jsondata: json)
        let serviceStr:NSMutableString = NSMutableString()
        serviceStr.append(msg)
        print ("发送字符串:\(serviceStr)")
        clientSocket.write(serviceStr.data(using: String.Encoding.utf8.rawValue)!, withTimeout: -1, tag: 0)
    }
    
}
