//
//  LocationView.swift
//  location-manager
//
//  Created by Robert Brennan on 2/28/24.
//

import SwiftUI

struct LocationView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var showNoAddressAlert: Bool = false
    @State private var searchResultsVisible: Bool = false
    @State private var showLocationPermissionPreviouslyRequestedAlert = false
    @State private var hideForLocationSearch = false    // todo rename
    
    
    var body: some View {
        VStack {
            
            HStack {
                ZStack {
                    TextField("Enter location", text: $viewModel.userAddress)
                        .padding()
                        .font(.callout)
                        .fontWeight(.semibold)
                        .autocorrectionDisabled(true)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                        .frame(width: 333)
                        .padding()
                        .border(.blue)
                        .onTapGesture {
                            withAnimation {
                                viewModel.userAddress = ""
                                hideForLocationSearch = true
                            }
                        }
                        .onChange(of: viewModel.userAddress) { newValue in
                            viewModel.searchAddress(newValue)
                            withAnimation {
                                searchResultsVisible = true
                            }
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                if !viewModel.userAddress.isEmpty {
                                    Button {
                                        viewModel.userAddress = ""
                                        viewModel.clearSearchResults()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: 3)
                                            )
                                            .padding(.trailing, 10)
                                            .padding(.bottom, 4)
                                            .background(.white)
                                    }
                                }
                            }
                        )
                    
                    if viewModel.getCurrentLocationInProgress && viewModel.useCurrentLocationTapped {
                        HStack {
                            ProgressView()
                                .tint(Color.green)
                                .padding(.bottom, 4)
                        }
                        .frame(width: 285)
                        .background(.white)
                    }
                }
                
                if hideForLocationSearch {
                    Button {
                        viewModel.userAddress = ""
                        
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        withAnimation {
                            hideForLocationSearch.toggle()
                        }
                    } label: {
                        Image(systemName: "multiply")
                            .resizable()
                            .foregroundColor(.blue)
                            .frame(width: 15, height: 15)
                            .shadow(radius: 1)
                            .padding()
                            .padding(.bottom, 4)
                    }
                }
            }
            
            Button {
                viewModel.userAddress = ""
                viewModel.useCurrentLocationTapped = true
                
                if !(viewModel.locationStatus == .authorizedWhenInUse || viewModel.locationStatus == .authorizedAlways) {
                    if viewModel.locationPermissionDenied {
                        showLocationPermissionPreviouslyRequestedAlert = true
                    } else {
                        viewModel.requestLocationPermission()
                    }
                } else {
                    viewModel.getCurrentLocation()
                }
            } label: {
                Label("Use current location", systemImage: "location.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }.alert("Location Permission", isPresented: $showLocationPermissionPreviouslyRequestedAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Settings", action: {
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                })
            } message: {
                Text("Location permission was previously denied. Go to your iPhone Settings app > Privacy & Security > Location Services > (app name) to change.")
            }
            
            if hideForLocationSearch {
                ScrollView {
                    VStack {
                        ForEach(viewModel.searchResults, id: \.self) { result in
                            HStack {
                                Text("\(result.title), \(result.subtitle)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.subheadline)
                                    .padding(.vertical, 9)
                                
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .frame(width: 8, height: 13)
                            }
                            .background(Color.clear)
                            .onTapGesture {
                                viewModel.selectSearchResult(result)
                                searchResultsVisible = false
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                withAnimation {
                                    hideForLocationSearch = false
                                }
                            }
                            Divider()
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .frame(maxHeight: 500)
            }
        }
    }
}

//#Preview {
//    LocationView()
//}
