//
//  CEFResourceBundleHandler.g.swift
//  CEF.swift
//
//  Created by Tamas Lustyik on 2015. 07. 30..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

import Foundation

extension cef_resource_bundle_handler_t: CEFObject {
}

typealias CEFResourceBundleHandlerMarshaller = CEFMarshaller<CEFResourceBundleHandler, cef_resource_bundle_handler_t>

extension CEFResourceBundleHandler {
    func toCEF() -> UnsafeMutablePointer<cef_resource_bundle_handler_t> {
        return CEFResourceBundleHandlerMarshaller.pass(self)
    }
}

extension cef_resource_bundle_handler_t: CEFCallbackMarshalling {
    mutating func marshalCallbacks() {
        get_localized_string = CEFResourceBundleHandler_getLocalizedString
        get_data_resource = CEFResourceBundleHandler_getDataResource
    }
}

func CEFResourceBundleHandler_getLocalizedString(ptr: UnsafeMutablePointer<cef_resource_bundle_handler_t>,
                                                 stringID: Int32,
                                                 cefStrPtr: UnsafeMutablePointer<cef_string_t>) -> Int32 {
    guard let obj = CEFResourceBundleHandlerMarshaller.get(ptr) else {
        return 0
    }
                                                    
    if let str = obj.getLocalizedString(Int(stringID)) {
        CEFStringSetFromSwiftString(str, cefString: cefStrPtr)
        return 1
    }
    
    return 0
}

func CEFResourceBundleHandler_getDataResource(ptr: UnsafeMutablePointer<cef_resource_bundle_handler_t>,
                                              resourceID: Int32,
                                              dataBufferPtr: UnsafeMutablePointer<UnsafeMutablePointer<Void>>,
                                              dataSizePtr: UnsafeMutablePointer<size_t>) -> Int32 {
    guard let obj = CEFResourceBundleHandlerMarshaller.get(ptr) else {
        return 0
    }
    
    if let (bufferPtr, size) = obj.getDataResource(Int(resourceID)) {
        dataBufferPtr.memory = bufferPtr
        dataSizePtr.memory = size
        return 1
    }
    
    return 0
}

