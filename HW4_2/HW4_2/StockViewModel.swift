//
//  StockViewModel.swift
//  HW4_2
//
//  Created by Anannya Patra on 08/04/24.
//

import Foundation

import SwiftUI
import Combine

class StockViewModel: ObservableObject {
        @Published var companyProfile: CompanyProfile?
        @Published var quote: Quote?
        @Published var recommendations: [Recommendation] = []
        @Published var news: [NewsResponse] = []
        @Published var companyLogo: UIImage?

        @Published var peers: Peers = []
        @Published var earnings: [Earning] = []
        @Published var autofillResults: [AutofillResult] = []
        @Published var hourData: [HourData] = [] // Assuming "results" array from HourDataResponse
        @Published var chartData: [ChartData] = [] // Assuming "results" array from ChartDataResponse
        @Published var sentiments: [SentimentData] = [] // Assuming you're interested in "data" array within Sentiment
        @Published var holdings: [Holding] = []
        @Published var wishlistItems: [WishlistItem] = []
        @Published var money: [Money] = [] // If you expect multiple money objects; adjust based on actual use

        @Published var isLoading: Bool = false
        @Published var isLoadingInitial: Bool = true
        @Published var errorMessage: String?
        @Published var activeError: ErrorType?
        @Published var quotes: [String: Quote] = [:] // Stores the quotes for each ticker
        @Published var isChartDataLoaded = false
    
        @Published var totalMSPR: Double = 0
        @Published var totalChange: Double = 0
        @Published var positiveMSPR: Double = 0
        @Published var positiveChange: Double = 0
        @Published var negativeMSPR: Double = 0
        @Published var negativeChange: Double = 0

        @Published var searchQuery = ""
        private var searchCancellable: AnyCancellable?
        private var debouncePeriod: TimeInterval = 0.3 // 500ms debounce period
    
    private var loadingOperationsCount = 0 {
        didSet {
            isLoading = loadingOperationsCount > 0
        }
    }

        init() {
            loadData()

            searchCancellable = $searchQuery
                .removeDuplicates()
                .debounce(for: .seconds(debouncePeriod), scheduler: RunLoop.main)
                .sink { [weak self] (searchText) in
                    self?.performSearch(text: searchText)
                }
        }

        func performSearch(text: String) {
            // Avoid searching for empty string
            guard !text.isEmpty else {
                autofillResults = []
                return
            }
            loadAutofill(ticker: text)
        }
    
//    func loadData() {
//        print("Value of isLoadingInitial starting: ", self.isLoadingInitial)
//        self.isLoadingInitial = true
//        print("Value of isLoadingInitial second: ", self.isLoadingInitial)
//
//        print("Inside loadData")
//          // Simulate data fetching
//          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//              print("Inside dispatch")
//              // Data is loaded
//              self.isLoadingInitial = false
//              print("Value of isLoadingInitial last: ", self.isLoadingInitial)
//
//          }
//      }
    
    func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
               self.isLoadingInitial = false
           }
       }

    
    
    var filteredNews: [NewsResponse] {
           news.filter { !$0.image.isEmpty && !$0.url.isEmpty && !$0.headline.isEmpty && !$0.summary.isEmpty }
               .prefix(20)
               .map { $0 }
       }
       
//       func isFirstArticle(_ article: NewsResponse) -> Bool {
//           guard let firstArticleID = news.first?.id else { return false }
//           return article.id == firstArticleID
//       }

    func isFirstArticle(_ article: NewsResponse) -> Bool {
        guard let firstFilteredArticleID = filteredNews.first?.id else { return false }
        return article.id == firstFilteredArticleID
    }
    
    // Add properties for other data types you need

    // Fetch Company Profile
