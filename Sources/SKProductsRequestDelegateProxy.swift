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
    
    let responseSubject = PublishSubject<SKProductsResponse>()
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        _forwardToDelegate?.productsRequest(request, didReceive: response)
        responseSubject.onNext(response)
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        _forwardToDelegate?.request?(request, didFailWithError: error)
        responseSubject.onError(error)
    }

    deinit {
        responseSubject.on(.completed)
    }
}
