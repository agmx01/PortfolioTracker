//
//  ContentView.swift
//  PortfolioTracker
//
//  Created by Samta Gupta on 01/05/26.
//

import SwiftUI

struct Stock: Identifiable {
    let id = UUID()
    let ticker: String
    let shares: Double
    var price: Double
    var change: Double
}

struct ContentView: View {
    @State var stocks: [Stock] = [
        Stock(ticker: "AAPL", shares: 10, price: 0, change: 0),
        Stock(ticker: "TSLA", shares: 5, price: 0, change: 0)
    ]
    // 👇 PASTE FUNCTION HERE
    var totalValue: Double {
        stocks.reduce(0) { $0 + ($1.price * $1.shares) }
    }
    
    var totalDailyChange: Double {
        stocks.reduce(0) { total, stock in
            let changeValue = (stock.change / 100) * stock.price * stock.shares
            return total + changeValue
        }
    }
    
    var totalDailyChangePercent: Double {
        if totalValue == 0 { return 0 }
        return (totalDailyChange / totalValue) * 100
    }
    func fetchPrice(for ticker: String, completion: @escaping (Double, Double) -> Void) {
        
        let apiKey = "0LEAMJFOD4I3U888"
        
        let urlString = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\(ticker)&apikey=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               
                let quote = json["Global Quote"] as? [String: String],
               
                let price = Double(quote["05. price"] ?? ""),
               
                let changePercentString = quote["10. change percent"]?.replacingOccurrences(of: "%", with: ""),
               
                let change = Double(changePercentString) {
                
                DispatchQueue.main.async {
                    
                    completion(price, change)
                    
                }
                
            }
            
        }.resume()
        
    }
    // 👇 UI starts here
    var body: some View {
        NavigationView {
            VStack {
                // 👇 Daily totals
                VStack(alignment: .leading, spacing: 10) {
                    Text("Total Value: $\(totalValue, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                    
                    Text("Today: $\(totalDailyChange, specifier: "%.2f") (\(totalDailyChangePercent, specifier: "%.2f")%)")
                        .foregroundColor(totalDailyChange >= 0 ? .green : .red)
                }
                .padding()
                
                // 👇 list of stocks
                List(stocks) { stock in
                    HStack {
                        Text(stock.ticker)
                            .frame(width: 60, alignment: .leading)
                        
                        Text("\(stock.shares, specifier: "%.1f")")
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("$\(stock.price, specifier: "%.2f")")
                            Text("\(stock.change, specifier: "%.2f")%")
                                .foregroundColor(stock.change >= 0 ? .green : .red)
                        }
                        
                        Text("$\(stock.price * stock.shares, specifier: "%.2f")")
                            .frame(width: 100, alignment: .trailing)
                    }
                }
                .navigationTitle("Portfolio")
                .onAppear {
                    for i in stocks.indices {
                        let delay = Double(i) * 5.0   // 5 sec gap
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            fetchPrice(for: stocks[i].ticker) { price, change in
                                var updatedStock = stocks[i]
                                updatedStock.price = price
                                updatedStock.change = change
                                stocks[i] = updatedStock
                            }
                        }
                    }
                }
            }
        }
        
    }
}
