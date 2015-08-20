//
//  ValidationError.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

public struct ValidationError : ErrorType {
    let value: Any
    let description: String
    
    public init(value: Any, description: String) {
        self.value = value
        self.description = description
    }
}
