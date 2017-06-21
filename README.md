# RxStoreKit

[![Version](https://img.shields.io/cocoapods/v/RxStoreKit.svg?style=flat)](http://cocoapods.org/pods/RxStoreKit)
[![License](https://img.shields.io/cocoapods/l/RxStoreKit.svg?style=flat)](http://cocoapods.org/pods/RxStoreKit)
[![Platform](https://img.shields.io/cocoapods/p/RxStoreKit.svg?style=flat)](http://cocoapods.org/pods/RxStoreKit)

RxStoreKit is lightweight and easy to use Rx support for StoreKit.

## Usage

### Request Products

```swift
import StoreKit
import RxSwift
import RxStoreKit

let disposeBag = DisposeBag()

let productRequest = SKProductsRequest(productIdentifiers: Set(["your app product id"]))
productRequest.rx.productsRequest
    .subscribe(onNext: { product in
        print(product)
    }).disposed(by: disposeBag)
productRequest.start()
```

### Restore Transactions

```swift
SKPaymentQueue.default().rx.restoreCompletedTransactions()
    .subscribe(onNext: { queue in
        print(queue)
    }).disposed(by: disposeBag)
```

### Request payment

```swift
let productRequest = SKProductsRequest(productIdentifiers: Set(["xxx.xxx.xxx"]))
productRequest.rx.productsRequest
    .flatMap { response -> Observable<SKProduct> in
        return Observable.from(response.products)
    }
    .flatMap { product -> Observable<SKPaymentTransaction> in
        return SKPaymentQueue.default().rx.add(product: product)
    }
    .subscribe(onNext: { transition in
        print(transition)
    }).disposed(by: disposeBag)
productRequest.start()
```

### Download hosting contents
Download In-App Purchase Contents
```swift
let productRequest = SKProductsRequest(productIdentifiers: Set(["xxx.xxx.xxx"]))
productRequest.rx.productsRequest
    .flatMap { response -> Observable<SKProduct> in
        return Observable.from(response.products)
    }
    .flatMap { product -> Observable<SKPaymentTransaction> in
        return SKPaymentQueue.default().rx.add(product: product)
    }
    .flatMap { transaction -> Observable<SKDownload> in
        return SKPaymentQueue.default().rx.start(downloads: transaction.downloads)
    }
    .subscribe(onNext: { download in
        print(download)
    }).disposed(by: disposeBag)
productRequest.start()
```

## Installation

This library depends on both __RxSwift__ and __RxCocoa__

### CocoaPods

RxStoreKit is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:
```ruby
pod "RxStoreKit"
```
Then, run following command:
`$ pod install`

## License

RxStoreKit is available under the MIT license. See the LICENSE file for more info.