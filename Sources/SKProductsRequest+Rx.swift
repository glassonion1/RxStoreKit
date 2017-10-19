//
//  SKProductsRequest+Rx.swift
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

extension SKProductsRequest {
    
    public func createRxDelegateProxy() -> SKProductsRequestDelegateProxy {
        return SKProductsRequestDelegateProxy(parentObject: self)
    }
    
}

extension Reactive where Base: SKProductsRequest {
    
    public var delegate: DelegateProxy<SKProductsRequest, SKProductsRequestDelegate> {
        return SKProductsRequestDelegateProxy.proxy(for: base)
    }
    
    public var productsRequest: Observable<SKProductsResponse> {
        return SKProductsRequestDelegateProxy.proxy(for: base).responseSubject.asObservable()
    }
    
}
