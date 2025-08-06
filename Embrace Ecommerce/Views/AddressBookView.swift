import SwiftUI

struct AddressBookView: View {
    @StateObject private var profileManager = UserProfileManager()
    @State private var showingAddAddress = false
    @State private var selectedAddress: Address?
    @State private var showingDeleteAlert = false
    @State private var addressToDelete: Address?
    
    var body: some View {
        NavigationView {
            ZStack {
                if profileManager.addresses.isEmpty && !profileManager.isLoading {
                    emptyStateView
                } else {
                    addressListView
                }
                
                if profileManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationTitle("Address Book")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedAddress = nil
                        showingAddAddress = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAddress) {
                AddressFormView(address: selectedAddress) { updatedAddress in
                    Task {
                        if selectedAddress != nil {
                            await profileManager.updateAddress(updatedAddress)
                        } else {
                            await profileManager.addAddress(updatedAddress)
                        }
                    }
                }
            }
            .alert("Delete Address", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let address = addressToDelete {
                        Task {
                            await profileManager.deleteAddress(id: address.id)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this address? This action cannot be undone.")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Addresses")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first address to make checkout faster")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                selectedAddress = nil
                showingAddAddress = true
            } label: {
                Text("Add Address")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var addressListView: some View {
        List {
            ForEach(profileManager.addresses) { address in
                AddressRowView(address: address) {
                    selectedAddress = address
                    showingAddAddress = true
                } onDelete: {
                    addressToDelete = address
                    showingDeleteAlert = true
                }
            }
        }
        .refreshable {
            await profileManager.loadAddresses()
        }
    }
}

struct AddressRowView: View {
    let address: Address
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(address.fullName)
                        .font(.headline)
                    
                    Text(address.formattedAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if address.isDefault {
                        Text("Default")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    Text(address.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 16) {
                Button("Edit") {
                    onEdit()
                }
                .foregroundColor(.blue)
                
                Button("Delete") {
                    onDelete()
                }
                .foregroundColor(.red)
                
                Spacer()
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct AddressFormView: View {
    let address: Address?
    let onSave: (Address) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var street: String = ""
    @State private var street2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = "US"
    @State private var addressType: Address.AddressType = .both
    @State private var isDefault: Bool = false
    
    private var isEditing: Bool {
        address != nil
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !street.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        TextField("First Name", text: $firstName)
                    }
                    
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        TextField("Last Name", text: $lastName)
                    }
                }
                
                Section("Address Information") {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        TextField("Street Address", text: $street)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        TextField("Apt, Suite, Unit (Optional)", text: $street2)
                    }
                    
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        TextField("City", text: $city)
                    }
                    
                    HStack {
                        HStack {
                            Image(systemName: "map")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            TextField("State", text: $state)
                        }
                        
                        TextField("ZIP Code", text: $zipCode)
                            .keyboardType(.numberPad)
                    }
                    
                    Picker("Country", selection: $country) {
                        Text("United States").tag("US")
                        Text("Canada").tag("CA")
                        Text("United Kingdom").tag("GB")
                    }
                }
                
                Section("Address Type") {
                    Picker("Type", selection: $addressType) {
                        Text("Shipping").tag(Address.AddressType.shipping)
                        Text("Billing").tag(Address.AddressType.billing)
                        Text("Both").tag(Address.AddressType.both)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Toggle("Set as default address", isOn: $isDefault)
                }
            }
            .navigationTitle(isEditing ? "Edit Address" : "Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAddress()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadAddressData()
            }
        }
    }
    
    private func loadAddressData() {
        guard let address = address else { return }
        
        firstName = address.firstName
        lastName = address.lastName
        street = address.street
        street2 = address.street2 ?? ""
        city = address.city
        state = address.state
        zipCode = address.zipCode
        country = address.country
        addressType = address.type
        isDefault = address.isDefault
    }
    
    private func saveAddress() {
        let newAddress = Address(
            id: address?.id ?? UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            street: street,
            street2: street2.isEmpty ? nil : street2,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            isDefault: isDefault,
            type: addressType
        )
        
        onSave(newAddress)
    }
}

#Preview {
    AddressBookView()
}