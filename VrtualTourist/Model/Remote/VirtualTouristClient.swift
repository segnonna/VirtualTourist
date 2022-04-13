//
//  VirtualTouristClient.swift
//  VrtualTourist
//
//  Created by Segnonna Hounsou on 12/04/2022.
//

import Foundation

class VirtualTouristClient {
    let API_KEY = "95e591f77ecc3dda1923f7c249c79356"
    let SECRET_KEY = "3cafb5025ae20835"
   
    
    let BASE_URL = "https://api.flickr.com/services/rest/?method=flickr.photos.search&"
    ///https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=95e591f77ecc3dda1923f7c249c79356&lat=37.7994&lon=122.3950
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=95e591f77ecc3dda1923f7c249c79356"
        
        case searchImage(String, String)
        
        case urlImage(String, String, String)
        
        
        
        var stringValue: String {
            switch self {
            case .searchImage(let latitude, let longitude): return "\(Endpoints.base)&lat=\(latitude)&lon=\(longitude)&format=json&nojsoncallback=1"
            case .urlImage(let server, let id, let secret): return  "https://live.staticflickr.com/\(server)/\(id)_\(secret).jpg"
            }
            
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func loadImagesByLocation (latitude:Double, longitude:Double, completion: @escaping ([Photo]?, Error?) -> Void){
        
        let task = URLSession.shared.dataTask(with: Endpoints.searchImage(String(format: "%.1f", latitude), String(format: "%.1f", longitude)).url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(PhotoResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject.photos.photo, nil)
                }
            } catch {
                print(error)
                completion(nil, error)
            }
        }
        task.resume()
    }
}
