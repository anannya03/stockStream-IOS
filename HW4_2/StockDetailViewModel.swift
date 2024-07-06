//
//  StockDetailViewModel.swift
//  HW4_2
//
//  Created by Anannya Patra on 14/04/24.
//

import Foundation

class StockDetailViewModel: ObservableObject {
    
//    var chartData: ChartDataResponse?
//    var hourData: HourDataResponse?
    
    func prepareChartDataHTML(chartData: [ChartData], ticker: String) -> String {
        //print("CD", chartData)
        
        let ohlc: [[Any]] = chartData.map {
            // Assuming $0.t is already in milliseconds, so don't multiply by 1000
            let date = Date(timeIntervalSince1970: TimeInterval($0.t / 1000)) // Divide by 1000 to convert back to seconds
//            let formatter = DateFormatter()
//            formatter.timeZone = TimeZone(abbreviation: "UTC") // Adjust the timezone as needed
//            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            let dateString = formatter.string(from: date)
            return [date.timeIntervalSince1970 * 1000, $0.o, $0.h, $0.l, $0.c]
        }

        
        let volume: [[Any]] = chartData.map {
            // Again, assuming $0.t is in milliseconds
            let date = Date(timeIntervalSince1970: TimeInterval($0.t / 1000)) // Divide by 1000 to convert back to seconds
            return [date.timeIntervalSince1970 * 1000, $0.v] // Highcharts needs milliseconds
        }
        
        do {
            let ohlcJSON = try JSONSerialization.data(withJSONObject: ohlc, options: [])
            let volumeJSON = try JSONSerialization.data(withJSONObject: volume, options: [])
            
            guard let ohlcString = String(data: ohlcJSON, encoding: .utf8),
                  let volumeString = String(data: volumeJSON, encoding: .utf8) else {
                print("Error: Can't create JSON strings")
                return ""
            }
            
                    let html = """
                    <html>
                    <head>
                        <script src="https://code.highcharts.com/stock/highstock.js"></script>
                        <script src="https://code.highcharts.com/stock/modules/data.js"></script>
                        <script src="https://code.highcharts.com/stock/highcharts-more.js"></script>
                        <script src="https://code.highcharts.com/stock/modules/exporting.js"></script>
                        <script src="https://code.highcharts.com/stock/modules/export-data.js"></script>
                        <script src="https://code.highcharts.com/stock/modules/accessibility.js"></script>
                        <script src="https://code.highcharts.com/stock/indicators/indicators.js"></script>
                           <script src="https://code.highcharts.com/stock/indicators/volume-by-price.js"></script>
                    </head>
                    <body>
                        <div id="chartContainer" style="height: 100%; width: 100%;"></div>
                        <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                Highcharts.stockChart('chartContainer', {
                                    rangeSelector: {
                    inputBoxWidth: 120, // Increase the width of the date range input boxes
                            inputBoxHeight: 18, // Increase the height of the date range input boxes
                            inputStyle: {
                                fontSize: '25px'
                                                           
                            },
                            buttonTheme: { // styles for the buttons
                                width: 60, // Increase the width of the buttons
                                height: 30, // Increase the height of the buttons
                                style: {
                                    fontSize: '30px', // Increase the font size of the button text
                                }
                            },
                                               selected: 2,
                                                dropdown: 'always',
                                                style: {
                                                fontSize: '30px' // Set title font size
                                                }
                                               
                                           },
                                    title: {
                                        text: '\(ticker) Historical',
                                        style: {
                                        fontSize: '40px' // Set title font size
                                    }
                                    },
                                    subtitle: {
                                        text: 'With SMA and Volume by Price technical indicators',
                                        style: {
                                                            fontSize: '25px' // Set title font size
                                                        }
                                    },
                                xAxis: {
                                        type: 'datetime',
                                         
                                        minTickInterval: 28*24*3600*1000,
                                        labels: {
                                                style: {
                                                fontSize: '25px' // Set X-axis labels font size
                                            }
                                        }
                                },
                                    yAxis: [{
                                tickAmount: 4,
                                startOnTick: false,
                                endOnTick: false,
                                        labels: {
                                            align: 'right',
                                            x: -3,
                                        style: {
                                            fontSize: '25px' // Set X-axis labels font size
                                        }
                                        },
                                        title: {
                                            text: 'OHLC',
                                            style: {
                                                 fontSize: '20px' // Set X-axis labels font size
                                              }
                                        },
                                        height: '60%',
                                        lineWidth: 2,
                                        resize: {
                                            enabled: true
                                        }
                                    }, {
                                        labels: {
                                            align: 'right',
                                            x: -3,
                                                            style: {
                                                                fontSize: '25px' // Set X-axis labels font size
                                                            }
                                        },
                                        title: {
                                            text: 'Volume',
                                            style: {
                                                fontSize: '20px' // Set X-axis labels font size
                                            }
                                        },
                                        top: '65%',
                                        height: '35%',
                                        offset: 0,
                                        lineWidth: 2
                                    }],
                                    tooltip: {
                                        split: true,
                                        style: {
                                        fontSize: '30px' // Set X-axis labels font size
                                        }
                                    },
                                    chart: {
                                        backgroundColor: '#ffffff',
                                    },
                    legend: {
                                    symbolHeight: 20, // Increase symbol height
                                    symbolWidth: 20, // Increase symbol width
                                    itemStyle: {
                                        fontSize: '30px' // Set legend item font size
                                    },
                                },
                                    series: [{
                                        type: 'candlestick',
                                        name: '\(ticker)',
                                        id: '\(ticker)',
                                        zIndex: 2,
                                        data: \(ohlcString)
                                    }, {
                                        type: 'column',
                                        name: 'Volume',
                                        id: 'volume',
                                        data: \(volumeString),
                                        yAxis: 1
                                    }, {
                                        type: 'vbp',
                                        linkedTo: '\(ticker)',
                                        params: {
                                            volumeSeriesID: 'volume'
                                        },
                                        dataLabels: {
                                            enabled: false
                                        },
                                        zoneLines: {
                                            enabled: false
                                        }
                                    }, {
                                        type: 'sma',
                                        linkedTo: '\(ticker)',
                                        zIndex: 1,
                                        marker: {
                                            enabled: false
                                        }
                                    }],
                                    time: {
                                        useUTC: false,
                                        timezone: 'America/Los_Angeles'
                                    }
                                });
                            });
                        </script>
                    </body>
                    </html>
                    """
            
            return html
            
        } catch {
            print("JSON Serialization error: \(error)")
            return ""
        }
    }
    
//    func prepareChartDataHTML(chartData: [ChartData], ticker: String) -> String {
//       // guard let chartData = self.chartData else { return "" }
//        print("CD" , chartData)
//        let ohlc: [[Any]] = chartData.map { [
//            $0.t * 1000, // JavaScript uses milliseconds for dates
//            $0.o, $0.h, $0.l, $0.c
//        ]}
//        
//        let volume: [[Any]] = chartData.map { [
//            $0.t * 1000, // JavaScript uses milliseconds for dates
//            $0.v
//        ]}
//        
//        let ohlcJSON = try! JSONSerialization.data(withJSONObject: ohlc, options: [])
//        let volumeJSON = try! JSONSerialization.data(withJSONObject: volume, options: [])
//        let ohlcString = String(data: ohlcJSON, encoding: .utf8)!
//        let volumeString = String(data: volumeJSON, encoding: .utf8)!
//        
//        let html = """
//        <html>
//        <head>
//            <script src="https://code.highcharts.com/stock/highstock.js"></script>
//            <script src="https://code.highcharts.com/stock/modules/data.js"></script>
//            <script src="https://code.highcharts.com/stock/modules/exporting.js"></script>
//            <script src="https://code.highcharts.com/stock/modules/export-data.js"></script>
//            <script src="https://code.highcharts.com/stock/modules/accessibility.js"></script>
//            <script src="https://code.highcharts.com/indicators/indicators.js"></script>
//            <script src="https://code.highcharts.com/indicators/volume-by-price.js"></script>
//        </head>
//        <body>
//            <div id="chartContainer" style="height: 600px; width: 100%;"></div>
//            <script>
//                document.addEventListener('DOMContentLoaded', function() {
//                    Highcharts.stockChart('chartContainer', {
//                        rangeSelector: {
//                            selected: 2
//                        },
//                        title: {
//                            text: '\(ticker) Historical'
//                        },
//                        subtitle: {
//                            text: 'With SMA and Volume by Price technical indicators'
//                        },
//                        yAxis: [{
//                            labels: {
//                                align: 'right',
//                                x: -3
//                            },
//                            title: {
//                                text: 'OHLC'
//                            },
//                            height: '60%',
//                            lineWidth: 2,
//                            resize: {
//                                enabled: true
//                            }
//                        }, {
//                            labels: {
//                                align: 'right',
//                                x: -3
//                            },
//                            title: {
//                                text: 'Volume'
//                            },
//                            top: '65%',
//                            height: '35%',
//                            offset: 0,
//                            lineWidth: 2
//                        }],
//                        tooltip: {
//                            split: true
//                        },
//                        chart: {
//                            backgroundColor: '#f4f4f4'
//                        },
//                        series: [{
//                            type: 'candlestick',
//                            name: '\(ticker)',
//                            id: '\(ticker)',
//                            zIndex: 2,
//                            data: \(ohlcString)
//                        }, {
//                            type: 'column',
//                            name: 'Volume',
//                            id: 'volume',
//                            data: \(volumeString),
//                            yAxis: 1
//                        }, {
//                            type: 'vbp',
//                            linkedTo: '\(ticker)',
//                            params: {
//                                volumeSeriesID: 'volume'
//                            },
//                            dataLabels: {
//                                enabled: false
//                            },
//                            zoneLines: {
//                                enabled: false
//                            }
//                        }, {
//                            type: 'sma',
//                            linkedTo: '\(ticker)',
//                            zIndex: 1,
//                            marker: {
//                                enabled: false
//                            }
//                        }],
//                        time: {
//                            useUTC: false,
//                            timezone: 'America/Los_Angeles'
//                        }
//                    });
//                });
//            </script>
//        </body>
//        </html>
//        """
//        print(html)
//        return html
//    }
    