//    func loadCompanyProfile(ticker: String) {
//        isLoading = true
//        NetworkManager.shared.fetchCompanyProfile(ticker: ticker) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let profile):
//                    self?.companyProfile = profile
//                case .failure(let error):
//                    self?.errorMessage = "Failed to load company profile: \(error.localizedDescription)"
//                }
//            }
//        }
//    }
    
    func loadCompanyProfile(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchCompanyProfile(ticker: ticker) { [weak self] result in
            switch result {
            case .success(let profile):
                self?.companyProfile = profile
                // Once profile is fetched, load the logo if URL is present
                if let url = URL(string: profile.logo) {
                    self?.loadLogoImage(from: url)
                } else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to load company profile: \(error.localizedDescription)"
                }
            }
        }
    }

    // New function to load image data
    func loadLogoImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false // Ensure isLoading is set to false regardless of the result
                if let data = data, let image = UIImage(data: data) {
                    self?.companyLogo = image
                } else {
                    self?.errorMessage = error?.localizedDescription ?? "Failed to load logo image."
                }
            }
        }.resume()
    }

    // Fetch Recommendations
    func loadRecommendations(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchRecommendation(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let recommendations):
                    self?.recommendations = recommendations
                case .failure(let error):
                    self?.errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadNews(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchNews(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let newsData):
                    self?.news = newsData
                case .failure(let error):
                    self?.errorMessage = "Failed to load news: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadPeers(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchPeers(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fetchedPeers):
                    self?.peers = fetchedPeers
                case .failure(let error):
                    self?.errorMessage = "Failed to load peers: \(error.localizedDescription)"
                }
            }
        }
    }

    func loadQuote(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchQuote(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let Quotedata):
                    self?.quote = Quotedata
                case .failure(let error):
                    self?.errorMessage = "Failed to load peers: \(error.localizedDescription)"
                }
            }
        }
    }
    
//    func loadQuote(ticker: String, completion: @escaping () -> Void) {
//        isLoading = true
//        NetworkManager.shared.fetchQuote(ticker: ticker) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let Quotedata):
//                    self?.quote = Quotedata
//                case .failure(let error):
//                    self?.errorMessage = "Failed to load peers: \(error.localizedDescription)"
//                }
//                completion() // Notify completion of the task
//            }
//        }
//    }

    func loadEarnings(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchEarnings(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let EarningData):
                    self?.earnings = EarningData
                case .failure(let error):
                    self?.errorMessage = "Failed to load peers: \(error.localizedDescription)"
                }
            }
        }
    }

    func loadSentiments(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchSentiment(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let sentimentResponse):
                    self?.sentiments = sentimentResponse.data
//                    self!.calculateSentiments()
                case .failure(let error):
                    self?.errorMessage = "Failed to load sentiments: \(error.localizedDescription)"
                }
            }
        }
    }

    func loadChartData(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchChartData(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let chartResponse):
                    self?.chartData = chartResponse.results
                    self?.checkIfDataLoadingIsComplete()
                case .failure(let error):
                    self?.errorMessage = "Failed to load chart Data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadHourData(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchHourData(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let hourResponse):
                    self?.hourData = hourResponse.results
                    self?.checkIfDataLoadingIsComplete()
                case .failure(let error):
                    self?.errorMessage = "Failed to load hour data: \(error.localizedDescription)"
                }
            }
        }
    }
    
//    private func checkIfDataLoadingIsComplete() {
//        // Assuming chartData and hourData are both required for isChartDataLoaded to be true
//        if !chartData.isEmpty && !hourData.isEmpty {
//            isChartDataLoaded = true
//        }
//    }
    
    private func checkIfDataLoadingIsComplete() {
        print("Checking if data loading is complete.")
        if !chartData.isEmpty && !hourData.isEmpty {
            print("Data is loaded. ChartData count: \(chartData.count), HourData count: \(hourData.count)")
            isChartDataLoaded = true
        }
    }

    
    func loadQuotesForRelevantTickers() {
            let allTickers = Set(holdings.map { $0.ticker } + wishlistItems.map { $0.ticker })
            for ticker in allTickers {
                fetchQuote(ticker: ticker)
            }
        }

        // Adjust the fetchQuote method to save the quotes in the dictionary
        func fetchQuote(ticker: String) {
            NetworkManager.shared.fetchQuote(ticker: ticker) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let quote):
                        self?.quotes[ticker] = quote
                    case .failure(let error):
                        self?.handleFailure(error)
                    }
                }
            }
        }
        
        // Method to calculate the total value of the stocks owned
        var totalStockValue: Double {
            return holdings.reduce(0) { total, holding in
                let quote = quotes[holding.ticker]
                return total + (quote?.c ?? 0) * Double(holding.quantity)
            }
        }
        
        // Method to calculate net worth
        var netWorth: Double {
            guard let cashBalance = money.first?.money else { return 0 }
            return cashBalance + totalStockValue
        }
    
    func loadAutofill(ticker: String) {
        isLoading = true
        NetworkManager.shared.fetchAutofill(ticker: ticker) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let autofillResponse):
