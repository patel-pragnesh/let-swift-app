//
//  NetworkProvider.swift
//  LetSwift
//
//  Created by Kinga Wilczek on 19.05.2017.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Alamofire

//TODO: return request to make this cancelable
struct NetworkProvider {

    static let shared = NetworkProvider()

    private enum Constants {
        static let perPage = "per_page"
        static let page = "page"
        static let events = "events"
        static let speakers = "speakers"
    }

    private init() {}

    func eventsList(with page: Int, perPage: Int, completionHandler: @escaping (NetworkReponse<NetworkPage<Event>>) -> ()) {
        Alamofire
            .request(NetworkRouter.eventsList([Constants.perPage: perPage, Constants.page: page]))
            .responseJSON { response in
                self.parsePage(response: response, with: Constants.events, completionHandler: completionHandler)
            }
    }

    func speakersList(with page: Int, perPage: Int, completionHandler: @escaping (NetworkReponse<NetworkPage<Speaker>>) -> ()) {
        Alamofire
            .request(NetworkRouter.speakersList([Constants.perPage: perPage, Constants.page: page]))
            .responseJSON { response in
                self.parsePage(response: response, with: Constants.speakers, completionHandler: completionHandler)
        }
    }

    private func parsePage<Element>(response: DataResponse<Any>, with key: String, completionHandler: @escaping (NetworkReponse<NetworkPage<Element>>) -> ()) {
        switch response.result {
        case .success(let result):
            guard let json = result as? NSDictionary, let object = NetworkPage<Element>.from(json, with: key) else {
                return completionHandler(.error(NetworkError.invalidObjectParse))
            }

            completionHandler(.success(object))
        case .failure(let error):
            completionHandler(.error(error))
        }
    }

}
