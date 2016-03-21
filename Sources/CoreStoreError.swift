//
//  CoreStoreError.swift
//  CoreStore
//
//  Copyright © 2014 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import CoreData


// MARK: - CoreStoreError

public enum CoreStoreError: ErrorType, CustomStringConvertible, CustomDebugStringConvertible {
    
    /**
     A failure occured because of an unknown error.
     */
    case Unknown
    
    /**
     The `NSPersistentStore` could note be initialized because another store existed at the specified `NSURL`.
     */
    case DifferentStorageExistsAtURL(existingPersistentStoreURL: NSURL)
    
    /**
     An `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case MappingModelNotFound(storage: LocalStorage, targetModel: NSManagedObjectModel, targetModelVersion: String)
    
    /**
     Progressive migrations are disabled for a store, but an `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case ProgressiveMigrationRequired(storage: LocalStorage)
    
    /**
     An internal SDK call failed with the specified `NSError`.
     */
    case InternalError(NSError: NSError)
    
    
    // MARK: ErrorType
    
    public var _domain: String {
        
        return "com.corestore.error"
    }
    
    public var _code: Int {
    
        switch self {
            
        case .Unknown:                      return Code.Unknown.rawValue
        case .DifferentStorageExistsAtURL:  return Code.DifferentStorageExistsAtURL.rawValue
        case .MappingModelNotFound:         return Code.MappingModelNotFound.rawValue
        case .ProgressiveMigrationRequired: return Code.ProgressiveMigrationRequired.rawValue
        case .InternalError:                return Code.InternalError.rawValue
        }
    }
    
    public var _userInfo: [NSObject: AnyObject] {
        
        return ["test": 1]
    }
    
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        
        // TODO:
        return (self as NSError).description
    }
    
    
    // MARK: CustomDebugStringConvertible
    
    public var debugDescription: String {
        
        return self.description
    }
    
    
    // MARK: Internal
    
    internal init(_ error: ErrorType?) {
        
        self = error.flatMap { $0.swift } ?? .Unknown
    }
    
    
    // MARK: Private
    
    private enum Code: Int {
        
        case Unknown
        case DifferentStorageExistsAtURL
        case MappingModelNotFound
        case ProgressiveMigrationRequired
        case InternalError
    }
}


// MARK: - CoreStoreErrorCode

/**
 The `NSError` error domain for `CoreStore`.
 */
@available(*, deprecated=2.0.0, message="Use CoreStoreError enum values instead.")
public let CoreStoreErrorDomain = "com.corestore.error"

/**
 The `NSError` error codes for `CoreStoreErrorDomain`.
 */
@available(*, deprecated=2.0.0, message="Use CoreStoreError enum values instead.")
public enum CoreStoreErrorCode: Int {
    
    /**
     A failure occured because of an unknown error.
     */
    case UnknownError
    
    /**
     The `NSPersistentStore` could note be initialized because another store existed at the specified `NSURL`.
     */
    case DifferentPersistentStoreExistsAtURL
    
    /**
     An `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case MappingModelNotFound
    
    /**
     Progressive migrations are disabled for a store, but an `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case ProgressiveMigrationRequired
}


// MARK: - NSError

public extension NSError {
    
    // MARK: Internal
    
    internal var isCoreDataMigrationError: Bool {
        
        let code = self.code
        return (code == NSPersistentStoreIncompatibleVersionHashError
            || code == NSMigrationMissingSourceModelError
            || code == NSMigrationError)
            && self.domain == NSCocoaErrorDomain
    }
    
    
    // MARK: Deprecated

    /**
     If the error's domain is equal to `CoreStoreErrorDomain`, returns the associated `CoreStoreErrorCode`. For other domains, returns `nil`.
     */
    @available(*, deprecated=2.0.0, message="Use CoreStoreError enum values instead.")
    public var coreStoreErrorCode: CoreStoreErrorCode? {
        
        return (self.domain == CoreStoreErrorDomain
            ? CoreStoreErrorCode(rawValue: self.code)
            : nil)
    }
}


// MARK: Internal

internal extension ErrorType {
    
    internal var swift: CoreStoreError {
        
        if case let error as CoreStoreError = self {
            
            return error
        }
        
        let error = self as NSError
        guard error.domain == "com.corestore.error" else {
            
            return .InternalError(NSError: error)
        }
        
        guard let code = CoreStoreError.Code(rawValue: error.code) else {
            
            return .Unknown
        }
        
        let info = error.userInfo
        switch code {
            
        case .Unknown:
            return .Unknown
            
        case .DifferentStorageExistsAtURL:
            guard case let existingPersistentStoreURL as NSURL = info["existingPersistentStoreURL"] else {
                
                return .Unknown
            }
            return .DifferentStorageExistsAtURL(existingPersistentStoreURL: existingPersistentStoreURL)
            
        case .MappingModelNotFound:
            guard let persistentStore = info["persistentStore"] as? NSPersistentStore,
                let storage = persistentStore.storageInterface as? LocalStorage,
                let targetModel = info["targetModel"] as? NSManagedObjectModel,
                let targetModelVersion = info["targetModelVersion"] as? String else {
                
                return .Unknown
            }
            return .MappingModelNotFound(storage: storage, targetModel: targetModel, targetModelVersion: targetModelVersion)
            
        case .ProgressiveMigrationRequired:
            guard let persistentStore = info["persistentStore"] as? NSPersistentStore,
                let storage = persistentStore.storageInterface as? LocalStorage else {
                
                return .Unknown
            }
            return .ProgressiveMigrationRequired(storage: storage)
            
        case .InternalError:
            guard case let NSError as NSError = info["NSError"] else {
                
                return .Unknown
            }
            return .InternalError(NSError: NSError)
            
        default:
            return .Unknown
        }
    }
    
    internal var objc: NSError {
        
        guard let error = self as? CoreStoreError else {
            
            return self as NSError
        }
        
        let domain = "com.corestore.error"
        let code: CoreStoreError.Code
        let info: [NSObject: AnyObject]
        switch error {
            
        case .Unknown:
            return self as NSError
            
        case .DifferentStorageExistsAtURL(let existingPersistentStoreURL):
            code = .DifferentStorageExistsAtURL
            info = [
                "existingPersistentStoreURL": existingPersistentStoreURL
            ]
            
        case .MappingModelNotFound(let storage, let targetModel, let targetModelVersion):
            code = .MappingModelNotFound
            info = [
                "storage": storage.objc,
                "targetModel": targetModel,
                "targetModelVersion": targetModelVersion
            ]
            
        case .ProgressiveMigrationRequired:
            guard let persistentStore = info["persistentStore"] as? NSPersistentStore,
                let storage = persistentStore.storageInterface as? LocalStorage else {
                    
                    return .Unknown
            }
            return .ProgressiveMigrationRequired(storage: storage)
            
        case .InternalError:
            guard case let NSError as NSError = info["NSError"] else {
                
                return .Unknown
            }
            return .InternalError(NSError: NSError)
            
        default:
            return self as NSError
        }
        
        return NSError(domain: domain, code: code.rawValue, userInfo: info)
    }
}