//
//  ValidationTestCase.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

class ValidationTestCase: XCTestCase {

    func assertValid(block: () throws -> ()) {
        do {
            try block()
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func assertValidationError(expectedErrorDescription: String, owned: Bool? = nil, block: () throws -> ()) {
        do {
            try block()
            XCTFail("ValidationError expected")
        } catch let error as ValidationError {
            XCTAssertEqual(error.description, expectedErrorDescription)
            if error.description != expectedErrorDescription {
                error.description
            }
            
            if let owned = owned {
                if error.owner != nil {
                    XCTAssertTrue(owned)
                } else {
                    XCTAssertFalse(owned)
                }
            }
        } catch {
            XCTFail("ValidationError expected")
        }
    }
    
}
