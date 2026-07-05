/// A minimal JSON scalar/array — just enough to decode the heterogeneous
/// blobs the contract carries (`Listing.attributesIndex`, `SchemaField.
/// validation`/`defaultValue`, `AttributeDependency.condition`) without a
/// full recursive JSON-value type. `DomainKit.AttributeValue` is the mapped
/// domain shape `CategoryRepositoryImpl`/`ListingRepositoryImpl` produce from
/// this.
enum JSONScalar: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONScalar])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let a = try? container.decode([JSONScalar].self) {
            self = .array(a)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON scalar")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .null: try container.encodeNil()
        }
    }
}
