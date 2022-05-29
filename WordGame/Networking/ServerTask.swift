//
//
//	ServerTask.swift
//	WordGame
//
//	Created By Rakesh Kumar Raushan on 5/29/22
//	
//

//

import Foundation

class ServerTask {
    
    static var shared: ServerTask = ServerTask()
    
    private init() {}
    
    // Fetch Words from API
    func doRequestForWords(searchText:String,completion:@escaping([WordDetail])->()) {
        
        let url = URL(string: "https://api.datamuse.com/words?sp=\(searchText)*")
        guard let url = url else {
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
            do {
                guard data != nil else {completion([]); return}
                let result = try JSONDecoder().decode([WordDetail].self, from: data!)
                completion(result)
            }catch{
                print(error.localizedDescription)
                completion([])
            }
        })
        task.resume()
    }
}
