//
//  HistoryView.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

import SwiftUI

struct HistoryView: View {
    
    @State private var viewModel: HistoryViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.scans.isEmpty {
                EmptyHistoryView()
            } else {
                HistoryListView(
                    scans: viewModel.scans
                )
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        Text("Belum ada riwayat scan.")
            .foregroundColor(.secondary)
    }
}

struct HistoryListView: View {
    let scans: [ScanRecord]
    
    var body: some View {
        List(scans) { scan in
            Text("Scan \(scan.date, format: .dateTime)")
        }
    }
}
