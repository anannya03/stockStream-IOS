//
//  ContentView.swift
//  HW4_2
//
//  Created by Anannya Patra on 08/04/24.
//


import SwiftUI
import Kingfisher

//struct ContentView: View {
//    @ObservedObject var viewModel = StockViewModel()
//    @EnvironmentObject var navigationManager: NavigationManager
//    
//    var body: some View {
//        StocksView(viewModel: viewModel)
//    }
//}

struct ContentView: View {
    @StateObject var viewModel = StockViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoadingInitial {
                ProgressView("Fetching Data...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                StocksView(viewModel: viewModel) // Reintroduce StocksView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            print("ContentView appeared")
        }
    }
}




class NavigationManager: ObservableObject {
    @Published var rootViewID = UUID()

    func resetToRootView() {
        rootViewID = UUID()  // Resetting the ID will refresh the root view
    }
}

struct RoundedSectionHeader: View {
    var title: String
    
    var body: some View {
        Text(title)
            .textCase(nil) // This removes any uppercasing done by list styles
            .font(.system(size: 30, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
            .listRowInsets(EdgeInsets(top: 0, leading: -2, bottom: 0, trailing: -10))
    }
}



struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text)
                .foregroundColor(.primary)
        }
        .padding(10)
        .background(Color(.systemGray5)) // Or any other color you prefer
        .cornerRadius(10)
        // Apply this modifier to remove the default padding around the cell in the list
        .padding(.horizontal, 16)
    }
}


struct FooterView: View {
    var body: some View {
        Button(action: openFinnhub) {
            Text("Powered by FinnHub.io")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.vertical, 20) // Adjust the vertical padding as needed
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 3)
                .padding(.horizontal, 16) // This should match the horizontal padding of your Favourites cards
              // Try setting this to zero if the
        }   .listRowInsets(EdgeInsets(top: 0, leading: -12, bottom: 0, trailing: -12))
    }
    
    func openFinnhub() {
        guard let url = URL(string: "https://www.finnhub.io") else { return }
        UIApplication.shared.open(url)
    }
}

struct StocksView: View {
    @ObservedObject var viewModel: StockViewModel
//    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
            NavigationView {
                Group {
//                    if viewModel.isLoading {
//                        ProgressView("Fetching data...")
////                            .progressViewStyle(CircularProgressViewStyle())
////                            .scaleEffect(1.5)
//                    } else {
                        content
//                    }
                }
//                .id(navigationManager.rootViewID)
                .searchable(text: $viewModel.searchQuery)
                .navigationBarTitle("Stocks", displayMode: .large)
                .onAppear {
                    viewModel.initialSetup()
                }
            }
        }
    
    private var content: some View {
            Group {
                if viewModel.searchQuery.isEmpty {
                    mainContent
                } else {
                    searchResultsView
                }
            }
        }
    
    private var mainContent: some View {
        
        List {
            Section(header: RoundedSectionHeader(title: formattedCurrentDate())) {
                EmptyView()
            }
            
            Section(header: Text("PORTFOLIO").font(.headline)) {
                PortfolioHeaderView(money: viewModel.money.first?.money ?? 0, totalStockValue: viewModel.totalStockValue)

                ForEach(viewModel.holdings, id: \.id) { holding in
                    if let quote = viewModel.quotes[holding.ticker] {
                        HoldingRow(ticker: holding.ticker, holding: holding, quote: quote, viewModel: viewModel)
                    } else {
                        HoldingRowPlaceholder(ticker: holding.ticker)
                    }
                }
                .onMove(perform: viewModel.moveHoldingItem)
            }

            
            
            Section(header: Text("Favorites").font(.headline)) {
                ForEach(viewModel.wishlistItems.indices, id: \.self) { index in
                    if let quote = viewModel.quotes[viewModel.wishlistItems[index].ticker] {
                        WishlistRow(item: viewModel.wishlistItems[index], quote: quote)
                    } else {
                        WishlistRowPlaceholder(ticker: viewModel.wishlistItems[index].ticker)
                    }
                }
                .onMove(perform: viewModel.moveWishlistItem)
                .onDelete(perform: viewModel.deleteWishlistItem)
            }
            
            
            Section(footer: FooterView()) {
                EmptyView()
            }
        }
        .toolbar {
            EditButton()
        }
    }
    
    private var searchResultsView: some View {
        List(viewModel.autofillResults, id: \.symbol) { result in
            NavigationLink(destination: StockDetailView(ticker: result.symbol)) {
                VStack(alignment: .leading) {
                    Text(result.symbol).bold()
                        .font(.system(size: 18))
                    Text(result.description).font(.subheadline).foregroundColor(.gray)
                }
            }
        }
    }
    
}

struct PortfolioHeaderView: View {
    let money: Double
    let totalStockValue: Double

    var body: some View {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Net Worth")
                           
                        Text(formatCurrency(money + totalStockValue))
                            .bold()
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Cash Balance")
                            
                        Text(formatCurrency(money))
                            .bold()
                    }
                }
                .padding(.vertical, 2) // Try reducing the vertical padding to 2 or even 0 to see if it helps
                .padding(.horizontal, 4)
        .background(Color("HeaderBackground")) // Set the background color according to the second image
    }
}

