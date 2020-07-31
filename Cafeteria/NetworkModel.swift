//
//  NetworkModel.swift
//  Cafeteria
//
//  Created by 손원희 on 2020/04/14.
//  Copyright © 2020 손원희. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import SPAlert

let header: HTTPHeaders = [ "Content-Type": "application/x-www-form-urlencoded" ]

let jsonheader: HTTPHeaders = [ "Content-Type": "application/json" ]

var alamoFireManager : SessionManager?

class NetworkModel {
    let BASE_URL = "http://cafeteria-main-lb-1293979949.ap-northeast-2.elb.amazonaws.com"
    
    //callback delegate
    var view: NetworkCallback?
    
    init() { }
    init(_ vc: NetworkCallback) {
        self.view = vc
    }
    
    func isSuccess(statusCode code: Int) -> Bool {
        switch code {
        case 200:
            return true
        default:
            return false
        }
    }
    
    func errorMsg(code: Int) -> String {
        switch code {
        case 400:
            return .checkId
        case 401:
            return .noToken
        case 402:
            return .dbERROR
        case 403:
            fallthrough
        default:
//            return "오류"
            return String(code)
        }
    }
    
    func post<T: Mappable>(function name: String, type: T.Type, params: Parameters? = nil, headers: HTTPHeaders? = header) {
        Alamofire.request("\(BASE_URL)/\(name)", method: .post, parameters: params, headers: headers).responseObject { (res: DataResponse<T>) in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
            }.responseArray { (res: DataResponse<[T]>) in
                self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
        }
    }
    
    func post(function name: String, params: Parameters? = nil, headers: HTTPHeaders? = header) {
        Alamofire.request("\(BASE_URL)/\(name)", method: .post, parameters: params, headers: headers).response { res in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: "")
        }
    }
    
    func get<T: Mappable>(function name: String, type: T.Type, params: Parameters? = nil) {
        Alamofire.request("\(BASE_URL)/\(name)").responseObject { (res: DataResponse<T>) in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
            }.responseArray { (res: DataResponse<[T]>) in
                self.networkResult(function: name, statusCode: res.response?.statusCode, item: res.result.value)
        }
    }
    
    func get(function name: String, params: Parameters? = nil) {
        Alamofire.request("\(BASE_URL)/\(name)").response { res in
            self.networkResult(function: name, statusCode: res.response?.statusCode, item: "")
        }
    }
    
    func networkResult(function name: String, statusCode code: Int? = nil, item: Any? = nil) {
        guard let code = code else {
            self.view?.networkFailed(errorMsg: name, code: name)
            return
        }
        
        if !self.isSuccess(statusCode: code) {
            self.view?.networkFailed(errorMsg: self.errorMsg(code: code), code: name)
            return
        }
        guard let item = item else {
            //Indicator.stopAnimating()
            return
        }
        
        if self.isSuccess(statusCode: code) {
            self.view?.networkResult(resultData: item, code: name)
        } else {
            
            self.view?.networkFailed(errorMsg: self.errorMsg(code: code), code: name)
        }
    }
    
    let _foodplan = "food"
    func foodplan(date: Int) {
        //요청 시간 관련 테스트 (임시)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        
        Alamofire.request("\(BASE_URL)/menus?date=\(date)", encoding: URLEncoding.httpBody).responseJSON { res in
            guard let code = res.response?.statusCode else {
                self.view?.networkFailed(errorMsg: String.noServer, code: self._foodplan)
                return
            }
            
            switch res.result {
            case .success(let item):
                print(item)
                if self.isSuccess(statusCode: code) {
                    if let array = item as? NSArray {
                        self.view?.networkResult(resultData: array, code: self._foodplan)
                    }
                } else {
                    self.view?.networkFailed(errorMsg: self.errorMsg(code: code), code: self._foodplan)
                }
            case .failure(let error):
                if let error = error as? String {
                    self.view?.networkFailed(errorMsg: error, code: self._foodplan)
                } else {
                    self.view?.networkFailed(errorMsg: String.noServer, code: self._foodplan)
                }
            }
        }
    }
}
