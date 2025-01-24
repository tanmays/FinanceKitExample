//
//  ContentView.swift
//  FinanceKitExample
//
//  Created by Tanmay Sonawane on 24/01/25.
//

/**
 INFO: This example is created to help me debug an issue where I'm unable to fetch transactions. Since the country I live in doesn't yet have Apple Card support, I'm unable to test the code myself.
 
 Requirements:
 - iOS 17.4 and above
 - Run on a physical device with Apple Card added to your wallet
 - Valid FinanceKit entitlements granted by Apple
 
 Change the bundle identifier of the project to match the entitlements that Apple has granted to your developer account.
 
 FinanceKitManager.swift inside the FinanceKitManager package is a good place to start setting breakpoints and understand the flow.
 */

import SwiftUI
import FinanceKitManager

struct ContentView: View {
	
	@StateObject private var dataService = FinanceKitManager.shared.dataService
	
    var body: some View {
        VStack {
			// MARK: Finance Kit Prompt
			FinanceKitAvailabilityView().padding()
			
			List {
				// MARK: Accounts
				Section {
					if dataService.accounts.isEmpty {
						Text("No Accounts Found")
					} else {
						Text("Accounts Found: \(dataService.accounts.count)")
						ForEach(dataService.accounts) { account in
							Text(account.title)
						}
					}
				} header: {
					Text("Accounts")
				}
				
				// MARK: Transactions
				Section {
					if dataService.transactions.isEmpty {
						Text("No Transactions Found")
					} else {
						Text("Transactions Found: \(dataService.transactions.count)")
						ForEach(dataService.transactions) { transaction in
							HStack {
								Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
								Text(transaction.desc)
								Text(transaction.amount.formatted(.currency(code: transaction.currencyCode)))
							}
						}
					}
				} header: {
					Text("Transactions")
				}
			}
        }
    }
}

#Preview {
    ContentView()
}


