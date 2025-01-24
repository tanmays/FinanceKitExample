# FinanceKitExample
This example is created to help me debug an issue where I'm unable to fetch transactions. Since the country I live in doesn't yet have Apple Card support, I'm unable to test the code myself.
 
 Requirements:
 - iOS 17.4 and above
 - Run on a physical device with Apple Card added to your wallet
 - Valid FinanceKit entitlements granted by Apple
 
 Change the bundle identifier of the project to match the entitlements that Apple has granted to your developer account.
 
 FinanceKitManager.swift inside the FinanceKitManager package is a good place to start setting breakpoints and understand the flow.
