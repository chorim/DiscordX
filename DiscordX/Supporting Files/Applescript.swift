//
//  Applescript.swift
//  DiscordX
//
//  Created by Asad Azam on 28/9/20.
//  Copyright © 2021 Asad Azam. All rights reserved.
//

import Foundation
import Cocoa

enum APScripts: String {
    case windowNames = "return name of windows"
    case filePaths = "return file of documents"
    case documentNames = "return name of documents"
    case activeWorkspaceDocument = "return active workspace document"
}

func runAPScript(_ s: APScripts) -> [String]? {
    let scr = """
    tell application "Xcode"
        \(s.rawValue)
    end tell
    """
    
    // execute the script
    let script = NSAppleScript.init(source: scr)
    let result = script?.executeAndReturnError(nil)

    // format the result as a Swift array
    if let desc = result {
        var arr: [String] = []
        if desc.numberOfItems == 0 {
            return arr
        }
        for i in 1...desc.numberOfItems {
            let strVal = desc.atIndex(i)!.stringValue
            if var uwStrVal = strVal {
                // remove " — Edited" suffix if it exists
                if uwStrVal.hasSuffix(" — Edited") {
                    uwStrVal.removeSubrange(uwStrVal.lastIndex(of: "—")!...)
                    uwStrVal.removeLast()
                }
                arr.append(uwStrVal)
            }
        }
        
        return arr
    }
    return nil
}

func getActiveFilename() -> String? {
    let activeApplicationVersion = """
        tell application (path to frontmost application as Unicode text)
            if name is "Xcode" then
                get version
            end if
        end tell
    """
    let result = NSAppleScript(source: activeApplicationVersion)?.executeAndReturnError(nil)
    let version = result?.stringValue?.split(separator: ".")
//    print(version?[0], version?[1])
    
    guard let fileNames = runAPScript(.documentNames) else {
        return nil
    }
    
    guard var windowNames = runAPScript(.windowNames) else {
        return nil
    }
    
    //Hotfix for Xcode 13.2.1
    if Int(version?[0] ?? "12") == 13 && (Int(version?[1] ?? "5") ?? 5) >= 2 {
        var correctedNames = [String]()
        for var windowName in windowNames {
            if let index = windowName.firstIndex(of: "—") { // — is a special character not - DO NOT GET CONFUSED
                windowName.removeSubrange(...index)
                windowName.removeFirst()
                correctedNames.append(windowName)
            }
        }
        windowNames = correctedNames
    }
//    print("\n\tFile Names: \(fileNames)\n\tWindow Names: \(windowNames)\n")
    
    // find the first window title that matches a filename
    // (the first window name is the one in focus)
    for window in windowNames {
        // make sure the focused window refers to a file
        for file in fileNames {
            if file == window {
                return file
            }
        }
    }

    return nil
}

func getActiveWorkspace() -> String? {
    if let awd = runAPScript(.activeWorkspaceDocument), awd.count >= 2 {
        return awd[1]
    }
    return nil
}

func getActiveWindow() -> String? {
    let activeApplication = """
        tell application "System Events"
            get the name of every application process whose frontmost is true
        end tell
    """
    
//    get the name of every process whose visible is true
    
    let script = NSAppleScript.init(source: activeApplication)
    let result = script?.executeAndReturnError(nil)

    if let desc = result {
        var arr: [String] = []
        for i in 1...desc.numberOfItems {
            guard let strVal = desc.atIndex(i)!.stringValue else { return "Xcode" }
            arr.append(strVal)
        }
//        print(arr[0])
        return arr[0]
    }
    return ""
}
