import Testing
import Foundation
@testable import Zapper

@Test func storeAndRetrieveData() throws {
    let service = KeychainService()
    let testData = "test-certificate-data".data(using: .utf8)!
    let key = "test-device-\(UUID().uuidString)"
    try service.store(data: testData, forKey: key)
    let retrieved = try service.retrieve(forKey: key)
    #expect(retrieved == testData)
    try service.delete(forKey: key)
}

@Test func retrieveNonexistentReturnsNil() throws {
    let service = KeychainService()
    let result = try service.retrieve(forKey: "nonexistent-key-\(UUID().uuidString)")
    #expect(result == nil)
}

@Test func deleteKey() throws {
    let service = KeychainService()
    let key = "delete-test-\(UUID().uuidString)"
    let testData = "data".data(using: .utf8)!
    try service.store(data: testData, forKey: key)
    try service.delete(forKey: key)
    let result = try service.retrieve(forKey: key)
    #expect(result == nil)
}

@Test func overwriteExistingKey() throws {
    let service = KeychainService()
    let key = "overwrite-test-\(UUID().uuidString)"
    let data1 = "first".data(using: .utf8)!
    let data2 = "second".data(using: .utf8)!
    try service.store(data: data1, forKey: key)
    try service.store(data: data2, forKey: key)
    let retrieved = try service.retrieve(forKey: key)
    #expect(retrieved == data2)
    try service.delete(forKey: key)
}
