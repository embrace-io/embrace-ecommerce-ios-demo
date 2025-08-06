import SwiftUI

struct PricePreset: Hashable, Identifiable {
    let id = UUID()
    let label: String
    let min: Double
    let max: Double
}

struct FiltersView: View {
    let availableBrands: [String]
    @Binding var selectedBrands: Set<String>
    @Binding var priceRange: PriceRange
    @Binding var inStockOnly: Bool
    
    let onApply: () -> Void
    let onClear: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempSelectedBrands: Set<String>
    @State private var tempPriceRange: PriceRange
    @State private var tempInStockOnly: Bool
    
    init(availableBrands: [String],
         selectedBrands: Binding<Set<String>>,
         priceRange: Binding<PriceRange>,
         inStockOnly: Binding<Bool>,
         onApply: @escaping () -> Void,
         onClear: @escaping () -> Void) {
        self.availableBrands = availableBrands
        self._selectedBrands = selectedBrands
        self._priceRange = priceRange
        self._inStockOnly = inStockOnly
        self.onApply = onApply
        self.onClear = onClear
        
        self._tempSelectedBrands = State(initialValue: selectedBrands.wrappedValue)
        self._tempPriceRange = State(initialValue: priceRange.wrappedValue)
        self._tempInStockOnly = State(initialValue: inStockOnly.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    priceRangeSection
                    brandsSection
                    availabilitySection
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        tempSelectedBrands.removeAll()
                        tempPriceRange = PriceRange()
                        tempInStockOnly = false
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Price Range")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("$\(Int(tempPriceRange.min)) - $\(Int(tempPriceRange.max))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Text("Min: $\(Int(tempPriceRange.min))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Max: $\(Int(tempPriceRange.max))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("$0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $tempPriceRange.min, in: 0...tempPriceRange.max, step: 10)
                            .accentColor(.blue)
                        
                        Text("$\(Int(tempPriceRange.max))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("$\(Int(tempPriceRange.min))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $tempPriceRange.max, in: tempPriceRange.min...1000, step: 10)
                            .accentColor(.blue)
                        
                        Text("$1000")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 12) {
                ForEach(pricePresets, id: \.self) { preset in
                    Button(preset.label) {
                        tempPriceRange.min = preset.min
                        tempPriceRange.max = preset.max
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        (tempPriceRange.min == preset.min && tempPriceRange.max == preset.max) ?
                        Color.blue : Color(.systemGray6)
                    )
                    .foregroundColor(
                        (tempPriceRange.min == preset.min && tempPriceRange.max == preset.max) ?
                        .white : .primary
                    )
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var brandsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Brands")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !tempSelectedBrands.isEmpty {
                    Text("\(tempSelectedBrands.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if availableBrands.isEmpty {
                Text("No brands available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(availableBrands, id: \.self) { brand in
                        BrandFilterRow(
                            brand: brand,
                            isSelected: tempSelectedBrands.contains(brand)
                        ) { isSelected in
                            if isSelected {
                                tempSelectedBrands.insert(brand)
                            } else {
                                tempSelectedBrands.remove(brand)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Availability")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("In stock only", isOn: $tempInStockOnly)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var pricePresets: [PricePreset] {
        [
            PricePreset(label: "Under $50", min: 0, max: 50),
            PricePreset(label: "$50 - $100", min: 50, max: 100),
            PricePreset(label: "$100 - $250", min: 100, max: 250),
            PricePreset(label: "$250 - $500", min: 250, max: 500),
            PricePreset(label: "Over $500", min: 500, max: 1000)
        ]
    }
    
    private func applyFilters() {
        selectedBrands = tempSelectedBrands
        priceRange = tempPriceRange
        inStockOnly = tempInStockOnly
        onApply()
    }
}

struct BrandFilterRow: View {
    let brand: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedBrands: Set<String> = ["Apple"]
        @State private var priceRange = PriceRange(min: 50, max: 500)
        @State private var inStockOnly = true
        
        var body: some View {
            FiltersView(
                availableBrands: ["Apple", "Samsung", "Nike", "Adidas", "Sony"],
                selectedBrands: $selectedBrands,
                priceRange: $priceRange,
                inStockOnly: $inStockOnly,
                onApply: {},
                onClear: {}
            )
        }
    }
    
    return PreviewWrapper()
}