    func findMaxValue(in priceData: [[Any]]) -> Double? {
        let values = priceData.compactMap { $0.last as? Double }
        return values.max()
    }
    
    func prepareHourlyDataHTML(hourData: [HourData], ticker: String, quote: Quote) -> String {

        
        let last32HourData = Array(hourData.suffix(32))

            // Map the data to the format Highcharts needs.
            let priceData: [[Any]] = last32HourData.map {
                let date = Date(timeIntervalSince1970: TimeInterval($0.t / 1000)) // Divide by 1000 to convert back to seconds
                return [date.timeIntervalSince1970 * 1000, $0.c] // Highcharts needs milliseconds
            }.suffix(20)

            // Determine the line color based on quote.d.
            let lineColor = quote.d > 0 ? "green" : "red"

            // Convert priceData to JSON string.
            let priceDataJSON = try! JSONSerialization.data(withJSONObject: priceData, options: [])
            let priceDataString = String(data: priceDataJSON, encoding: .utf8)!
        
        let html = """
        <html>
        <head>
            <script src="https://code.highcharts.com/stock/highstock.js"></script>
            <script src="https://code.highcharts.com/stock/modules/data.js"></script>
            <script src="https://code.highcharts.com/stock/modules/exporting.js"></script>
            <script src="https://code.highcharts.com/stock/modules/export-data.js"></script>
            <script src="https://code.highcharts.com/stock/modules/accessibility.js"></script>
        </head>
        <body>
            <div id="hourlyChartContainer" style="height: 100%; width: 100%;"></div>
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    Highcharts.stockChart('hourlyChartContainer', {
                        chart: {
                            backgroundColor: '#ffffff',
                        },
                        title: {
                            text: '\(ticker) Hourly Price Variation',
                            style: {
                                color: 'gray',
                                fontSize: '40px'
                            }
                        },
                        xAxis: {
                            type: 'datetime',
                            tickInterval: 6*3600*1000,
                            labels: {
                                                style: {
                                                    fontSize: '25px' // Set Y-axis labels font size
                                                }
                                            }
                        },
                       yAxis: {
                            tickAmount: 5,
                            labels: {
                            style: {
                                fontSize: '25px' // Set Y-axis labels font size
                            }
                        }
                        },
                        series: [{
                            name: 'Hourly Data',
                            data: \(priceDataString),
                            type: 'line',
                            color: '\(lineColor)' // Use 'green' or 'red' based on data
                        }],
                        tooltip: {
                            split: true,
                            style: {
                            fontSize: '30px'
                            }
                        },
                        rangeSelector: {
                            enabled: false
                        },
                        navigator: {
                            enabled: false
                        },
                        legend: {
                            enabled: false,
         symbolHeight: 20, // Increase symbol height
                        symbolWidth: 20, // Increase symbol width
                        itemStyle: {
                            fontSize: '25px' // Set legend item font size
                        },
                        },
                        time: {
                            useUTC: false,
                            timezone: 'America/Los_Angeles'
                        }
                    });
                });
            </script>
        </body>
        </html>
        """
        return html
    }
    
//    func generateRecHTML(forRecommendations recommendations: [Recommendation]) -> String {
//        // Prepare the data arrays from your recommendations and earnings
//        let categories = recommendations.map { $0.period }
//        let strongBuyData = recommendations.map { $0.strongBuy }
//        let buyData = recommendations.map { $0.buy }
//        let holdData = recommendations.map { $0.hold }
//        let sellData = recommendations.map { $0.sell }
//        let strongSellData = recommendations.map { $0.strongSell }
//
//        // Convert your Swift data to JavaScript data
//        let categoriesJSArray = categories.map { "'\($0)'" }.joined(separator: ", ")
//        let strongBuyJSArray = strongBuyData.map(String.init).joined(separator: ", ")
//        let buyJSArray = buyData.map(String.init).joined(separator: ", ")
//        let holdJSArray = holdData.map(String.init).joined(separator: ", ")
//        let sellJSArray = sellData.map(String.init).joined(separator: ", ")
//        let strongSellJSArray = strongSellData.map(String.init).joined(separator: ", ")
//        
//        // Similar preparation for earnings...
//
//        // Generate the HTML and JavaScript
//        let htmlContent = """
//        <!DOCTYPE html>
//        <html>
//        <head>
//            <script src="https://code.highcharts.com/highcharts.js"></script>
//            <style>
//                body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto; }
//                .chart-container { padding: 20px; }
//            </style>
//        </head>
//        <body>
//            <div id="recommendation-chart" style="height: 600px; width: 100%;"></div>
//            <script>
//                // Render Recommendation Trends Chart
//                Highcharts.chart('recommendation-chart', {
//                    chart: { type: 'column', backgroundColor: '#ffffff' },
//                    title: { text: 'Recommendation Trends' },
//                    xAxis: { categories: [\(categoriesJSArray)] },
//                    yAxis: { min: 0, title: { text: '#Analysis' }},
//                    plotOptions: { column: { stacking: 'normal' }},
//                    series: [{
//                        name: 'Strong Buy', data: [\(strongBuyJSArray)], type: 'column', color: 'darkgreen',
//                    }, {
//                        name: 'Buy', data: [\(buyJSArray)], type: 'column', color: 'green',
//                    }, {
//                        name: 'Hold', data: [\(holdJSArray)], type: 'column', color: 'yellow',
//                    }, {
//                        name: 'Sell', data: [\(sellJSArray)], type: 'column', color: 'red',
//                    }, {
//                        name: 'Strong Sell', data: [\(strongSellJSArray)], type: 'column', color: 'magenta',
//                    }]
//                });
//
//            </script>
//        </body>
//        </html>
//        """
//        //print(htmlContent)
//        return htmlContent
//    }
    
