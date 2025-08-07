import Foundation

struct ShippingMethod: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let cost: Double
    let estimatedDays: Int
    let isAvailable: Bool
    let trackingIncluded: Bool
    let insuranceIncluded: Bool
    
    var displayName: String {
        if cost == 0 {
            return "\(name) - FREE"
        }
        return "\(name) - $\(String(format: "%.2f", cost))"
    }
    
    var formattedCost: String {
        if cost == 0 {
            return "FREE"
        }
        return "$\(String(format: "%.2f", cost))"
    }
    
    var estimatedDeliveryText: String {
        switch estimatedDays {
        case 1:
            return "1 business day"
        case 2...7:
            return "\(estimatedDays) business days"
        default:
            return "\(estimatedDays) days"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, cost
        case estimatedDays = "estimated_days"
        case isAvailable = "is_available"
        case trackingIncluded = "tracking_included"
        case insuranceIncluded = "insurance_included"
    }
}