struct HoldingRow: View {
    let ticker: String
    let holding: Holding
    let quote: Quote
    var viewModel: StockViewModel
    
    var avgCostPerShare: Double {
        if let holdings = viewModel.holdings.first(where: { $0.ticker == ticker }), holdings.quantity > 0 {
            return holdings.cost / Double(holdings.quantity)
        }
        return 0 // Or handle it in some other way appropriate for your app
    }
    


    var body: some View {
        NavigationLink(destination: StockDetailView(ticker: holding.ticker, viewModel: viewModel)) {
            
        HStack {
            VStack(alignment: .leading) {
                Text(holding.ticker)
                    .font(.headline)
                Text("\(holding.quantity) shares")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                let totalCost = quote.c * Double(holding.quantity)
                Text(formatCurrency(totalCost))
                    .bold()

                let change = (quote.c - avgCostPerShare) * Double(holding.quantity)
                let changePercent = (change / holding.cost) * 100

                HStack {
                    Image(systemName: change > 0 ? "arrow.up.forward" : change < 0 ? "arrow.down.right" : "minus")
                        .foregroundColor(change != 0 ? (change > 0 ? .green : .red) : .gray)
                    Text("$" + formatChange(change) + " (\(String(format: "%.2f", changePercent))%)")
                        .foregroundColor(change != 0 ? (change > 0 ? .green : .red) : .gray)
                }
            }
        }
        .padding(.vertical, 2) // Try reducing the vertical padding to 2 or even 0 to see if it helps
        .padding(.horizontal, 4)
        .background(Color.clear) // Match the background with the second image
    }
    }
}



struct StockDetailView: View {
    let ticker: String
    @ObservedObject var viewModel: StockViewModel
    private let detailViewModel = StockDetailViewModel()
    @State private var showingNewsDetail = false
    @State private var selectedArticle: NewsResponse?
    @State private var showingTradeScreen = false
    @State private var showToast = false
    @State private var toastText = ""
    
    // Add state for toggling between charts
    @State private var showingHistorical = false
    @State private var articles: [NewsResponse] = []
    @State private var isInWishlist = false
    @State private var showingWishlistConfirmation = false
    
    
    init(ticker: String, viewModel: StockViewModel? = nil) {
        self.ticker = ticker
        self.viewModel = viewModel ?? StockViewModel()
    }
    
