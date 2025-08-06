import Foundation

struct Address: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let street: String
    let street2: String?
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let isDefault: Bool
    let type: AddressType
    
    enum AddressType: String, Codable {
        case shipping
        case billing
        case both
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var formattedAddress: String {
        var address = street
        if let street2 = street2, !street2.isEmpty {
            address += "\n\(street2)"
        }
        address += "\n\(city), \(state) \(zipCode)"
        if country != "US" {
            address += "\n\(country)"
        }
        return address
    }
    
    enum CodingKeys: String, CodingKey {
        case id, street, street2, city, state, country, type
        case firstName = "first_name"
        case lastName = "last_name"
        case zipCode = "zip_code"
        case isDefault = "is_default"
    }
}