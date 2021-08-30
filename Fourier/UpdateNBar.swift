//
//  UpdateNBar.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI

struct UpdateNBar: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("\(Int(vm.N)-1) Epicycle" + (vm.N == 2 ? "":"s"))
                Spacer()
                Stepper("", value: $vm.N, in: vm.nRange, onEditingChanged: { stepping in
                    if !stepping { vm.updatePath() }
                })
            }
            Slider(value: $vm.N, in: vm.nRange, step: 1, onEditingChanged: { sliding in
                if !sliding { vm.updatePath() }
            })
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .compositingGroup()
        .shadow(color: Color(UIColor.systemFill), radius: 5)
        .padding(.vertical)
        .padding(.trailing)
    }
}
