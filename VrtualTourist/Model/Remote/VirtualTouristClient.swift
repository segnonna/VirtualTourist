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
        static let perPage = 30
        static let base = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=95e591f77ecc3dda1923f7c249c79356&per_page=\(perPage)"
        
        case searchImage(String, String,Int)
        
        case urlImage(String, String, String)
        
        
        
        var stringValue: String {
            switch self {
            case .searchImage(let latitude, let longitude, let page): return "\(Endpoints.base)&lat=\(latitude)&lon=\(longitude)&page=\(page)&format=json&nojsoncallback=1"
            case .urlImage(let server, let id, let secret): return  "https://live.staticflickr.com/\(server)/\(id)_\(secret).jpg"
            }
            
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func loadImagesByLocation (latitude:Double, longitude:Double, totalPage: Int, completion: @escaping (Photos?, Error?) -> Void){
        
        
        let task = URLSession.shared.dataTask(with: Endpoints.searchImage(String(format: "%.1f", latitude), String(format: "%.1f", longitude), Int.random(in: 1...totalPage)).url) { data, response, error in
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
                    completion(responseObject.photos, nil)
                }
            } catch {
                print(error)
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    class func loadPhoto(_ locationImage: LocationImage, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.downloadTask(with: VirtualTouristClient.Endpoints.urlImage(locationImage.server ?? "", locationImage.id ?? "", locationImage.secret ?? "").url) { tempURL, response, error in
            guard error == nil, tempURL != nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            if let data = try? Data(contentsOf: tempURL!) {
                DispatchQueue.main.async {
                    completion(data, nil)
                }
            }
        }
        task.resume()
    }
}
