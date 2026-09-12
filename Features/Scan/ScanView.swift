//
//  ScanView.swift
//  
//
//  Created by Ivanri Fleri Simanjuntak on 03/09/26.
//

struct ScanView: View {
    
    @State private var viewModel: ScanViewModel
    
    var body: some View {
        switch viewModel.state {
        case .idle:
            idleView
            
        case .preparing:
            preparingView
            
        case .scanning:
            scanningView
            
        case .processing:
            processingView
            
        case .showingResult(let result):
            resultView(result)
            
        case .failed(let error):
            errorView(error)
        }
    }
}
