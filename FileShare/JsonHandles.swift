//
//  JsonHandles.swift
//  FileShare
//
//  Created by 吴子鸿 on 2016/12/20.
//  Copyright © 2016年 吴子鸿. All rights reserved.
//

import Foundation

class JsonHandles {
    var sendjson:[String: Any] = [:]
    
    
    var fileMsg={       //文件信息获取
        (str:[(String,Int)]) in
    }
    func getdata(data:Data)
    {
        print(data)
        let jsontest = try? JSONSerialization.jsonObject(with: data,
                                                     options:.allowFragments) as! [String: Any]
        if (jsontest != nil)
        {
            print("yes")
            let json = jsontest!
            let type = json["TYPE"] as! String
            if (type == "LSNAME")
            {
                self.lsHandle(jsondata: json)
            }
        }
        else
        {
            //json无法处理，进行提示等操作

        }
    }

    func lsHandle(jsondata:[String: Any])  //返回文件路径数组
    {
        let num = jsondata["NUM"] as! Int
        let filenames:[String] = jsondata["NAME"] as! [String]
        let filesizes:[Int] = jsondata["SIZE"] as! [Int]
        var str:[(String,Int)] = []
        for i in 0..<num
        {
            let key = (filenames[i],filesizes[i])
            str.append(key)
        }
        fileMsg(str)    //设置文件
    }
    
    func strToJson(jsondata:[String: Any]) ->String     //结构数组转字符串
    {
        let data = try? JSONSerialization.data(withJSONObject: jsondata, options: [])
        let str = String(data:data!, encoding: String.Encoding.utf8)!
        return str
    }

}
