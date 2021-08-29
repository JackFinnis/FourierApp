//
//  PhotoButton.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI

struct PhotoButton: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        Button {
            vm.reset()
            vm.showImagePicker = true
        } label: {
            if vm.loading {
                ProgressView()
                    .font(.system(size: 25))
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: vm.recentlyFailed ? "xmark" : "photo")
                    .font(.system(size: 25))
                    .frame(width: 60, height: 60)
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(Circle())
        .compositingGroup()
        .shadow(color: Color(UIColor.systemFill), radius: 5)
        .padding()
    }
}
