//
//  Conductor.swift
//  SimplePlayer
//
//  Created by Patrick Quinn-Graham on 5/1/25.
//

import Foundation

// BootFailed error
enum ConductorError: Error {
    case bootFailed
    case couldNotSaveBookmark
    case couldNotAccessSecurityScopedResource(String)
    case noSelectedDirectory
}

@Observable
class Conductor {
    
    var booted = false
    
    var loading = false
    
    var selectedDirectory: URL?
    
    var items: [URL] = []
    
    var bootError: ConductorError?
    
    func clear() {
        selectedDirectory?.stopAccessingSecurityScopedResource()
        selectedDirectory = nil
        
        UserDefaults.standard.removeObject(forKey: "LastPickedFolder")
        
        items = []
        booted = false
    }
    
    func retrieveSelectedDirectoryOrClear() {
        do {
           try retrieveLastPickedFolder()
        } catch {
            clear()
        }
    }
    
    func retrieveLastPickedFolder() throws {
        guard let data = UserDefaults.standard.data(forKey: "LastPickedFolder") else {
            return
        }
            
        var isStale = false
        let newUrl = try URL(resolvingBookmarkData: data,
                             options: .withSecurityScope,
                             relativeTo: nil,
                             bookmarkDataIsStale: &isStale)
          
        guard newUrl.startAccessingSecurityScopedResource() else {
            throw ConductorError.couldNotAccessSecurityScopedResource(newUrl.path())
        }
        
        selectedDirectory = newUrl
        
        refreshItemsFromSelectedDirectory()
    }
    
    func selectNewFolder(_ url: URL) {
        let gotAccess = url.startAccessingSecurityScopedResource()
        if !gotAccess { return }
        
        if selectedDirectory != nil {
            selectedDirectory?.stopAccessingSecurityScopedResource()
            selectedDirectory = nil
        }
        
        do {
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            UserDefaults.standard.set(data, forKey: "LastPickedFolder")
        } catch {
            bootError = ConductorError.couldNotSaveBookmark
            return
        }
        
        selectedDirectory = url
        
        refreshItemsFromSelectedDirectory()
    }
    
    func refreshItemsFromSelectedDirectory() {
        booted = true
        do {
            loading = true
            guard let selectedDirectory else { throw ConductorError.noSelectedDirectory }
            // Find all mov, mp4 or m4v files within the directory url
            let videoExtensions: Set<String> = ["mov", "mp4", "m4v"]

            let files = try FileManager.default.contentsOfDirectory(at: selectedDirectory, includingPropertiesForKeys: nil, options: [])
                .filter { url in
                    return videoExtensions.contains(url.pathExtension.lowercased())
                }
            
            for file in files {
                print("Found \(file)")
            }
            
            items = files
        } catch {
            print("Refresh items failed: \(error)")
            bootError = ConductorError.bootFailed
        }
        loading = false
    }
    
    
}