//                    self?.autofillResults = autofillResponse.result
                    self?.autofillResults = autofillResponse.result.filter { result in
                                        result.type == "Common Stock" && !result.symbol.contains(".")
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to load autofill: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadWishlist(completion: @escaping () -> Void) {
            isLoading = true
            NetworkManager.shared.fetchWishlist { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let wishlistResponse):
                        self?.wishlistItems = wishlistResponse
                        completion() // Call completion handler here, once the wishlist is loaded
                    case .failure(let error):
                        self?.errorMessage = "Failed to load wishlist: \(error.localizedDescription)"
                        completion() // Also call completion in the case of an error
                    }
                }
            }
        }
    
    func checkWishlistStatus(ticker: String, completion: @escaping (Bool) -> Void) {
        loadWishlist { [weak self] in
            guard let self = self else { return }
            let wishlistTickers = self.wishlistItems.map { $0.ticker }
            let isInWishlist = wishlistTickers.contains(ticker)
            completion(isInWishlist)
        }
    }

        func loadHoldings(completion: @escaping () -> Void) {
            isLoading = true
            NetworkManager.shared.fetchHoldings { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let holdingResponse):
                        self?.holdings = holdingResponse
                        completion() // Call completion handler here, once the holdings are loaded
                    case .failure(let error):
                        self?.errorMessage = "Failed to load holdings: \(error.localizedDescription)"
                        completion() // Also call completion in the case of an error
                    }
                }
            }
        }
    
    func loadMoney() {
        isLoading = true
        NetworkManager.shared.fetchMoney() { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let moneyResponse):
                    self?.money = moneyResponse
                case .failure(let error):
                    self?.errorMessage = "Failed to load money: \(error.localizedDescription)"
                }
            }
        }
    }
 
//    func modifyHoldingItem(ticker: String, quantity: Int, cost: Double, completion: @escaping (Bool) -> Void) {
////         isLoading = true
//        loadingOperationsCount += 1
//
//        NetworkManager.shared.modifyHoldings(ticker: ticker, quantity: quantity, cost: cost) { [weak self] result in
//            DispatchQueue.main.async {
////                self?.isLoading = false
//                self?.loadingOperationsCount -= 1
//                switch result {
//                case .success(let updatedHolding):
//                    // If quantity becomes zero or negative, remove the holding
//                    if updatedHolding.quantity <= 0 {
//                        self?.holdings.removeAll { $0.ticker == updatedHolding.ticker }
//                    } else {
//                        // Update or append the holding as appropriate
//                        if let index = self?.holdings.firstIndex(where: { $0.ticker == updatedHolding.ticker }) {
//                            self?.holdings[index] = updatedHolding
//                        } else {
//                            self?.holdings.append(updatedHolding)
//                        }
//                    }
//                    completion(true)
//                case .failure(let error):
//                    self?.handleFailure(error)
//                    completion(false)
//                }
//            }
//        }
//    }