    var avgCostPerShare: Double {
        if let holdings = viewModel.holdings.first(where: { $0.ticker == ticker }), holdings.quantity > 0 {
            return holdings.cost / Double(holdings.quantity)
        }
        return 0 // Or handle it in some other way appropriate for your app
    }
    
    
    var body: some View {
        GeometryReader { geometry in
        ScrollView {
            VStack {
                
                if viewModel.isLoading {
                    Spacer(minLength: geometry.size.height / 2) // Half the height to center vertically
                    ProgressView("Fetching data...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: geometry.size.width, alignment: .center) // Center horizontally
                    Spacer(minLength: geometry.size.height / 2)
                    
                } else if let companyProfile = viewModel.companyProfile,
                          let quote = viewModel.quote {
                    // Stock price details
                    // ... (Your existing stock detail code)
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {

                            Text(ticker)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.bottom, 12)
                            
                            Text(companyProfile.name)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 12)
                            
                            // Current price
                            HStack(spacing: 10) {
                                Text("$\(quote.c, specifier: "%.2f")")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                //  .bold()
                                
                                Image(systemName: quote.d >= 0 ? "arrow.up.forward" : "arrow.down.right")
                                    .foregroundColor(quote.d >= 0 ? .green : .red)
                                
                                // Price change in dollars and percentage
                                Text("$\(quote.d >= 0 ? "+" : "")\(quote.d, specifier: "%.2f") (\(quote.dp, specifier: "%.2f")%)")
                                    .foregroundColor(quote.d < 0 ? .red : .green)
                                    .font(.headline)
                            }
                        }
                        Spacer() // Use spacer to push content to the left and logo to the right

                        
                        if let logo = viewModel.companyLogo {
                                Image(uiImage: logo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .padding(.trailing, 20)
                            } 

                    }
                    // .padding(.vertical)
                    .padding([.leading, .top]) // Adjust padding as needed
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .navigationBarTitleDisplayMode(.inline)
                    
                    // Conditional Chart View
                    if viewModel.isChartDataLoaded {
                        if showingHistorical {
                            // Historical Chart View
                            let chartHTML = detailViewModel.prepareChartDataHTML(chartData: viewModel.chartData, ticker: ticker)
                            ChartWebView(htmlContent: chartHTML)
                                .frame(height: 300)
                        } else {
                            // Hourly Chart View
                            let hourlyHTML = detailViewModel.prepareHourlyDataHTML(hourData: viewModel.hourData, ticker: ticker, quote: viewModel.quote!)
                            ChartWebView(htmlContent: hourlyHTML)
                                .frame(height: 300)
                        }
                    } else {
                        // Text("Chart data is not yet available.")
                    }
                    
                    HStack {
                        Button(action: {
                            showingHistorical = false
                        }) {
                            VStack {
                                Image(systemName: "chart.xyaxis.line") // System icon
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(!showingHistorical ? .blue : .gray)
                                Text("Hourly") // Label text
                                    .foregroundColor(!showingHistorical ? .blue : .gray)
                                    .font(.caption)
                            }
                        }
                        
                        // You can adjust the padding value to increase or decrease the space between the buttons
                        .padding(.trailing, 100) // Adjust the right padding to bring the images closer together
                        
                        Button(action: {
                            showingHistorical = true
                        }) {
                            VStack {
                                Image(systemName: "clock.fill") // Use a system icon or your custom icon
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(showingHistorical ? .blue : .gray)
                                Text("Historical") // Label text
                                    .foregroundColor(!showingHistorical ? .gray : .blue)
                                    .font(.caption)
                            }
                        }
                    }
//                    .padding() // Apply padding to the entire HStack if necessary
                    // Adjusting the frame of the HStack itself can also help to control spacing
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    
                    let holdings = viewModel.holdings.first(where: { $0.ticker == ticker })
                    let totalCost = holdings?.cost ?? 0
                    let change = quote.c - avgCostPerShare
                    let marketValue = quote.c * Double(holdings?.quantity ?? 0)
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Portfolio")
                                .font(.system(size: 22))
                            
                            if let holdings = holdings, holdings.quantity > 0 {
                                Group {
                                    Text("Shares Owned:")
                                        .bold()
                                    + Text(" \(holdings.quantity)")
                                    Text("Avg. Cost / Share:")
                                        .bold()
                                    + Text(" $\(avgCostPerShare, specifier: "%.2f")")
                                    
                                    Text("Total Cost:")
                                        .bold()
                                    + Text(" $\(totalCost, specifier: "%.2f")")
                                    
                                    Text("Change:")
                                        .bold()
                                    + Text(" $\(change >= 0 ? "" : "")\(change, specifier: "%.2f")")
                                        .foregroundColor(change > 0 ? .green : (change < 0 ? .red : .black))

                                    
                                    Text("Market Value:")
                                        .bold()
                                    + Text(" $\(marketValue, specifier: "%.2f")")
                                        .foregroundColor((marketValue-totalCost) > 0 ? .green : ((marketValue-totalCost) < 0 ? .red : .black))
                                }
                                
                            } else {
                                Text("You have 0 shares of \(ticker). Start trading!")
                            }
                            
                            //TradeButton() // Assuming TradeButton is a reusable view component
                            
                        }
                        Spacer()
                        TradeButton {
                            print("Trade button was tapped, showingTradeScreen set to true")
                            showingTradeScreen = true
                            print("Trade button was tapped")
                            
                        }.fixedSize()
                            .sheet(isPresented: $showingTradeScreen) {  // <-- Add this sheet modifier
                                TradeView(viewModel: viewModel, ticker: ticker)
                                       .onAppear {
                                           print("TradeView appeared")
                                       }
                                       .onDisappear {
                                           print("TradeView disappeared")
                                           showingTradeScreen = false  // Ensure it's reset when the view disappears
                                       }
                                
                            }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground)) // Adjust this for your theme
                    
                    if let quote = viewModel.quote {
                        
                        VStack(alignment: .leading, spacing: 12) { // Increase this spacing for space between lines
                            Text("Stats")
                                .font(.system(size: 22))
                                .padding(.leading)
                            
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 16) { // Increase this for more space between High Price and Low Price
                                    HStack {
                                        Text("High Price:") .bold()
                                        Spacer().frame(width: 8) // Adjust this width for space between label and value
                                        Text("$\(quote.h, specifier: "%.2f")")
                                    }
                                    HStack {
                                        Text("Low Price:").bold()
                                        Spacer().frame(width: 8) // Same as above
                                        Text("$\(quote.l, specifier: "%.2f")")
                                    }
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                
                                Spacer().frame(width: 24) // Adjust this width for space between the end of High Price's value and "Open Price"
                                
                                VStack(alignment: .leading, spacing: 16) { // Same as above for the space between Open Price and Prev. Close
                                    HStack {
                                        Text("Open Price:").bold()
                                        Spacer().frame(width: 8) // Adjust this width for space between label and value
                                        Text("$\(quote.o, specifier: "%.2f")")
                                    }
                                    HStack {
                                        Text("Prev. Close:").bold()
                                        Spacer().frame(width: 8) // Same as above
                                        Text("$\(quote.pc, specifier: "%.2f")")
                                    }
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                            .padding([.leading, .trailing])
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        
                    }
                    
                    // About Section
                    if let companyProfile = viewModel.companyProfile {
                        VStack(alignment: .leading, spacing: 12) { // Control the space between the rows
                            Text("About")
                                .font(.system(size: 22))
                            
                            HStack(alignment: .top, spacing: 16) { // Control the space between the label and value columns
                                // VStack for labels
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("IPO Start Date:").bold()
                                    Text("Industry:").bold()
                                    Text("Webpage:").bold()
                                    Text("Company Peers:").bold()
                                }
                                
                                // VStack for values
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(companyProfile.ipo)
                                    Text(companyProfile.finnhubIndustry)
                                    Link(viewModel.companyProfile?.weburl ?? "", destination: URL(string: viewModel.companyProfile?.weburl ?? "")!)
                                        .foregroundColor(.blue)
                                    ScrollView(.horizontal, showsIndicators: true) {
                                        HStack(spacing: 10) {
                                            ForEach(viewModel.peers, id: \.self) { peer in
                                                NavigationLink(destination: StockDetailView(ticker: peer, viewModel: StockViewModel())) {
                                                    Text(peer + ",")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 20) // Increase this padding to add more space between label and value
                            }
                        }
                        .padding() // Apply padding to the entire VStack if necessary
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        
                    }
                    
                    Spacer()
                    
                    if !viewModel.sentiments.isEmpty, let companyProfile = viewModel.companyProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Insights")
                                .font(.title2)
                            HStack {
                                Spacer()
                                Text("Insider Sentiments")
                                    .font(.title2)
                                Spacer()
                            }
                            
                            
                            Spacer()
                            
                            //                             Calculating the total, positive, and negative values
                            let totalMSPR = viewModel.sentiments.map { $0.mspr }.reduce(0, +)
                            let totalChange = viewModel.sentiments.map { Double($0.change) }.reduce(0, +)
                            let positiveMSPR = viewModel.sentiments.filter { $0.mspr > 0 }.map { $0.mspr }.reduce(0, +)
                            let positiveChange = viewModel.sentiments.filter { $0.change > 0 }.map { Double($0.change) }.reduce(0, +)
                            let negativeMSPR = viewModel.sentiments.filter { $0.mspr < 0 }.map { $0.mspr }.reduce(0, +)
                            let negativeChange = viewModel.sentiments.filter { $0.change < 0 }.map { Double($0.change) }.reduce(0, +)
                            
                            // Creating views for the values
                            HStack {
                                Text(companyProfile.name)
                                    .bold()
                                Spacer()
                                Text("MSPR")
                                    .bold()
                                Spacer()
                                Text("Change")
                                    .bold()
                            }
                            
                            Divider()
                            
                            SentimentRow(title: "Total", mspr: totalMSPR, change: totalChange)
                            SentimentRow(title: "Positive", mspr: positiveMSPR, change: positiveChange)
                            SentimentRow(title: "Negative", mspr: negativeMSPR, change: negativeChange)
                            
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Assuming recommendations and earnings are non-optional in your view model
                    let recommendationChartHTML = detailViewModel.generateRecHTML(forRecommendations: viewModel.recommendations)
                    ChartWebView(htmlContent: recommendationChartHTML)
                        .frame(height: 280)
                    
                    let earningsChartHTML = detailViewModel.generateEarningsChartHTML(earnings: viewModel.earnings)
                    ChartWebView(htmlContent: earningsChartHTML)
                        .frame(height: 280)
                    
                    newsSection
                    
                } else {
                    // Show an error message if there was a problem loading the data
//                    print("Failed to load data for \(ticker).")
                    ProgressView("Fetching Data...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                }
    
            }  .onAppear {
                print("detailView appeared")
                viewModel.checkWishlistStatus(ticker: ticker) { isInWishlist in
                    self.isInWishlist = isInWishlist
                }
                viewModel.loadAllData(ticker: ticker)
                
//                if viewModel.holdings.isEmpty {
//                    viewModel.loadHoldings {
//                        // Empty completion handler because no additional action is needed here
//                    }
//                }
                
//                viewModel.loadMoney()
                // Triggers the loading of chart data when the view appears
                //                viewModel.loadMoney()
//                viewModel.loadChartData(ticker: ticker)
//                viewModel.loadHourData(ticker: ticker)
//                viewModel.loadCompanyProfile(ticker: ticker)
//                viewModel.loadQuote(ticker: ticker)
//                viewModel.loadPeers(ticker: ticker)
//                viewModel.loadSentiments(ticker: ticker)
//                viewModel.loadRecommendations(ticker: ticker)
//                viewModel.loadEarnings(ticker: ticker)
//                viewModel.loadNews(ticker: ticker)
                //viewModel.loadHoldings(completion: <#T##() -> Void#>)
                
                //viewModel.loadHoldings(completion: <#T##() -> Void#>)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        
    }
        .navigationBarItems(trailing: Button(action: {
            toggleWishlistStatus()
        }) {
            Image(systemName: isInWishlist ? "plus.circle.fill" : "plus.circle")
                .imageScale(.large)
                .foregroundColor(.blue)
        })
        // Showing a toast message when wishlist status changes
        if showToast {
            Text(toastText)
                .padding()
                .background(Color.gray)
                .foregroundColor(Color.white)
                .cornerRadius(25)
                .transition(.move(edge: .bottom))
                .onAppear {
                    // Dismiss the toast after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showToast = false
                    }
                }
        }
        
    }
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("News")
                .font(.headline)
                .padding(.leading)
            
            ForEach(viewModel.filteredNews, id: \.id) { article in
                if viewModel.isFirstArticle(article) {
                    // Special style for the first item
                    FirstNewsArticleView(article: article)
                        .onTapGesture {
                            self.selectedArticle = article
                            self.showingNewsDetail = true
                        }
                } else {
                    // Button to select an article and present the sheet
                    Button(action: {
                        self.selectedArticle = article // Set the selected article
                        self.showingNewsDetail = true
                    }) {
                        NewsArticleView(article: article)
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        
        .sheet(item: $selectedArticle) { currentArticle in
            NewsDetailView(news: currentArticle) // Pass the current article to the detail view
        }
    }
    
    
    func toggleWishlistStatus() {
        isInWishlist.toggle()
        if isInWishlist {
            // Add to wishlist and show added toast
            viewModel.modifyWishlistItem(ticker: ticker, name: viewModel.companyProfile?.name)
            toastText = "Adding \(ticker) to Favorites"
        } else {
            // Remove from wishlist and show removed toast
            viewModel.modifyWishlistItem(ticker: ticker, name: nil)
            toastText = "Removing \(ticker) from Favorites"
        }
        showToast = true
    }
    
    
    
    func addToWishlist() {
        isInWishlist.toggle()
        if isInWishlist {
            // Call your network manager's add to wishlist function
            viewModel.modifyWishlistItem(ticker: ticker, name: viewModel.companyProfile?.name)
            showingWishlistConfirmation = true
        }
    }
}


enum TradeAction {
    case buy, sell
}

struct TradeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject var viewModel: StockViewModel
    let ticker: String
    
    @State private var numberOfSharesText = ""
    //    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccessScreen = false
    @State private var showToast = false
    @State private var toastText = ""
    @State private var tradeAction: TradeAction? = nil
    @State private var operationCompleted = false
    
    var body: some View {
        NavigationView {
            ZStack {
            VStack {
                
                // Close button at the top
                HStack {
                    Spacer() // This will push the close button to the right
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark").imageScale(.large)
                    }
                    .padding()
                }
                
                // Title
                Text("Trade \(viewModel.companyProfile?.name ?? ticker) shares")
                    .font(.headline)
                    .padding()
                
                Spacer() // This will push the content below to the middle of the screen
                
                // Share input and calculation
                HStack {
                    TextField("", text: $numberOfSharesText)
                        .placeholder(when: numberOfSharesText.isEmpty) {
                            Text("0").foregroundColor(.gray)
                        }
                        .keyboardType(.numberPad)
                        .font(.system(size: 70))
                        .multilineTextAlignment(.leading)
                        .padding()
                    
                    VStack(alignment: .leading) {
                        Text((Int(numberOfSharesText) ?? 0) < 2 ? "Share" : "Shares")
                            .font(.largeTitle)
                        Text(calculateTotalCostText())
                            .fixedSize(horizontal: true, vertical: false)
                            .font(.system(size: 15))
                            .foregroundColor(.black)
                            .padding(.top, 10)
                    }
                    .padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 100) // Set the height for your TextField and VStack
                
                Spacer() // This will push the content below to the bottom of the screen
                
                // Available money to buy
                if let availableMoney = viewModel.money.first?.money {
                    Text("$\(availableMoney, specifier: "%.2f") available to buy \(ticker)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 15)
                }
                
                // Buy and Sell buttons
                HStack(spacing: 10) {
                    Button("Buy") {
                        print("Attempting to buy shares")
                        
                        executeTrade(action: .buy)
                    }
                    .buttonStyle(GreenButtonStyle())
                    .frame(maxWidth: .infinity) // Make the button fill the width
                    .padding(.horizontal) // Negative padding to counteract the padding in the ButtonStyle, adjust value as needed
                    
                    Button("Sell") {
                        print("Attempting to sell shares")
                        
                        executeTrade(action: .sell)
                    }
                    .buttonStyle(GreenButtonStyle())
                    .frame(maxWidth: .infinity) // Make the button fill the width
                    .padding(.horizontal) // Negative padding to counteract the padding in the ButtonStyle, adjust value as needed
                }
                .padding(.bottom, 10)  // Add padding at the bottom if necessary
                
            }
            .padding()
                
                if showToast {
                    VStack {
                        Spacer() // Pushes the toast message towards the bottom
                        Text(toastText)
                            .padding(.horizontal, 20) // Apply horizontal padding as needed
                            .padding(.vertical, 20)
                            .foregroundColor(.white)
                            .background(Color.gray)
                            .cornerRadius(30)
                            .transition(.move(edge: .bottom))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showToast = false // Dismiss the toast after 3 seconds
                                }
                            }
                    }
                }
            }

            
            
            .navigationBarHidden(true)
            .navigationBarTitle("", displayMode: .inline)
        }.sheet(isPresented: $showingSuccessScreen) {
            if let shares = Int(numberOfSharesText) {
                SuccessView(viewModel: viewModel, action: $tradeAction, ticker: ticker,
                            shares: shares,
                            showingTradeView: $showingSuccessScreen,
                            operationCompleted: $operationCompleted)
            }
        }
        .onChange(of: operationCompleted) { isCompleted in
            if isCompleted {
                if tradeAction == .sell {
                    navigationManager.resetToRootView()
                }
                self.showingSuccessScreen = false // This will dismiss the sheet
                self.presentationMode.wrappedValue.dismiss() // This will go back in the navigation
                
            }
        }

        
//        .onDisappear {
////            showingTradeScreen = false
//            print("TradeView is disappearing!")
////            viewModel.loadHoldings {
////                
////            }
//        }
        .onDisappear {
            print("TradeView is disappearing!")
//            viewModel.loadHoldings {}
//            if let holding = viewModel.holdings.first(where: { $0.ticker == ticker }), holding.quantity == 0 {
//                print("No holdings or holdings are zero for \(ticker), reloading holdings...")
//                viewModel.loadHoldings {
//                    // You might need to pass a completion handler here if `loadHoldings` has one
//                    print("Holdings have been reloaded.")
//                }
//            } else if viewModel.holdings.first(where: { $0.ticker == ticker }) == nil {
//                print("No holdings exist for \(ticker), reloading holdings...")
//                viewModel.loadHoldings {
//                    // Handle completion of loadHoldings if needed
//                }
//            }
        }

        
    }
    

    
    private func executeTrade(action: TradeAction) {
        print("Executing trade with action: \(action)")

        // Check if the input is a valid number and positive
        guard let numberOfShares = Int(numberOfSharesText), numberOfShares > 0 else {
            toastText = numberOfSharesText.isEmpty || numberOfSharesText <= "0" ?
                (action == .buy ? "Cannot buy non-positive shares" : "Cannot sell non-positive shares") :
                "Please enter a valid amount"
            showToast = true
            return
        }
        
        // Check the specific action
        switch action {
        case .buy:
            // Check if there's enough money to buy
            if let availableMoney = viewModel.money.first?.money,
               let quote = viewModel.quote,
               availableMoney >= (quote.c * Double(numberOfShares)) {
                tradeAction = .buy
                print("action: \(String(describing: tradeAction ?? nil))")
                DispatchQueue.main.async {
                    print("Before setting showingSuccessScreen: \(showingSuccessScreen)")
                    showingSuccessScreen = true
                    print("After setting showingSuccessScreen: \(showingSuccessScreen)")
                }
            } else {
                toastText = "Not enough money to buy"
                showToast = true
            }
        case .sell:
            // Check if there are enough shares to sell
            if let holdings = viewModel.holdings.first(where: { $0.ticker == ticker }),
               holdings.quantity >= numberOfShares {
                tradeAction = .sell
                print("action: \(String(describing: tradeAction ?? nil))")
                DispatchQueue.main.async {
                    print("Before setting showingSuccessScreen: \(showingSuccessScreen)")
                    showingSuccessScreen = true
                    print("After setting showingSuccessScreen: \(showingSuccessScreen)")
                }
            } else {
                toastText = "Not enough shares to sell"
                showToast = true
            }
        }
    }


    private func calculateTotalCostText() -> String {
        let numberOfShares = Int(numberOfSharesText) ?? 0
        guard let quote = viewModel.quote else {
            return "x $0.00/share = $0.00"
        }
        
        let totalCost = quote.c * Double(numberOfShares)
        return String(format: "x $%.2f/share = $%.2f", quote.c, totalCost)
    }
}


extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

struct SuccessView: View {
    
    let viewModel: StockViewModel
    @Binding var action: TradeAction?
    let ticker: String
    let shares: Int?
    //let totalCost: Double? // You should pass this value when initializing the SuccessView
    @Environment(\.presentationMode) var presentationMode
    @Binding var showingTradeView: Bool
    @State private var isLoading = true
    @Binding var operationCompleted: Bool
    
    var totalCost: Double {
        if let quoteC = viewModel.quote?.c, let shares = shares {
            return quoteC * Double(shares)
        } else {
            // Handle the case where either `quote` is nil, `c` is not available, or `shares` is nil
            return 0.0
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Congratulations!")
                .font(.largeTitle)
                .padding()
                .bold()
            
            Text("You have successfully \(action == .buy ? "bought" : "sold") \(shares ?? 0) shares of \(ticker).")
                .padding(.top, 20)
            
            Spacer()
            
//            Button("Done") {
//                if let shares = shares, let unwrappedAction = action {
//                    print("Shares: \(shares), and action: \(unwrappedAction)")
//                    updateDatabase(action: unwrappedAction, shares: shares) { success in
//                        if success {
//                            //                            showingTradeView = false
//                            //                            presentationMode.wrappedValue.dismiss()
//                            operationCompleted = true
//                            DispatchQueue.main.async {
//                                                        self.showingTradeView = false  // Simplify the control of the view's presentation
//                                                    }
////                            self.presentationMode.wrappedValue.dismiss()
//                        } else {
//                            // Handle the error case appropriately, perhaps show an alert or error message
//                        }
//                    }
//                } else {
//                    // Handle the case where shares or action is nil
//                    print("Error: shares or action is nil.")
//                }
//            }
            
            Button("Done") {
                if let shares = shares, let unwrappedAction = action {
                    print("Shares: \(shares), and action: \(unwrappedAction)")
                    updateDatabase(action: unwrappedAction, shares: shares) { success in
                        if success {
                            operationCompleted = true
                            DispatchQueue.main.async {
                                self.showingTradeView = false  // Simplify the control of the view's presentation
                            }
                        } else {
                            // Handle the error case appropriately, perhaps show an alert or error message
                            print("Failed to update database.")
                        }
                    }
                } else {
                    print("Error: shares or action is nil.")
                }
            }
            
            .buttonStyle(WhiteButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
        .foregroundColor(.white)
        .edgesIgnoringSafeArea(.all)
    }
    
//    private func updateDatabase(action: TradeAction, shares: Int, completion: @escaping (Bool) -> Void) {
//        if action == .buy {
//            let availableMoney = viewModel.money.first?.money ?? 0
//            let newMoneyAmount = availableMoney - totalCost
//            
//            viewModel.updateMoneyAmount(money: newMoneyAmount) { success in
//                if success {
//                    self.viewModel.modifyHoldingItem(ticker: self.ticker, quantity: shares, cost: totalCost) { success in
//                        completion(success)
//                    }
//                } else {
//                    completion(false)
//                }
//            }
//        } else if action == .sell {
//            let availableMoney = viewModel.money.first?.money ?? 0
//            let newMoneyAmount = availableMoney + totalCost
//            viewModel.updateMoneyAmount(money: newMoneyAmount) { success in
//                if success {
//                    print("Inside updateDB ContentView")
//                    self.viewModel.modifyHoldingItem(ticker: self.ticker, quantity: -shares, cost: -totalCost) { success in
//                        completion(success)
//                    }
//                } else {
//                    completion(false)
//                }
//            }
//        }
//    }
    
    private func updateDatabase(action: TradeAction, shares: Int, completion: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup() // Create a new Dispatch Group
        
        if action == .buy {
            let availableMoney = viewModel.money.first?.money ?? 0
            let newMoneyAmount = availableMoney - totalCost
            
            dispatchGroup.enter() // Enter the group
            viewModel.updateMoneyAmount(money: newMoneyAmount) { success in
                if success {
                    print("Inside success")
                    self.viewModel.modifyHoldingItem(ticker: self.ticker, quantity: shares, cost: totalCost) { success in
                        dispatchGroup.leave() // Leave the group upon completion
                        completion(success)
                    }
                } else {
                    dispatchGroup.leave() // Ensure to leave the group if early exit
                    completion(false)
                }
            }
        } else if action == .sell {
            let availableMoney = viewModel.money.first?.money ?? 0
            let newMoneyAmount = availableMoney + totalCost
            
            dispatchGroup.enter() // Enter the group
            viewModel.updateMoneyAmount(money: newMoneyAmount) { success in
                if success {
                    print("Inside updateDB ContentView")
                    self.viewModel.modifyHoldingItem(ticker: self.ticker, quantity: -shares, cost: -totalCost) { success in
                        dispatchGroup.leave() // Leave the group upon completion
                        completion(success)
                    }
                } else {
                    dispatchGroup.leave() // Ensure to leave the group if early exit
                    completion(false)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("All operations completed.") // This is called after all operations are completed
            // Here you might want to handle UI updates or navigate away from the current view
        }
    }

    
    
}


struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
        // Adjust padding as needed to fill the space
            .padding()
        // Use a background that fills the space and has rounded corners
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(25) // Adjust the corner radius to get the desired "pill" shape
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut, value: configuration.isPressed)
    }
}

struct WhiteButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
        // Adjust padding as needed to fill the space
            .padding()
        // Use a background that fills the space and has rounded corners
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.green)
            .cornerRadius(25) // Adjust the corner radius to get the desired "pill" shape
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut, value: configuration.isPressed)
    }
}

