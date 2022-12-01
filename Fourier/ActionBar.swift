//
//  UpdateNBar.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI

struct ActionBar: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        VStack(spacing: 5) {
            if vm.fourierPath != nil {
                HStack {
                    Text(Int(vm.N-1).formattedPlural("Epicycle"))
                    Spacer()
                    Stepper("", value: $vm.N, in: vm.nRange) { stepping in
                        if !stepping { vm.updatePath() }
                    }
                    
                    Menu {
                        Button {
                            vm.showInfoView = true
                        } label: {
                            Label("About Fourier", systemImage: "info.circle")
                        }
                        Button {
                            vm.reset()
                        } label: {
                            Label("Reset", systemImage: "xmark")
                        }
                        Button {
                            vm.showImagePicker = true
                        } label: {
                            Label("Import Silhouette", systemImage: "photo")
                        }
                        Button {
                            //todo
                        } label: {
                            Label("Copy Formula", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
                .padding(.top, 10)
                
                Slider(value: $vm.N, in: vm.nRange, step: 1) { sliding in
                    if !sliding { vm.updatePath() }
                }
            } else if vm.path.isEmpty {
                Button {
                    vm.showImagePicker = true
                } label: {
                    Text("Draw a shape in the space above with your finger or ") +
                    Text("upload")
                        .foregroundColor(.accentColor) +
                    Text(" a picture of a silhouette and I will squigglify it!")
                }
                .horizontallyCentred()
                .buttonStyle(.plain)
            } else {
                Rectangle()
                    .foregroundColor(Color(UIColor.systemBackground))
            }
        }
        .frame(height: 80)
        .padding(.horizontal)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}