//    
//    func modifyHoldingItem(ticker: String, quantity: Int, cost: Double, completion: @escaping (Bool) -> Void) {
//        loadingOperationsCount += 1  // Ensure this counter is decremented in all cases
//
//        NetworkManager.shared.modifyHoldings(ticker: ticker, quantity: quantity, cost: cost) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.loadingOperationsCount -= 1  // Decrement on completion of the network request
//                switch result {
//                case .success(let updatedHolding):
//                    // If quantity becomes zero or negative, remove the holding
//                    if updatedHolding.quantity <= 0 {
//                        self?.holdings.removeAll { $0.ticker == updatedHolding.ticker }
//                    } else {
//                        // Update or append the holding as appropriate
//                        if let index = self?.holdings.firstIndex(where: { $0.ticker == updatedHolding.ticker }) {
//                            self?.holdings[index] = updatedHolding
//                        } else {
//                            self?.holdings.append(updatedHolding)
//                        }
//                    }
//                    completion(true)
//                case .failure(let error):
//                    self?.handleFailure(error)
//                    completion(false)
//                }
//            }
//        }
//    }
    
    func modifyHoldingItem(ticker: String, quantity: Int, cost: Double, completion: @escaping (Bool) -> Void) {
        loadingOperationsCount += 1  // Increment operation count
        print("Starting modifyHoldingItem for \(ticker) with quantity \(quantity)")

        NetworkManager.shared.modifyHoldings(ticker: ticker, quantity: quantity, cost: cost) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    print("Self is nil, exiting modifyHoldingItem")
                    return
                }

                self.loadingOperationsCount -= 1  // Decrement on completion
                print("modifyHoldings network call completed for \(ticker)")

                switch result {
                case .success(let updatedHolding):
                    print("Successfully modified holding for \(ticker): new quantity \(updatedHolding.quantity)")
                    if updatedHolding.quantity <= 0 {
                        self.holdings.removeAll { $0.ticker == updatedHolding.ticker }
                        print("Removed \(ticker) from holdings as quantity is zero or less")
                    } else {
                        if let index = self.holdings.firstIndex(where: { $0.ticker == updatedHolding.ticker }) {
                            self.holdings[index] = updatedHolding
                            print("Updated \(ticker) in holdings")
                        } else {
                            self.holdings.append(updatedHolding)
                            print("Added \(ticker) to holdings")
                        }
                    }
                    completion(true)
                case .failure(let error):
                    print("Failed to modify holding for \(ticker) with error: \(error)")
                    self.handleFailure(error)
                    completion(false)
                }
            }
        }
    }




    
    func updateMoneyAmount(money: Double, completion: @escaping (Bool) -> Void) {
        //isLoading = true
        loadingOperationsCount += 1

        NetworkManager.shared.updateMoney(money: money) { [weak self] result in
            DispatchQueue.main.async {
                //self?.isLoading = false
                self?.loadingOperationsCount -= 1
                switch result {
                case .success(let updatedMoney):
                    print("Success updating money")
                    self?.money = [updatedMoney]
                    completion(true)// Replaces any existing money values
                case .failure(let error):
                    self?.handleFailure(error)
                    completion(false)
                }
            }
        }
    }
    
//    func handleFailure(_ error: Error) {
//            // Convert your error into the new ErrorType
//            self.activeError = ErrorType(message: error.localizedDescription)
//        }
        
        // Add the initial setup to load all the necessary data for the portfolio and wishlist
        func initialSetup() {
            loadMoney()
            loadHoldings { self.loadQuotesForRelevantTickers() }
            loadWishlist { self.loadQuotesForRelevantTickers() }
        }



    func modifyWishlistItem(ticker: String, name: String?) {
//        isLoading = true
        // Call the NetworkManager to modify the wishlist, passing nil for 'name' when deleting
        NetworkManager.shared.modifyWishlist(ticker: ticker, name: name) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let wishlistItem):
                    if let _ = name {
                        // If name is provided, it's an add operation
                        self?.wishlistItems.append(wishlistItem)
                    } else {
                        // If no name is provided, it's a delete operation
                        self?.wishlistItems.removeAll { $0.ticker == ticker }
                    }
                case .failure(let error):
                    // If there's an error, handle it
                    self?.handleFailure(error)
                }
            }
        }
    }

    func deleteWishlistItem(at offsets: IndexSet) {
        // Map the IndexSet to an array of items that should be deleted
        let itemsToDelete = offsets.map { wishlistItems[$0] }
        
        // Iterate over each item to delete and call modifyWishlistItem for each
        itemsToDelete.forEach { item in
            modifyWishlistItem(ticker: item.ticker, name: nil) // Passing nil for 'name' to indicate deletion
        }
        // Remove the items from the local array to update the UI immediately
        wishlistItems.remove(atOffsets: offsets)
    }
    
    func moveWishlistItem(from source: IndexSet, to destination: Int) {
        withAnimation {
            wishlistItems.move(fromOffsets: source, toOffset: destination)
        }
            // Here, add any logic if you need to persist this new order to a database or backend
        }
        
        // Method to reorder holdings items
        func moveHoldingItem(from source: IndexSet, to destination: Int) {
            holdings.move(fromOffsets: source, toOffset: destination)
            // Similar to above, add any additional logic if required
        }

    
    func handleFailure(_ error: Error) {
        DispatchQueue.main.async {
            // Update the view model state to reflect the error
            self.errorMessage = error.localizedDescription
            // You can also set a flag to show an error message in the UI, etc.
            // e.g., self.showErrorAlert = true
        }
    }
    
