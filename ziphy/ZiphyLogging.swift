// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation



@objc public enum ZiphyLogLevel: Int, Comparable {
    
    case verbose = 0
    case debug
    case info
    case warning
    case error
}


public func ==(x: ZiphyLogLevel, y: ZiphyLogLevel) -> Bool { return x.rawValue == y.rawValue }
public func <(x: ZiphyLogLevel, y: ZiphyLogLevel) -> Bool { return x.rawValue < y.rawValue }



func Log(_ message: String,
    function: String = #function,
    file: String = #file,
    line: Int = #line,
    level:ZiphyLogLevel) {
        
        if ZiphyClient.logLevel <= level {
            
            NSLog("%@", "\"\(message)\" (File: \(file), Function: \(function), Line: \(line))")
        }
}

func LogVerbose(_ message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.verbose)
}

func LogDebug(_ message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.debug)
}

func LogInfo(_ message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.info)
}

func LogWarn(_ message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.warning)
}

func LogError(_ message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.error)
}
