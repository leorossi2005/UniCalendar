//
//  Network.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 08/10/25.
//

import Foundation

//enum OperationResult<T> {
//    case success(T)
//    case failure
//}

internal func fetchText(from urlString: String) async throws -> String {
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        throw URLError(.badURL)
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        print("Invalid response")
        throw URLError(.badServerResponse)
    }
    
    guard let text = String(data: data, encoding: .utf8) else {
        print("Failed to decode body as UTF-8 text")
        throw URLError(.cannotDecodeContentData)
    }
    
    return text
}

internal func getYears() async throws -> [Year] {
    var yearsData: [Year] = []
    
    do {
        var text = try await fetchText(from: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php?aa=1")
        
        if let startRange = text.firstIndex(of: "{") {
            text = String(text[startRange...])
            if let semicolonIndex = text.lastIndex(of: ";") {
                text.removeSubrange(semicolonIndex..<(text.endIndex))
            }
        } else {
            print("No JSON object found in body")
            print("Raw body:\n\(text)")
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
            throw error
        }
        
        return yearsData.sorted(by: { $0.valore < $1.valore })
    } catch {
        print("Fetch error in getYears: ", error)
        throw error
    }
}

internal func getCourses(year: String) async throws -> [Corso] {
    var coursesData: [Corso] = []
    
    do {
        var text = try await fetchText(from: "https://logistica.univr.it/PortaleStudentiUnivr/combo.php?aa=" + year + "&page=corsi")
        
        if let startRange = text.firstIndex(of: "["), let endRange = text.lastIndex(of: "}") {
            text = String(text[startRange...endRange] + "]")
        } else {
            print("No JSON object found in body")
            print("Raw body:\n\(text)")
        }
        
        do {
            let decoder = JSONDecoder()
            let corsi = try decoder.decode([Corso].self, from: Data(text.utf8))
            
            coursesData = corsi
        } catch {
            print("Decoding failed:", error)
            print("Cleaned JSON candidate:\n\(text)")
            throw error
        }
        
        return coursesData
    } catch {
        print("Fetch error in getCourses: ", error)
        throw error
    }
}

func fetchOrario(corso: String, anno: String, selyear: String) async throws -> [Lesson] {
    guard let url = URL(string: "https://logistica.univr.it/PortaleStudentiUnivr/grid_call.php") else {
        throw URLError(.badURL)
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
    
    let (data, response) = try await URLSession.shared.data(for: request)
        
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        print("Invalid response in fetchOrario")
        throw URLError(.badServerResponse)
    }

    do {
        let decoder = JSONDecoder()
        var lessons: ResponseAPI = try decoder.decode(ResponseAPI.self, from: data)
        
        var colors: [String: String] = [:]
        var colorsIndex: Int = 0
    
        for i in lessons.celle.indices {
            var color: String = ""
            
            if lessons.celle[i].Annullato == "1" {
                color = "#FFFFFF"
            } else if lessons.celle[i].tipo == "chiusura_type" {
                color = "#BDF2F2"
            } else if !lessons.celle[i].color_index.isEmpty {
                print("Trovato uno")
            } else if colors[lessons.celle[i].codice_insegnamento] != nil {
                color = colors[lessons.celle[i].codice_insegnamento]!
            } else {
                color = lessons.colori[colorsIndex]
                
                colors[lessons.celle[i].codice_insegnamento] = color
                colorsIndex += 1
            }
    
            lessons.celle[i].color = color
        }
        
        return lessons.celle
    } catch {
        print("Errore parsing JSON:", error)
        if let text = String(data: data, encoding: .utf8) {
            print("Risposta testuale:\n", text)
        }
        
        throw error
    }
}
