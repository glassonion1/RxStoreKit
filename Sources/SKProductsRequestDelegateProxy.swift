//
//  SKProductsRequestDelegateProxy.swift
//  RxStoreKit
//
//  Created by taisuke fujita on 2017/06/21.
//  Copyright © 2017年 Taisuke Fujita. All rights reserved.
//

import StoreKit
import RxSwift
import RxCocoa

public class SKProductsRequestDelegateProxy: DelegateProxy, SKProductsRequestDelegate, DelegateProxyType {
    public static func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let request: SKProductsRequest = object as! SKProductsRequest
        return request.delegate
    }
    
    public static func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let request: SKProductsRequest = object as! SKProductsRequest
        request.delegate = delegate as? SKProductsRequestDelegate
    }
    
    public override static func createProxyForObject(_ object: AnyObject) -> AnyObject {
        let request: SKProductsRequest = object as! SKProductsRequest
        return request.createRxDelegateProxy()
    }
    
    let responseSubject = PublishSubject<SKProductsResponse>()
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        responseSubject.onNext(response)
        _forwardToDelegate?.productsRequest(request, didReceive: response)
    }
    
    deinit {
        responseSubject.onCompleted()
    }
}
