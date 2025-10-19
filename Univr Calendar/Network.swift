//
//  Network.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation

enum OperationResult<T> {
    case success(T)
    case failure
}

internal func fetch(url: String, completion: @escaping (OperationResult<String>) -> Void) {
    guard let url = URL(string: url) else {
        print("Invalid URL")
        completion(.failure)
        return
    }

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if error != nil {
            print("Request error")
            DispatchQueue.main.async { completion(.failure) }
            return
        }

        guard let data = data else {
            print("No data returned")
            DispatchQueue.main.async { completion(.failure) }
            return
        }

        // Convert to text to remove JS prefix/suffix
        guard let text = String(data: data, encoding: .utf8) else {
            print("Failed to decode body as UTF-8 text")
            DispatchQueue.main.async { completion(.failure) }
            return
        }

        DispatchQueue.main.async { completion(.success(text)) }
    }
    task.resume()
}

internal func getYears(completion: @escaping ([Year]) -> Void) {
    var yearsData: [Year] = []
    
    fetch(url: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php?aa=1") { result in
        switch result {
        case .success(var text):
            if let startRange = text.firstIndex(of: "{") {
                text = String(text[startRange...])
                if let semicolonIndex = text.lastIndex(of: ";") {
                    text.removeSubrange(semicolonIndex..<(text.endIndex))
                }
            } else {
                print("No JSON object found in body")
                print("Raw body:\n\(text)")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let anni = try decoder.decode([String: Year].self, from: Data(text.utf8))
                
                for (_, obj) in anni.sorted(by: { $0.key < $1.key }) {
                    yearsData.append(Year(label: obj.label, valore: obj.valore))
                }
            } catch {
                print("Decoding failed:", error)
                print("Cleaned JSON candidate:\n\(text)")
            }
            
            completion(yearsData.sorted(by: { $0.valore < $1.valore }))
        case .failure:
            print("Completion error")
            return
        }
    }
}

internal func getCourses(year: String, completion: @escaping ([Corso]) -> Void) {
    var coursesData: [Corso] = []
    
    fetch(url: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php?aa=" + year + "&page=corsi") { result in
        switch result {
        case .success(var text):
            // Keep only the JSON portion between the first '{' and the matching closing '}'
            if let startRange = text.firstIndex(of: "["), let endRange = text.lastIndex(of: "}") {
                text = String(text[startRange...endRange] + "]")
            } else {
                print("No JSON object found in body")
                print("Raw body:\n\(text)")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let corsi = try decoder.decode([Corso].self, from: Data(text.utf8))
                
                coursesData = corsi
            } catch {
                print("Decoding failed:", error)
                print("Cleaned JSON candidate:\n\(text)")
            }
            
            //completion(yearsData.sorted(by: { $0.valore > $1.valore }))
            completion(coursesData)
        case .failure:
            print("Completion error")
            return
        }
    }
}

func fetchOrario(corso: String, anno: String, selyear: String, completion: @escaping (OperationResult<[Lesson]>) -> Void) {
    guard let url = URL(string: "https://logistica.univr.it/PortaleStudentiUnivr/grid_call.php") else {
        completion(.failure)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "Accept")
    
    let dateformatter: DateFormatter = DateFormatter()
    dateformatter.dateFormat = "dd-MM-yyyy"
    
    let params: [String: String] = [
        "view": "easycourse",
        "include": "corso",
        "anno": selyear,
        "cdl": corso,
        "anno2": anno,
        "_lang": "it",
        "date": dateformatter.string(from: Date()),
        "all_events": "1",
        "ar_codes_": "",
        "ar_select_": "",
    ]

    // Converti in formato x-www-form-urlencoded
    let bodyString = params.map { "\($0.key)=\($0.value)" }
                           .joined(separator: "&")
                           .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
                           .replacingOccurrences(of: "+", with: "%20") ?? ""

    request.httpBody = bodyString.data(using: .utf8)

    // 🔥 Fai la richiesta
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data, error == nil else {
            print("Errore rete:", error ?? "")
            completion(.failure)
            return
        }

        do {
            // Decodifica il JSON generico
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            
            var lessons: [Lesson] = []
            var colors: [String: String] = [:]
            if let events = json["celle"] as? [[String: Any]], let allColors = json["colori"] as? [String] {
                var colorsIndex: Int = 0
                
                for evento in events {
                    var color: String = ""
                    
                    if evento["Annullato"] as? String == "1" {
                        color = "#FFFFFF"
                    } else if evento["tipo"] as? String == "chiusura_type" {
                        color = "#BDF2F2"
                    } else if evento["color_index"] != nil {
                        print("Trovato uno")
                    } else if colors[evento["codice_insegnamento"] as? String ?? ""] != nil {
                        color = colors[evento["codice_insegnamento"] as? String ?? ""]!
                    } else {
                        color = allColors[colorsIndex]
                        
                        colors[evento["codice_insegnamento"] as? String ?? ""] = allColors[colorsIndex]
                        colorsIndex += 1
                    }
                    
                    lessons.append(.init(
                        nome_insegnamento: evento["nome_insegnamento"] as? String ?? "",
                        name_original: evento["name_original"] as? String ?? "",
                        orario: evento["orario"] as? String ?? "",
                        data: evento["data"] as? String ?? "",
                        aula: evento["aula"] as? String ?? "",
                        docente: evento["docente"] as? String ?? "",
                        color: color,
                        type: evento["tipo"] as? String ?? ""
                    ))
                }
            }
            
            completion(.success(lessons))
        } catch {
            print("Errore parsing JSON:", error)
            if let text = String(data: data, encoding: .utf8) {
                print("Risposta testuale:\n", text)
            }
            completion(.failure)
        }
    }.resume()
}
