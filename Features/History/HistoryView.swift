//
//  HistoryView.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

struct HistoryView: View {
    
    @State private var viewModel: HistoryViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.scans.isEmpty {
                EmptyHistoryView()
            } else {
                HistoryList(
                    scans: viewModel.scans
                )
            }
        }
    }
}
