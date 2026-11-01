//
//  ios_templateApp.swift
//  Block Fit (project still named ios-template)
//

import SwiftUI
#if canImport(BlockFitCore)
import BlockFitCore
#endif

@main
struct ios_templateApp: App {
    @StateObject private var app = AppState(store: FileSaveStore(url: ios_templateApp.saveURL))

    static var saveURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("blockfit-save.json")
    }

    init() {
        try? FileManager.default.createDirectory(at: Self.saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    var body: some Scene {
        WindowGroup { RootView().environmentObject(app) }
    }
}