//        .onAppear {
//           //checkWishlistStatus()
//           if viewModel.holdings.isEmpty {
//                  viewModel.loadHoldings {
//                      // Empty completion handler because no additional action is needed here
//                  }
//           }
//           // Triggers the loading of chart data when the view appears
//           viewModel.loadMoney()
//           viewModel.loadChartData(ticker: ticker)
//           viewModel.loadHourData(ticker: ticker)
//           viewModel.loadCompanyProfile(ticker: ticker)
//           viewModel.loadQuote(ticker: ticker)
//           viewModel.loadPeers(ticker: ticker)
//           viewModel.loadSentiments(ticker: ticker)
//           viewModel.loadRecommendations(ticker: ticker)
//           viewModel.loadEarnings(ticker: ticker)
//           viewModel.loadNews(ticker: ticker)
//           //viewModel.loadHoldings(completion: <#T##() -> Void#>)
//           viewModel.checkWishlistStatus(ticker: ticker) { isInWishlist in
//                   self.isInWishlist = isInWishlist
//               }
//           //viewModel.loadHoldings(completion: <#T##() -> Void#>)
//       }
    
    func loadAllData(ticker: String, completion: (() -> Void)? = nil) {
        isLoading = true

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        loadMoney()
        dispatchGroup.leave()

        dispatchGroup.enter()
        loadCompanyProfile(ticker: ticker)
        dispatchGroup.leave()
        
        dispatchGroup.enter()
        loadHoldings {
        dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        loadQuote(ticker: ticker)
        dispatchGroup.leave()
        
        dispatchGroup.enter()
        loadPeers(ticker: ticker)
        dispatchGroup.leave()
        
        dispatchGroup.enter()
        loadSentiments(ticker: ticker)
        dispatchGroup.leave()
        
//        dispatchGroup.enter()
//        print("Calculate Sentiments")
//        calculateSentiments()
//        dispatchGroup.leave()
        
        dispatchGroup.enter()
        loadRecommendations(ticker: ticker)
        dispatchGroup.leave()

        dispatchGroup.enter()
        loadNews(ticker: ticker)
        dispatchGroup.leave()

        
        dispatchGroup.enter()
        loadEarnings(ticker: ticker)
        dispatchGroup.leave()
        
        // Add other necessary data loading calls here with dispatchGroup.enter() and dispatchGroup.leave()
        
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
            self.loadChartData(ticker: ticker)
            self.loadHourData(ticker: ticker)

            completion?()
        }
    }
    
//    func calculateSentiments() {
//        self.totalMSPR = 0
//        self.totalChange = 0
//        self.positiveMSPR = 0
//        self.positiveChange = 0
//        self.negativeMSPR = 0
//        self.negativeChange = 0
//                
//        for sentiment in sentiments {
//
//            self.totalMSPR += Double(sentiment.mspr)
//
//            self.totalChange += Double(sentiment.change)
//            
//            if sentiment.mspr >= 0 {
//                self.positiveMSPR += Double(sentiment.mspr)
//                self.positiveChange += Double(sentiment.change)
//            } else {
//                self.negativeMSPR += Double(sentiment.mspr)
//                self.negativeChange += Double(sentiment.change)
//            }
//        }
//    }

    
//    func loadMoney(completion: @escaping () -> Void) {
//        isLoading = true
//        NetworkManager.shared.fetchMoney() { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let moneyResponse):
//                    self?.money = moneyResponse
//                    completion()
//                case .failure(let error):
//                    self?.errorMessage = "Failed to load money: \(error.localizedDescription)"
//                    completion()
//                }
//            }
//        }
//    }
    