    func generateRecHTML(forRecommendations recommendations: [Recommendation]) -> String {
        var period = [String]()
        var strongBuy = [Int]()
        var buy = [Int]()
        var hold = [Int]()
        var sell = [Int]()
        var strongSell = [Int]()
        
        for recommendation in recommendations {
            let length = recommendation.period.count
            period.append(String(recommendation.period.prefix(length - 3)))
            strongBuy.append(recommendation.strongBuy)
            buy.append(recommendation.buy)
            hold.append(recommendation.hold)
            sell.append(recommendation.sell)
            strongSell.append(recommendation.strongSell)
        }
        
        let chartData = """
        {
            chart:{
                type: 'column',
                backgroundColor: '#ffffff',
            },
            title: {
                text: 'Recommendation Trends',
                  style: {
                      fontSize: '40px'
                   }
            },
            xAxis: {
                categories: \(period),
                labels: {
                    style: {
                        fontSize:'25px'
                    }
                }
                //crosshair: true
            },
            yAxis:{
                min: 0,
                title:{
                    text: '#Analysis'
                },
                        labels: {
                            style: {
                                fontSize:'25px'
                            }
                        },
                tickAmount: 5
            },
           
            plotOptions: {
                column: {
                    stacking: 'normal',
                    dataLabels: {
                        enabled: true,
         style: {
                                    fontSize: '25px',
                                    color: 'white'
                                }
                    }
                }
            },
                            tooltip: {style: {
                                      fontSize: '30px'
                                   }},
         legend: {
                        symbolHeight: 20, // Increase symbol height
                        symbolWidth: 20, // Increase symbol width
                        itemStyle: {
                            fontSize: '25px' // Set legend item font size
                        },
                    },
        ticker: {
            style: {
                fontSize:'25px'
                }
        },
            series: [{
                name: 'Strong Buy',
                data: \(strongBuy),
                type: 'column',
                color: 'darkgreen',
            },{
                name: 'Buy',
                data: \(buy),
                type: 'column',
                color: 'green',
            },{
                name: 'Hold',
                data: \(hold),
                type: 'column',
                color: '#B07E28',
            },{
                name: 'Sell',
                data: \(sell),
                type: 'column',
                color: 'red',
            },{
                name: 'Strong Sell',
                data: \(strongSell),
                type: 'column',
                color: 'darkred',
            }],
        }
        """
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <script src="https://code.highcharts.com/highcharts.js"></script>
        </head>
        <body>
            <div id="container" style="height: 600px; width: 100%;"></div>
            <script>
                Highcharts.chart('container', \(chartData));
            </script>
        </body>
        </html>
        """
        
        return html
    }
    
    func generateEarningsChartHTML(earnings: [Earning]) -> String {
        let periods = earnings.map { "\($0.period)" }
          let actualData = earnings.map { "\($0.actual)" }
          let estimateData = earnings.map { "\($0.estimate)" }
          let surpriseData = earnings.map { "\($0.surprise)" }
        
        
        let periodsString = periods.joined(separator: ", ")
        let actualDataString = actualData.joined(separator: ", ")
        let estimateDataString = estimateData.joined(separator: ", ")
        let surpriseDataString = surpriseData.joined(separator: ", ")

        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <script src="https://code.highcharts.com/highcharts.js"></script>
            <style>
                body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto; }
                .chart-container { padding: 20px; }
            </style>
        </head>
        <body>
            <div id="earnings-chart" style="height: 600px; width: 100%;"></div>
            
            <script>
                // Render Historical EPS Surprises Chart
                Highcharts.chart('earnings-chart', {
                    chart: {
                        type: 'spline',
                        backgroundColor: '#ffffff',
                    },
                    title: {
                        text: 'Historical EPS Surprises',
                          style: {
                              fontSize: '40px'
                           }
                    },
                    tooltip: {style: {
                              fontSize: '30px'
                           }},
                    xAxis: {
                        categories: \(periods),
                        labels: {
                            rotation: -45,
                             style: {
                                fontSize:'25px'
                            },
                            useHTML: true,
                            formatter: function () {
                                let surpriseValue = [\(surpriseDataString)][this.pos];
                                return '<div style="text-align: center;">' + this.value + '<br><span>Surprise: ' + surpriseValue + '</span></div>';
                            }
                        }
                    },
                    yAxis: {
                        title: {
                            text: 'Quarterly EPS',
                            style: {
                                fontSize: '25px'
                            }
                        },
                        labels: {
                            style: {
                                fontSize:'25px'
                            }
                        }
                    },
                    legend: {
                        symbolHeight: 20, // Increase symbol height
                        symbolWidth: 20, // Increase symbol width
                        itemStyle: {
                            fontSize: '30px' // Set legend item font size
                        }
                    },
                    series: [{
                        name: 'Actual',
                        data: [\(actualDataString)],
                        type: 'spline'
                    }, {
                        name: 'Estimate',
                        data: [\(estimateDataString)],
                        type: 'spline'
                    }]
                });
            </script>
        </body>
        </html>
        """


        return htmlContent
    }
    
//series: [{
//    name: 'Actual',
//    data: [\(actualDataString)],
//    type: 'spline',
//    color: 'blue'
//}, {
//    name: 'Estimate',
//    data: [\(estimateDataString)],
//    type: 'spline',
//    color: 'lightblue'
//}]



}

// Function to generate HTML and JavaScript for Highcharts