struct FirstNewsArticleView: View {
    let article: NewsResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Image
            if let imageUrl = URL(string: article.image), !article.image.isEmpty {
                KFImage(imageUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 200) // Width is full and height is adjusted
                    .clipped()
            }
            
            // Source and Time
            HStack {
                Text(article.source)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(timeAgoSinceDate(unixTimestamp: article.datetime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding([.leading, .trailing, .top], 8)
            
            // Headline
            Text(article.headline)
                .font(.headline)
                .lineLimit(3)
                .padding([.leading, .trailing], 8)
            
            // Divider Line
            Divider()
                .background(Color.gray)
                .padding([.leading, .trailing, .top], 8)
        }.padding([.leading, .trailing, .top], 8)
            .background(Color.white) // White background for the text stack
            .cornerRadius(8) // Rounded corners for the entire card
        //        .shadow(radius: 4)
    }
    
    func timeAgoSinceDate(unixTimestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}




struct NewsArticleView: View {
    
    let article: NewsResponse
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack() {
                    Text(article.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeAgoSinceDate(unixTimestamp: article.datetime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(article.headline)
                    .font(.headline)
                    .lineLimit(2) // Adjust the line limit to match the UI
            }
            .layoutPriority(1) // Ensure text takes up available space
            
            Spacer()
            
            if !article.image.isEmpty, let imageUrl = URL(string: article.image) {
                KFImage(imageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80) // Adjust the frame size as needed
                    .clipped()
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
    
    // Helper function to format the timestamp
    func timeAgoSinceDate(unixTimestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated // Change this to 'abbreviated' for a shorter format
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NewsDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    var news: NewsResponse
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                Text(news.source)
                    .font(.title).bold()
//                    .foregroundColor(.primary)
                
                Text(dateString(from: news.datetime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider().background(Color.gray)
                
                Text(news.headline)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.vertical)
                
                Text(news.summary)
                    .font(.body)
                
                // Assuming 'news.url' is the string of the URL you want to link to
                HStack {
                    Text("For more details click")
                        .foregroundColor(.gray)
                    
                    Button("here") {
                        if let url = URL(string: news.url), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                // Social sharing buttons
                HStack(spacing: 20) {
                    Button(action: {
                        shareOnTwitter(news: news)
                    }) {
                        Image("X") // Placeholder for Twitter logo
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                    Button(action: {
                        shareOnFacebook(news: news)
                    }) {
                        Image("Facebook") // Placeholder for Facebook logo
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            
                    }
                }
                .padding(.top) // Add some space above the sharing buttons
                
                Spacer()
            }
            .padding()
            
            .navigationBarItems(trailing: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
            })
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // This will run after the view has appeared
                print("NewsDetailView has appeared with article: \(news.headline)")
            }
        }
    }
    
    private func dateString(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter.string(from: date)
    }
    
    func shareOnTwitter(news: NewsResponse) {
        // Implement the Twitter sharing functionality
        if let url = URL(string: "https://twitter.com/intent/tweet?text=\(news.headline)&url=\(news.url)") {
            UIApplication.shared.open(url)
        }
    }
    
    func shareOnFacebook(news: NewsResponse) {
        // Implement the Facebook sharing functionality
        if let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(news.url)") {
            UIApplication.shared.open(url)
        }
    }
}




struct SentimentRow: View {
    var title: String
    var mspr: Double
    var change: Double
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 100, alignment: .leading)
                .bold()// Adjust the width as needed
            Spacer()
            Text(String(format: "%.2f", mspr))
                .frame(width: 100, alignment: .trailing) // MSPR column
            Spacer()
            Text(String(format: "%.2f", change))
                .frame(width: 120, alignment: .trailing) // Change column
        }
    }
}


struct TradeButton: View {
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
            Button(action: action) {
                Text("Trade")
                    .font(.headline) // You can increase this if you want a bigger font
                                   .fontWeight(.semibold) // This makes the text bolder
                                   .foregroundColor(.white)
                                   .padding(.vertical, 10) // Increase vertical padding to make the button taller
                                   .padding(.horizontal, 40) // Increase horizontal padding to make the button wider
                                   .background(Color.green)
                                   .cornerRadius(20) // This radius will give a pronounced pill shape
            }
                  .buttonStyle(PlainButtonStyle())
        }
}




