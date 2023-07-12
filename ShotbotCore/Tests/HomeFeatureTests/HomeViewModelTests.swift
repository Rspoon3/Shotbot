////
////  HomeViewModelTests.swift
////  ShotbotTests
////
////  Created by Richard Witherspoon on 5/12/23.
////
//
//import Foundation
//import Combine
//import XCTest
//import HomeFeature
//
//@MainActor final class HomeViewModelTests: XCTestCase {
//    var mockPhotoLibraryManager: MockPhotoLibraryManager!
//    var mockPersistenceManager: MockPersistenceManager!
//    var mockFileManager: MockFileManager!
//    var mockPurchaseManager: MockPurchaseManager!
//    var sut: HomeViewModel!
//    private var cancellables = Set<AnyCancellable>()
//    private let screenshot = UIImage(named: "iPhone14Screenshot", in: .models)!
//
//    // MARK: - Lifecycle
//
//    override func setUp() {
//        mockPhotoLibraryManager = MockPhotoLibraryManager()
//        mockPersistenceManager = MockPersistenceManager()
//        mockFileManager = MockFileManager()
//        mockPurchaseManager = MockPurchaseManager()
//
//        sut = HomeViewModel(
//            persistenceManager: mockPersistenceManager,
//            photoLibraryManager: mockPhotoLibraryManager,
//            purchaseManager: mockPurchaseManager,
//            fileManager: mockFileManager
//        )
//    }
//
//    override func tearDown() {
//        mockPhotoLibraryManager = nil
//        mockPersistenceManager = nil
//        mockFileManager = nil
//        mockPurchaseManager = nil
//
//        sut = nil
//
//        cancellables.removeAll()
//        super.tearDown()
//    }
//
//    // MARK: - Tests
//
//    func testStartPhotoSelectionProcess() {
//        mockPersistenceManager.canSaveFramedScreenshot = true
//
//        XCTAssertFalse(sut.showPhotosPicker)
//        sut.selectPhotos()
//        XCTAssertTrue(sut.showPhotosPicker)
//    }
//
//    func testCreateDeviceFrameSavesToFiles() async throws {
//        mockPersistenceManager.reset()
//        mockPersistenceManager.autoSaveToFiles = true
//        mockFileManager.copyResult = nil
//
//        _ = try await sut.createDeviceFrame(using: screenshot, count: 0)
//    }
//
//    func testCreateDeviceFrameSavesToPhotos() async throws {
//        mockPersistenceManager.reset()
//        mockPersistenceManager.autoSaveToPhotos = true
//        mockPhotoLibraryManager.saveImageURLResult = nil
//
//        _ = try await sut.createDeviceFrame(using: screenshot, count: 0)
//    }
//
////
////
////    func testProcessSelectedPhotosDeletesPhotoIfNeeded() async throws {
////        sut.imageSelections = [.init(itemIdentifier: "test")]
////        sut.shareableImages = [.init(image: screenshot, url: URL(string: "www.google.com")!)]
////
////        sut.$shareableImages
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] values in
////                guard let self, values.isEmpty else { return }
////                sut.shareableImages = [.init(image: screenshot, url: URL(string: "www.google.com")!)]
////            }.store(in: &cancellables)
////
////        mockPersistenceManager.autoDeleteScreenshots = true
////        try await sut.processSelectedPhotos()
////        XCTAssertTrue(mockPhotoLibraryManager.didDelete)
////
////        mockPersistenceManager.autoDeleteScreenshots = false
////        mockPhotoLibraryManager.didDelete = false
////        try await sut.processSelectedPhotos()
////        XCTAssertFalse(mockPhotoLibraryManager.didDelete)
////    }
////
////    func testProcessSelectedPhotosShowsToast() async throws {
////        sut.imageSelections = [.init(itemIdentifier: "test")]
////        sut.shareableImages = [.init(image: screenshot, url: URL(string: "www.google.com")!)]
////
////        sut.$shareableImages
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] values in
////                guard let self, values.isEmpty else { return }
////                sut.shareableImages = [.init(image: screenshot, url: URL(string: "www.google.com")!)]
////            }.store(in: &cancellables)
////
////        // Files
////        mockPersistenceManager.reset()
////        mockPersistenceManager.autoSaveToFiles = true
////
////        try await sut.processSelectedPhotos()
////        XCTAssertTrue(sut.showAutoSaveToast)
////
////        // Photos
////        mockPersistenceManager.reset()
////        mockPersistenceManager.autoSaveToPhotos = true
////
////        try await sut.processSelectedPhotos()
////        XCTAssertTrue(sut.showAutoSaveToast)
////
////        // Files & Photos
////        mockPersistenceManager.reset()
////        mockPersistenceManager.autoSaveToFiles = true
////        mockPersistenceManager.autoSaveToPhotos = true
////
////        try await sut.processSelectedPhotos()
////        XCTAssertTrue(sut.showAutoSaveToast)
////    }
////
////    func testProcessSelectedPhotosSkipsToast() async throws {
////        sut.shareableImages.removeAll()
////        mockPersistenceManager.reset()
////        try await sut.processSelectedPhotos()
////        XCTAssertFalse(sut.showAutoSaveToast)
////    }
////
////    func testClearImagesOnAppBackgroundReturnsNothing() {
////        mockPersistenceManager.clearImagesOnAppBackground = false
////
////        sut.shareableImages = [.init(image: screenshot, url: URL(string: "www.google.com")!)]
////        sut.imageSelections = [.init(itemIdentifier: "test")]
////
////        sut.clearImagesOnAppBackground()
////        XCTAssertFalse(sut.shareableImages.isEmpty)
////        XCTAssertFalse(sut.imageSelections.isEmpty)
////    }
////
////    func testClearImagesOnAppBackgroundClears() {
////        mockPersistenceManager.clearImagesOnAppBackground = true
////        sut.shareableImages = [.init(image: screenshot, url: URL(string: "www.google.com")!)]
////        sut.imageSelections = [.init(itemIdentifier: "test")]
////        sut.clearImagesOnAppBackground()
////        XCTAssertTrue(sut.shareableImages.isEmpty)
////        XCTAssertTrue(sut.imageSelections.isEmpty)
////    }
//}
