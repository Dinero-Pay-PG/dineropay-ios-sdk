//
//  RestApiClient.swift
//  AkuratecoSDK
//
//  Created by Bodia on 08.03.2021.
//

import Foundation

final class AkuratecoRestApiClient {
    
    private let urlSession: URLSession = .shared
    var printRequestInfo = true
    
    @discardableResult
    func send(_ dataRequest: AkuratecoDataRequest, callback: @escaping (AkuratecoDataResponse) -> Void) -> URLSessionDataTask {
        let task = urlSession.dataTask(with: dataRequest.request) { [weak self] (data, response, error) in
            self?.printDataResponse(response, request: dataRequest.request, data: data)
            
            DispatchQueue.main.async {
                callback(AkuratecoDataResponse(data: data, response: response, error: error))                
            }
        }
        task.resume()
        
        return task
    }
    
    func printDataResponse(_ dataResponse: URLResponse?, request: URLRequest?, data: Data?) {
        #if DEBUG
        if printRequestInfo {
            var printString = "\n\n-------------------------------------------------------------\n"
            
            if let urlDataResponse = dataResponse as? HTTPURLResponse {
                let statusCode = urlDataResponse.statusCode
                printString += "\(statusCode == 200 ? "SUCCESS" : "ERROR") \(statusCode)\n"
            }
            
            var responceArray: [[String: Any]] = []
            // REQUEST
            if let request = request {
                var requestArray: [[String: Any]] = []
                
                // URL
                requestArray.append(["!!!<URL>!!!": request.url?.absoluteString ?? ""])
                
                // HEADERS
                if let headers = request.allHTTPHeaderFields {
                    requestArray.append(["!!!<HEADERS>!!!": headers])
                } else {
                    requestArray.append(["!!!<HEADERS>!!!": ["SYSTEM PRINT": "No Headers"]])
                }
                
                // PARAMETERS
                if let httpBody = request.httpBody {
                    if let stringBody = String(data: httpBody, encoding: .ascii) {
                        let formatedBody = stringBody.components(separatedBy: "&").map { $0.replacingOccurrences(of: "=", with: ": ") }
                        requestArray.append(["!!!<PARAMETERS>!!!": formatedBody])
                        
                    } else {
                        requestArray.append(["!!!<PARAMETERS>!!!": ["SYSTEM PRINT": "No parameters"]])
                    }
                }
                
                responceArray.append(["!!!<REQUEST>!!!": requestArray])
            } else {
                responceArray.append(["!!!<REQUEST>!!!": [["SYSTEM PRINT": "No Request"]]])
            }
            
            // RESPONSE
            do {
                if let data = data {
                    let temDictData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    responceArray.append(["!!!<RESPONSE>!!!": temDictData])
                } else {
                    responceArray.append(["!!!<RESPONSE>!!!": ["SYSTEM PRINT": "No Data"]])
                }
                
            } catch {
                responceArray.append(["!!!<RESPONSE>!!!": ["SYSTEM PRINT": "Throw error: \(error)"]])
            }
            
            // Print
            do {
                var httpMethod = request?.httpMethod ?? ""
                if !httpMethod.isEmpty {
                    httpMethod += "\n"
                }
                
                let data = try JSONSerialization.data(withJSONObject: ["!!!<RESTAPIMANAGER>!!!": responceArray], options: .prettyPrinted)
                var responceString = String.init(data: data, encoding: .utf8) ?? ""
                responceString = responceString.replacingOccurrences(of: "\"!!!<RESTAPIMANAGER>!!!\" :", with: "")
                responceString = responceString.replacingOccurrences(of: "{\n   [\n    {\n      \"!!!<REQUEST>!!!\" : ", with: "\n\(httpMethod)REQUEST:")
                responceString = responceString.replacingOccurrences(of: "[\n        {\n          \"!!!<URL>!!!\" : ", with: "\n\tURL: \n\t\t  ")
                responceString = responceString.replacingOccurrences(of: "        },\n        {\n          \"!!!<HEADERS>!!!\" : ", with: "\tHEADERS: \n\t\t  ")
                responceString = responceString.replacingOccurrences(of: "\n        },\n        {\n          \"!!!<PARAMETERS>!!!\" : ", with: "\n\tPARAMETERS:\n\t\t  ")
                responceString = responceString.replacingOccurrences(of: "\n        }\n      ]\n    },\n    {\n      \"!!!<RESPONSE>!!!\" : ", with: "\nRESPONSE:\n\t  ")
                responceString = responceString.replacingOccurrences(of: "\\/", with: "/")
                if responceString.count > 12 {
                    responceString.removeLast(12) // "\n    }\n  ]\n}"
                }
                
                if responceString.isEmpty {
                    responceString = "Can't create string from responce"
                }
                
                printString += responceString + "\n"
            } catch {
                printString += "ERROR PRINTING RESPONCE\n"
            }
            
            printString += "-------------------------------------------------------------\n\n"
            
            print(printString)
        }
        #endif
    }
}

public final class AkuratecoDataRequest {
    
    fileprivate let request: URLRequest

    init<T: Encodable>(url: URL,
                       httpMethod: AkuratekoHttpMethod,
                       body: T) {
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue.capitalized
        
        request.httpBody = (body as? XWWWFormUrlEncodable)?.formUrlEncodableData
        
        request.allHTTPHeaderFields = [
            "X-User-Agent": "ios",
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        self.request = request
    }
}

public struct AkuratecoDataResponse {
    public let data: Data?
    public let response: URLResponse?
    public let error: Error?
}

enum AkuratekoHttpMethod: String {
    case get, post
}