struct HoldingRowPlaceholder: View {
    let ticker: String
    
    var body: some View {
        Text(ticker)
            .foregroundColor(.secondary)
    }
}


struct WishlistRow: View {
    let item: WishlistItem
    let quote: Quote
    
    var body: some View {
        NavigationLink(destination: StockDetailView(ticker: item.ticker)) {
            HStack {
                Text(item.ticker)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(formatCurrency(quote.c))
                        .bold()
                    HStack{
                        Image(systemName: quote.d > 0 ? "arrow.up.forward" : quote.d < 0 ? "arrow.down.right" : "minus")
                            .foregroundColor(quote.d != 0 ? (quote.d > 0 ? .green : .red) : .gray)
                        Text(formatChange(quote.d) + " (\(String(format: "%.2f", quote.dp))%)")
                            .foregroundColor(quote.d >= 0 ? .green : .red)
                    }
                    
                }
            }
        }
    }
}

struct WishlistRowPlaceholder: View {
    let ticker: String
    
    var body: some View {
        Text(ticker)
            .foregroundColor(.secondary)
    }
}

// Helper function to format currency
// ... existing formatCurrency function

// Helper function to format change in price
func formatChange(_ change: Double) -> String {
    let formatter = NumberFormatter()
//    formatter.positivePrefix = "formatter.plusSign"
    formatter.negativePrefix = formatter.minusSign
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: change)) ?? "\(change)"
}

// Replace with previews or other necessary views
// ... existing previews


// Helper function to format currency
func formatCurrency(_ number: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "en_US") // Adjust if necessary
    return formatter.string(from: NSNumber(value: number)) ?? "$\(number)"
}

//func formattedCurrentDate() -> String {
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = "MMMM d, yyyy" // Example: "March 21, 2024"
//    return dateFormatter.string(from: Date())
//}
func formattedCurrentDate() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM dd, yyyy"
    let dateString = dateFormatter.string(from: Date())
    
    // Capitalize the first letter of the month and lowercase the rest
    let month = dateString.prefix(while: { $0 != " " }).lowercased().capitalizingFirstLetter()
    let restOfString = dateString.drop(while: { $0 != " " })
    
    return month + restOfString
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}

// Replace with previews or other necessary views
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let navigationManager = NavigationManager()
        ContentView()
            .environmentObject(navigationManager)
    }
}
