//
//  SKProductsRequest+Rx.swift
//  RxStoreKit
//
//  Created by taisuke fujita on 2017/06/21.
//  Copyright © 2017年 Taisuke Fujita. All rights reserved.
//

import StoreKit
import RxSwift
import RxCocoa

extension SKProductsRequest {
    
    public func createRxDelegateProxy() -> SKProductsRequestDelegateProxy {
        return SKProductsRequestDelegateProxy(parentObject: self)
    }
    
}

extension Reactive where Base: SKProductsRequest {
    
    public var delegate: DelegateProxy {
        return SKProductsRequestDelegateProxy.proxyForObject(base)
    }
    
    public var productsRequest: Observable<SKProductsResponse> {
        let proxy = SKProductsRequestDelegateProxy.proxyForObject(base)
        return proxy.responseSubject
    }
    
}
