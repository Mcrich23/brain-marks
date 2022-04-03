//
//  AddURLView.swift
//  brain-marks
//
//  Created by PRABALJIT WALIA     on 11/04/21.
//

import SwiftUI
import UIKit

enum AddURLViewSender: Equatable {
    case categoryList
    case category(category: AWSCategory)
}

struct AddURLView: View {
    @State private var showingAlert = false
    @State private var selectedCategory = AWSCategory(name: "")
    @State var newEntry = ""
    @Environment(\.presentationMode) var presentationMode
    let categories: [AWSCategory]
    
    let sender: AddURLViewSender // Gets where AddURLView is being shown to decide what to show
    
    @StateObject var viewModel = AddURLViewModel()
    
    let pasteBoard = UIPasteboard.general
    
    var body: some View {
        NavigationView {
            Form {
                TextField("EnterCopiedURL", text: $newEntry)
                    .autocapitalization(.none)
                if sender == .categoryList {
                    Picker(selection: $selectedCategory , label: Text("Category"), content: {
                        ForEach(categories,id:\.self) { category in
                            Text(category.name).tag(category.id)
                        }
                    })
                }
            }
            .navigationTitle(Text("Add Tweet URL"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if selectedCategory.name == "" {
                        viewModel.alertItem = AlertContext.noCategory
                        showingAlert = true
                    } else {
                        viewModel.fetchTweet(url: newEntry) { result in
                            switch result {
                            case .success(let tweet):
                                
                                DataStoreManger.shared.fetchCategories { (result) in
                                    if case .success = result {
                                        DataStoreManger.shared.createTweet(
                                            tweet: tweet,
                                            category: selectedCategory)
                                    }
                                    presentationMode.wrappedValue.dismiss()
                                }
                                
                            case .failure:
                                viewModel.alertItem = AlertContext.badURL
                            }
                        }
                    }
                })
        }
        .onAppear {
            switch sender {
            case .categoryList:
                break
            case .category(let category):
                selectedCategory = category // Set category to current category
            }
            DispatchQueue.main.async {
                newEntry = pasteBoard.string ?? ""
            }
        }
        .onDisappear {
            selectedCategory.name = ""
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(title: Text(alertItem.title),
                  message: Text(alertItem.message),
                  dismissButton: alertItem.dismissButon) 
        }
    }
}
