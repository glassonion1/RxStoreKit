//
//  SKProductsRequestDelegateProxy.swift
//  RxStoreKit
//
//  Created by taisuke fujita on 2017/06/21.
//  Copyright © 2017年 Taisuke Fujita. All rights reserved.
//

import StoreKit
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

public class SKProductsRequestDelegateProxy
    : DelegateProxy<SKProductsRequest, SKProductsRequestDelegate>
    , DelegateProxyType
    , SKProductsRequestDelegate {
    
    public init(parentObject: SKProductsRequest) {
        super.init(parentObject: parentObject, delegateProxy: SKProductsRequestDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        self.register { SKProductsRequestDelegateProxy(parentObject: $0) }
    }
    
    public static func currentDelegate(for object: SKProductsRequest) -> SKProductsRequestDelegate? {
        return object.delegate
    }
    
    public static func setCurrentDelegate(_ delegate: SKProductsRequestDelegate?, to object: SKProductsRequest) {
        object.delegate = delegate
    }
    
    public static func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let request: SKProductsRequest = object as! SKProductsRequest
        return request.delegate
    }
    
    public static func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let request: SKProductsRequest = object as! SKProductsRequest
        request.delegate = delegate as? SKProductsRequestDelegate
    }
    
    let responseSubject = PublishSubject<SKProductsResponse>()
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        _forwardToDelegate?.productsRequest(request, didReceive: response)
        responseSubject.onNext(response)
    }
    
    deinit {
        responseSubject.on(.completed)
    }
}
