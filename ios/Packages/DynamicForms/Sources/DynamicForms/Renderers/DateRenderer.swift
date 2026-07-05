import DesignSystem
import DomainKit
import SwiftUI

public struct DateRenderer: FieldRenderer {
    public init() {}

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(DateRendererView(value: value))
    }
}

private struct DateRendererView: View {
    private static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    @Binding var value: AttributeValue?

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                if case .string(let s) = value, let date = Self.isoDate.date(from: s) { return date }
                return Date()
            },
            set: { value = .string(Self.isoDate.string(from: $0)) }
        )
    }

    var body: some View {
        DatePicker("", selection: dateBinding, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
    }
}
