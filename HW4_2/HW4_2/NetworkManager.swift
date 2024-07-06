//
//  NetworkManager.swift
//  HW4_2
//
//  Created by Anannya Patra on 08/04/24.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    let baseURL = "https://stockios-422105.wl.r.appspot.com"
//      let baseURL = "http://localhost:8080"
    
    // Generic function to fetch data from the server
    private func fetchData<T: Codable>(from endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NetworkError.unknown))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedData))
                }
               // print("Fetched chart data: \(decodedData)")
            } catch {
                completion(.failure(NetworkError.decodingError))
            }
        }.resume()
    }
    
    // Fetches quote data
    func fetchQuote(ticker: String, completion: @escaping (Result<Quote, Error>) -> Void) {
        fetchData(from: "/api/quote?ticker=\(ticker)", completion: completion)
    }
    
    func fetchNews(ticker: String, completion: @escaping (Result<[NewsResponse], Error>) -> Void) {
        fetchData(from: "/api/news?ticker=\(ticker)", completion: completion)
    }
    
    // Fetches company profile data
    func fetchCompanyProfile(ticker: String, completion: @escaping (Result<CompanyProfile, Error>) -> Void) {
        fetchData(from: "/api/company-profile?ticker=\(ticker)", completion: completion)
    }
    
    func fetchRecommendation(ticker: String, completion: @escaping (Result<[Recommendation], Error>) -> Void) {
        fetchData(from: "/api/recommendation?ticker=\(ticker)", completion: completion)
    }
    
    func fetchSentiment(ticker: String, completion: @escaping (Result<Sentiment, Error>) -> Void) {
        fetchData(from: "/api/sentiment?ticker=\(ticker)", completion: completion)
    }
    
    func fetchPeers(ticker: String, completion: @escaping (Result<Peers, Error>) -> Void) {
        fetchData(from: "/api/peers?ticker=\(ticker)", completion: completion)
    }
    
    func fetchEarnings(ticker: String, completion: @escaping (Result<[Earning], Error>) -> Void) {
        fetchData(from: "/api/earnings?ticker=\(ticker)", completion: completion)
    }
    
    func fetchHourData(ticker: String, completion: @escaping (Result<HourDataResponse, Error>) -> Void) {
        fetchData(from: "/api/hourData?ticker=\(ticker)", completion: completion)
    }
    
    func fetchChartData(ticker: String, completion: @escaping (Result<ChartDataResponse, Error>) -> Void) {
        fetchData(from: "/api/charts?ticker=\(ticker)", completion: completion)
    }
    
    func fetchWishlist(completion: @escaping (Result<[WishlistItem], Error>) -> Void) {
        fetchData(from: "/wishlist", completion: completion)
    }
    
    func fetchHoldings(completion: @escaping (Result<[Holding], Error>) -> Void) {
        fetchData(from: "/holdings", completion: completion)
    }
    
    func fetchMoney(completion: @escaping (Result<[Money], Error>) -> Void) {
        fetchData(from: "/money", completion: completion)
    }
    
    func fetchAutofill(ticker: String, completion: @escaping (Result<AutofillResponse, Error>) -> Void) {
        fetchData(from: "/api/autofill/\(ticker)", completion: completion)
    }
    
//    private func postData<T: Codable>(to endpoint: String, body: Data, completion: @escaping (Result<T, Error>) -> Void) {
//           guard let url = URL(string: baseURL + endpoint) else {
//               completion(.failure(NetworkError.invalidURL))
//               return
//           }
//
//           var request = URLRequest(url: url)
//           request.httpMethod = "POST"
//           request.httpBody = body
//           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//           URLSession.shared.dataTask(with: request) { data, response, error in
//               guard let data = data, error == nil else {
//                   completion(.failure(error ?? NetworkError.unknown))
//                   return
//               }
//
//               do {
//                   let decodedData = try JSONDecoder().decode(T.self, from: data)
//                   DispatchQueue.main.async {
//                       completion(.success(decodedData))
//                   }
//               } catch {
//                   completion(.failure(NetworkError.decodingError))
//               }
//           }.resume()
//       }
//   
    
    private func postData<T: Codable>(to endpoint: String, body: Data, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NetworkError.unknown))
                return
            }

            // Add this line to print out the raw response data
            print(String(data: data, encoding: .utf8) ?? "No raw data")

            do {
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(decodedData))
                        }
                    } catch let DecodingError.dataCorrupted(context) {
                        print(context)
                        completion(.failure(NetworkError.decodingError))
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("Key '\(key)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                        completion(.failure(NetworkError.decodingError))
                    } catch let DecodingError.valueNotFound(value, context) {
                        print("Value '\(value)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                        completion(.failure(NetworkError.decodingError))
                    } catch let DecodingError.typeMismatch(type, context)  {
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                        completion(.failure(NetworkError.decodingError))
                    } catch {
                        print("error: ", error)
                        completion(.failure(NetworkError.decodingError))
                    }
        }.resume()
    }

    
    func modifyWishlist(ticker: String, name: String?, completion: @escaping (Result<WishlistItem, Error>) -> Void) {
        var bodyDict = ["ticker": ticker]
        if let name = name {
            bodyDict["name"] = name // Include the name only if we are adding
        }
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
            completion(.failure(NetworkError.decodingError))
            return
        }
        let endpoint = "/wishlist"
        postData(to: endpoint, body: bodyData, completion: completion)
    }

    
    func modifyHoldings(ticker: String, quantity: Int, cost: Double, completion: @escaping (Result<Holding, Error>) -> Void) {
        let bodyDict: [String: Any] = ["ticker": ticker, "quantity": quantity, "cost": cost]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
            completion(.failure(NetworkError.decodingError))
            return
        }
        let endpoint = "/holdings"
        postData(to: endpoint, body: bodyData, completion: completion)
    }

    
    func updateMoney(money: Double, completion: @escaping (Result<Money, Error>) -> Void) {
            let bodyDict = ["money": money]
            guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
                completion(.failure(NetworkError.decodingError))
                return
            }
            let endpoint = "/money"
            postData(to: endpoint, body: bodyData, completion: completion)
        }
    
    
    // Enum to handle different network errors
    enum NetworkError: Error {
        case invalidURL
        case unknown
        case decodingError
    }
}
