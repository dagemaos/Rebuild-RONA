//
//  ReportView.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

import SwiftUI

struct ReportView: View {
    
    @State private var viewModel: ReportViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let report = viewModel.reportData {
                ReportContent(report: report)
            } else if viewModel.error != nil {
                ReportErrorView()
            }
        }
    }
}

struct ReportContent: View {
    let report: ReportData
    
    var body: some View {
        Text("Report Content")
    }
}

struct ReportErrorView: View {
    var body: some View {
        Text("Error loading report")
    }
}
