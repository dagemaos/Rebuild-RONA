//
//  HistoryState.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 10/09/26.
//

enum HistoryState {
    case idle
    case loading
    case loaded([ScanRecord])
    case empty
    case failed(Error)
}
