import Foundation

extension JSONDecoder {
    /// utility that makes it easy to see detailed decoding errors
    func decodeJSON<T: Decodable>(_ type: T.Type, from jsonData: Data) throws -> T {
        
        do {
            let decodedData = try decode(T.self, from: jsonData)
            return decodedData
        } catch {
            var logStr = "Decoding error for type: \(T.self)"
            if let rawJsonDataStr = String(data: jsonData, encoding: .utf8) {
                logStr += " – raw string of jsonData: \(rawJsonDataStr)"
            } else {
                logStr += " – no raw string of jsonData available :<"
            }
            // Perform the general logging
            print(logStr)

            // Now, handle specific DecodingError cases with a switch
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                    print("codingPath: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("Key '\(key)' not found: \(context.debugDescription)")
                    print("codingPath: \(context.codingPath)")
                case .valueNotFound(let value, let context):
                    print("Value '\(value)' not found: \(context.debugDescription)")
                    print("codingPath: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("Type '\(type)' mismatch: \(context.debugDescription)")
                    print("codingPath: \(context.codingPath)")
                @unknown default:
                    throw decodingError
                }
                // Re-throw the DecodingError for further handling
                throw decodingError
            } else {
                // Log and re-throw any other errors
                print("Unknown decoding error: \(error.localizedDescription)")
                throw error
            }
        }
    }

    /// utility that adds JS Date decoding. useful for node APIs. 
    static func withJSDateDecoding() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
        })
        
        return decoder
    }
}
