import Foundation

class NetworkManager: ObservableObject {
    
    @Published var posts = [Post]()
    
    func fetchData(){
        if let url = URL(string: "https://hn.algolia.com/api/v1/search?tags=front_page") {
            let session: URLSession = {
                let config = URLSessionConfiguration.ephemeral
                return URLSession(configuration: config)
            }()
            let task = session.dataTask(with: url) { (data, response, error) in
                if error == nil {
                    let decoder = JSONDecoder()
                    if let fetchedData = data {
                        do {
                            let results = try decoder.decode(Results.self, from: fetchedData)
                            DispatchQueue.main.async {
                                self.posts = results.hits
                            }
                        } catch  {
                            print(error)
                        }
                    }
                }
            }
            task.resume()
        }

    }
    
}
