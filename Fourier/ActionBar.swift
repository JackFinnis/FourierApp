//
//  UpdateNBar.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI
import Photos

struct ActionBar: View {
    @EnvironmentObject var vm: ViewModel
    @AppStorage("boldLines") var boldLines = true
    @State var showPermissionAlert = false
    @State var showFailedAlert = false
    
    var pathShowing: Bool { vm.fourierPath != nil }
    
    var settingsMenu: some View {
        Menu {
            Button {
                vm.showInfoView = true
            } label: {
                Label("About Fourier", systemImage: "info.circle")
            }
            
            Menu("Import File...") {
                Button("Example Squiggle") {
                    vm.showExampleSquiggle()
                }
                
                Button {
                    vm.showSVGImporter = true
                } label: {
                    Label("SVG File", systemImage: "pencil.and.outline")
                }
                
                Button {
                    vm.showImagePicker = true
                } label: {
                    Label("Silhouette Image", systemImage: "photo")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if pathShowing {
                HStack {
                    ColorPicker(selection: $vm.strokeColour) {
                        HStack {
                            Text(Int(vm.N-1).formattedPlural("Epicycle"))
                            Spacer()
                            Stepper("", value: $vm.N, in: vm.nRange) { stepping in
                                if !stepping { vm.transform() }
                            }
                        }
                    }
                    Menu {
                        if pathShowing {
                            if #available(iOS 15, *) {
                                Button(role: .destructive) {
                                    vm.reset()
                                } label: {
                                    Label("Reset", systemImage: "xmark")
                                }
                            } else {
                                Button {
                                    vm.reset()
                                } label: {
                                    Label("Reset", systemImage: "xmark")
                                }
                            }
                            
                            Button {
                                vm.copyCoefficients()
                            } label: {
                                Label(vm.copiedCoefficients ? "Copied Coefficients" : "Copy Coefficients", systemImage: vm.copiedCoefficients ? "checkmark.circle.fill" : "doc.on.doc")
                            }
                            .disabled(vm.copiedCoefficients)
                            
                            Button(action: saveImage) {
                                Label(vm.savedImage ? "Saved to Photos" : "Save to Photos", systemImage: vm.savedImage ? "checkmark.circle.fill" : "square.and.arrow.down")
                            }
                            .disabled(vm.savedImage)
                        }
                        
                        Button {
                            withAnimation {
                                boldLines.toggle()
                            }
                        } label: {
                            Label((boldLines ? "Thinner" : "Thicker") + " Lines", systemImage: "lineweight")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                    }
                    settingsMenu
                }
                .padding(.top, 10)
                
                Slider(value: $vm.N, in: vm.nRange, step: 1) { sliding in
                    if !sliding { vm.transform() }
                }
            } else if !vm.drawing {
                HStack(alignment: .top) {
                    Text("Draw a shape in the space above with your finger or upload a picture of a silhouette or an svg file and I will squigglify it!")
                        .font(.subheadline)
                    Spacer(minLength: 10)
                    settingsMenu
                }
                .onTapGesture {
                    vm.showImagePicker = true
                }
            } else {
                Rectangle()
                    .foregroundColor(Color(UIColor.systemBackground))
            }
        }
        .frame(height: 80)
        .padding(.horizontal)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .background(
            Group {
                Text("")
                    .alert(isPresented: $showPermissionAlert) {
                        Alert(title: Text("Access Denied"), message: Text("Please go to Settings > Privacy > Photos to allow \(NAME) to add to your photo library."), primaryButton: .default(Text("Close")), secondaryButton: .default(Text("Settings"), action: openSettings))
                    }
                Text("")
                    .alert(isPresented: $showFailedAlert) {
                        Alert(title: Text("Save Failed"), message: Text("Please try saving a different drawing."), dismissButton: .default(Text("Ok")))
                    }
            }
        )
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func saveImage() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    showPermissionAlert = true; return
                }
                guard let view = vm.fourierPath?.stroke(Color.accentColor, lineWidth: 3),
                      let image = view.snapshot()
                else { showFailedAlert = true; return }
                
                Task {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    Haptics.tap()
                    withAnimation {
                        vm.savedImage = true
                    }
                }
            }
        }
    }
}
