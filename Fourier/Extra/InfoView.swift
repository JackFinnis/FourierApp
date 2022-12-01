//
//  WelcomeView.swift
//  Location
//
//  Created by Jack Finnis on 27/07/2022.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showShareSheet = false
    
    let firstLaunch: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .cornerRadius(15)
                        .padding(.bottom)
                    Text((firstLaunch ? "Welcome to " : "") + NAME)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 5)
                    if !firstLaunch {
                        Text("Version " + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""))
                            .foregroundColor(.secondary)
                    }
                }
                .horizontallyCentred()
                
                Group {
                    Spacer()
                    SummaryRow("Draw Fourier Squiggles", description: "Draw a shape with your finger and I will squigglify it", systemName: "pencil.and.outline")
                    SummaryRow("Import a Silhouette", description: "Convert an image of a silhouette to a squiggle", systemName: "photo")
                    
                    Button {
                        open3b1b()
                    } label: {
                        SummaryRow("Inspired by 3Blue1Brown", description: "Learn the maths behind the Complex Fourier Series ", systemName: "lightbulb", linkText: "here")
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Spacer()
                    Spacer()
                }
                
                if firstLaunch {
                    Button {
                        dismiss()
                    } label: {
                        Text("Start Drawing!")
                            .bigButton()
                    }
                } else {
                    Menu {
                        Button {
                            Store.writeReview()
                        } label: {
                            Label("Write a Review", systemImage: "quote.bubble")
                        }
                        Button {
                            Store.requestRating()
                        } label: {
                            Label("Rate \(NAME)", systemImage: "star")
                        }
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share with a Friend", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Text("Contribute...")
                            .bigButton()
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !firstLaunch {
                        Button("Done") {
                            dismiss()
                        }
                        .font(.body.bold())
                    }
                }
                ToolbarItem(placement: .principal) {
                    if !firstLaunch {
                        DraggableBar()
                    } else {
                        Text("")
                    }
                }
            }
        }
        .shareSheet(url: APP_URL, isPresented: $showShareSheet)
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    func open3b1b() {
        if let url = URL(string: "https://youtu.be/r6sGWTCMz2k") {
            UIApplication.shared.open(url)
        }
    }
}

struct SummaryRow: View {
    let title: String
    let description: String
    let systemName: String
    let linkText: String
    
    init(_ title: String, description: String, systemName: String, linkText: String = "") {
        self.title = title
        self.systemName = systemName
        self.description = description
        self.linkText = linkText
    }
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundColor(.secondary) +
                Text(linkText)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical)
    }
}
