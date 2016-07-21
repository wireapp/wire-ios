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
    
    case Verbose = 0
    case Debug
    case Info
    case Warning
    case Error
}


public func ==(x: ZiphyLogLevel, y: ZiphyLogLevel) -> Bool { return x.rawValue == y.rawValue }
public func <(x: ZiphyLogLevel, y: ZiphyLogLevel) -> Bool { return x.rawValue < y.rawValue }



func Log(message: String,
    function: String = #function,
    file: String = #file,
    line: Int = #line,
    level:ZiphyLogLevel) {
        
        if ZiphyClient.logLevel <= level {
            
            NSLog("%@", "\"\(message)\" (File: \(file), Function: \(function), Line: \(line))")
        }
}

func LogVerbose(message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.Verbose)
}

func LogDebug(message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.Debug)
}

func LogInfo(message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.Info)
}

func LogWarn(message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.Warning)
}

func LogError(message:String,
    function: String = #function,
    file: String = #file,
    line: Int = #line){
        
        Log(message, function:function, file:file, line:line, level: ZiphyLogLevel.Error)
}