//
//    func modifyWishlistItem(ticker: String, name: String, isAdding: Bool) {
//        isLoading = true
//        NetworkManager.shared.modifyWishlist(ticker: ticker, name: name, isAdding: isAdding) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let wishlistItem):
//                    if isAdding {
//                        self?.wishlistItems.append(wishlistItem)
//                    } else {
//                        self?.wishlistItems.removeAll { $0.ticker == wishlistItem.ticker }
//                    }
//                case .failure(let error):
//                    self?.handleFailure(error)
//                }
//            }
//        }
//    }

//    func modifyHoldingItem(ticker: String, quantity: Int, cost: Double, isAdding: Bool) {
//        isLoading = true
//        NetworkManager.shared.modifyHoldings(ticker: ticker, quantity: quantity, cost: cost, isAdding: isAdding) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let holding):
//                    if isAdding {
//                        self?.holdings.append(holding)
//                    } else {
//                        self?.holdings.removeAll { $0.ticker == holding.ticker }
//                    }
//                case .failure(let error):
//                    self?.handleFailure(error)
//                }
//            }
//        }
//    }

//    func updateMoneyAmount(money: Double) {
//        isLoading = true
//        NetworkManager.shared.updateMoney(money: money) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let updatedMoney):
//                    self?.money = [updatedMoney]
//                case .failure(let error):
//                    self?.handleFailure(error)
//                }
//            }
//        }
//    }
    
//    func modifyWishlistItem(ticker: String, name: String?) {
//        isLoading = true
//        NetworkManager.shared.modifyWishlist(ticker: ticker, name: name) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let wishlistItem):
//                    if let name = name {
//                        // If name is provided, it's an add operation
//                        self?.wishlistItems.append(wishlistItem)
//                    } else {
//                        // If no name is provided, it's a delete operation
//                        self?.wishlistItems.removeAll { $0.ticker == ticker }
//                    }
//                case .failure(let error):
//                    self?.handleFailure(error)
//                }
//            }
//        }
//    }
    
    
//    func deleteWishlistItem(at offsets: IndexSet) {
//        // First, get the items you want to delete.
//        let itemsToDelete = offsets.map { wishlistItems[$0] }
//
//        // Iterate over each item and perform the deletion.
//        itemsToDelete.forEach { item in
//            modifyWishlistItem(ticker: item.ticker, name: nil) { [weak self] result in
//                DispatchQueue.main.async {
//                    switch result {
//                    case .success(_):
//                        // Success case
//                        self?.wishlistItems.removeAll { $0.ticker == item.ticker }
//                        // You may want to add more UI update logic here
//                    case .failure(let error):
//                        // Handle error case
//                        self?.handleFailure(error)
//                    }
//                }
//            }
//
//            }
//        }
//    }

    
//    func deleteWishlistItem(ticker: String) {
//        // Call the NetworkManager to delete the item from the backend.
//        // Note: This assumes your backend will interpret a POST with a nil name as a delete operation.
//        NetworkManager.shared.modifyWishlist(ticker: ticker, name: nil) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success:
//                    // Remove the item from the local array if the backend confirms deletion.
//                    self?.wishlistItems.removeAll { $0.ticker == ticker }
//                case .failure(let error):
//                    self?.handleFailure(error)
//                }
//            }
//        }
//    }
//
//    func deleteWishlistItem(at offsets: IndexSet) {
//        // Assuming you can identify items uniquely by their index.
//        for index in offsets {
//            let ticker = wishlistItems[index].ticker
//            deleteWishlistItem(ticker: ticker)
//        }
//    }
    
//    func modifyHoldingItem(ticker: String, quantity: Int, cost: Double, completion: @escaping (Bool) -> Void) {
//        //isLoading = true
//        loadingOperationsCount += 1
//
//        NetworkManager.shared.modifyHoldings(ticker: ticker, quantity: quantity, cost: cost) { [weak self] result in
//            DispatchQueue.main.async {
//                //self?.isLoading = false
//                self?.loadingOperationsCount -= 1
//                switch result {
//                case .success(let updatedHolding):
//                    if let index = self?.holdings.firstIndex(where: { $0.ticker == updatedHolding.ticker }) {
//                        self?.holdings[index] = updatedHolding
//                    } else {
//                        self?.holdings.append(updatedHolding)
//                    }
//                    completion(true)
//                case .failure(let error):
//                    self?.handleFailure(error)
//                    completion(false)
//                }
//            }
//        }
//    }

    
}
