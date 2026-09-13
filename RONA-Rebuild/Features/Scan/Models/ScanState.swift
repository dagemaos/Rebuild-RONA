//
//  ScanState.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 09/09/26.
//

enum ScanState {
    case idle
    case preparing
    case scanning
    case processing
    case showingResult(ScanResult)
    case failed(ScanError)
}
