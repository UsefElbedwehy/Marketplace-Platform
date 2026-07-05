import Testing
@testable import Core

@Test func validationErrorDescriptionUsesFirstFieldMessage() {
    let error = DomainError.validation([
        FieldError(field: "mileage", code: "max", message: "Must be ≤ 2,000,000"),
        FieldError(field: "brand", code: "required", message: "Brand is required"),
    ])
    #expect(error.errorDescription == "Must be ≤ 2,000,000")
}

@Test func unknownErrorCarriesItsOwnMessage() {
    let error = DomainError.unknown(message: "Something odd happened")
    #expect(error.errorDescription == "Something odd happened")
}

@Test func fieldErrorIdentityIsFieldPlusCode() {
    let a = FieldError(field: "mileage", code: "max", message: "a")
    let b = FieldError(field: "mileage", code: "max", message: "different message, same field+code")
    #expect(a.id == b.id)
}
