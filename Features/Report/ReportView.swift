//
//  ReportView.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

struct ReportView: View {
    
    @state private var viewModel: ReportViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let report = viewModel.reportData {
                ReportContent{report: report}
            } else if viewModel.error != nil {
                ReportErrorView()
            }
        }
    }
}
