import Foundation

/// Metadata for a model available on the NVIDIA API.
struct NvidiaModel: Codable, Identifiable, Hashable {
    let id: String
    let object: String?
    let created: Int?
    let ownedBy: String?

    /// Context window length in tokens, when reported by the API.
    /// Used by `TokenEstimator` to warn before overflow.
    var contextLength: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case ownedBy = "owned_by"
        case contextLength
    }

    /// Human-readable display name derived from the model id.
    var displayName: String {
        id
            .replacingOccurrences(of: "nvidia/", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

/// Response envelope for `GET /v1/models`.
struct ModelsResponse: Codable {
    let data: [NvidiaModel]
}
