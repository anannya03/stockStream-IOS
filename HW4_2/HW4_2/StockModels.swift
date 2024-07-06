//
//  StockModels.swift
//  HW4_2
//
//  Created by Anannya Patra on 08/04/24.
//

import Foundation

struct Quote: Codable {
    let c: Double  // Current price
    let d: Double  // Change
    let dp: Double // Percent change
    let h: Double  // High price of the day
    let l: Double  // Low price of the day
    let o: Double  // Open price of the day
    let pc: Double // Previous close price
    let t: Int     // Timestamp
}

struct NewsResponse: Codable, Identifiable {
    let category: String
    let datetime: Int
    let headline: String
    let id: Int
    let image: String
    let related: String
    let source: String
    let summary: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
           case category, datetime, headline, id, image, related, source, summary, url
       }
}


struct CompanyProfile: Codable {
    let country: String
    let currency: String
    let estimateCurrency: String
    let exchange: String
    let finnhubIndustry: String
    let ipo: String
    let logo: String
    let marketCapitalization: Double
    let name: String
    let phone: String
    let shareOutstanding: Double
    let ticker: String
    let weburl: String
}


struct Recommendation: Codable {
    let buy: Int
    let hold: Int
    let period: String
    let sell: Int
    let strongBuy: Int
    let strongSell: Int
    let symbol: String
    
    enum CodingKeys: String, CodingKey {
           case buy, hold, period, sell, strongBuy, strongSell, symbol
       }
    
    // When decoding:
    // let recommendations = try JSONDecoder().decode([Recommendation].self, from: data)
}

struct Sentiment: Codable {
    let data: [SentimentData]
}

struct SentimentData: Codable {
    let symbol: String
    let year: Int
    let month: Int
    let change: Int
    let mspr: Double
    
    // When decoding:
    // let sentimentResponse = try JSONDecoder().decode(SentimentResponse.self, from: data)
}


typealias Peers = [String]  // Since the API returns an array of tickers


struct Earning: Codable {
    let actual: Double
    let estimate: Double
    let period: String
    let quarter: Int
    let surprise: Double
    let surprisePercent: Double
    let symbol: String
    let year: Int
    
    enum CodingKeys: String, CodingKey {
           case actual, estimate, period, quarter, surprise, surprisePercent, symbol, year
    }
    
    // When decoding:
    // let earnings = try JSONDecoder().decode([Earning].self, from: data)
}

struct HourDataResponse: Codable {
    let ticker: String
    let queryCount: Int
    let resultsCount: Int
    let adjusted: Bool
    let results: [HourData]
}

struct HourData: Codable {
    let v: Int // volume
    let vw: Double // volume weighted average price
    let o: Double // open price
    let c: Double // close price
    let h: Double // high price
    let l: Double // low price
    let t: Int // timestamp
    let n: Int // number of trades
}

struct ChartDataResponse: Codable {
    let ticker: String
    let queryCount: Int
    let resultsCount: Int
    let adjusted: Bool
    let results: [ChartData]
}

struct ChartData: Codable {
    let v: Int // volume
    let vw: Double // volume weighted average price
    let o: Double // open price
    let c: Double // close price
    let h: Double // high price
    let l: Double // low price
    let t: Int // timestamp
    let n: Int // number of trades
}


struct AutofillResponse: Codable {
    let count: Int
    let result: [AutofillResult]
}

struct AutofillResult: Codable {
    let description: String
    let displaySymbol: String
    let symbol: String
    let type: String
}


struct WishlistItem: Codable, Identifiable {
    let id: String
    let ticker: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case ticker, name
    }
}

struct Money: Codable, Identifiable {
    let id: String
    let money: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case money
    }
}

struct Holding: Codable, Identifiable {
    let id: String
    let ticker: String
    let quantity: Int
    let cost: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case ticker, quantity, cost
    }
}

struct ErrorType: Identifiable {
    let id = UUID()
    let message: String
}




