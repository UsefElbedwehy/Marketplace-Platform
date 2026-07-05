import Testing
import Core
import DomainKit
@testable import DynamicForms

@Suite @MainActor struct DynamicFormStateTests {
    @Test func fieldWithNoDependencyIsAlwaysVisible() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        #expect(state.isVisible(CarsSchemaFixture.brandField) == true)
    }

    @Test func visibleWhenHidesTheFieldUntilTheConditionIsMet() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        #expect(state.isVisible(CarsSchemaFixture.conditionNoteField) == false)

        state.setValue(.string("new"), for: CarsSchemaFixture.conditionField)
        #expect(state.isVisible(CarsSchemaFixture.conditionNoteField) == false)

        state.setValue(.string("used"), for: CarsSchemaFixture.conditionField)
        #expect(state.isVisible(CarsSchemaFixture.conditionNoteField) == true)
    }

    @Test func optionsFilteredByReturnsNoOptionsBeforeTheParentIsChosen() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        #expect(state.visibleOptions(for: CarsSchemaFixture.modelField).isEmpty)
    }

    @Test func optionsFilteredByNarrowsToTheSelectedParentOptionsChildren() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)

        state.setValue(.string("bmw"), for: CarsSchemaFixture.brandField)
        #expect(state.visibleOptions(for: CarsSchemaFixture.modelField).map(\.value) == ["x5"])

        state.setValue(.string("audi"), for: CarsSchemaFixture.brandField)
        #expect(state.visibleOptions(for: CarsSchemaFixture.modelField).map(\.value) == ["a4"])
    }

    @Test func fieldsWithNoDependencyReturnAllOfTheirOptionsUnfiltered() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        #expect(state.visibleOptions(for: CarsSchemaFixture.brandField).count == 2)
    }

    @Test func validateFlagsAMissingRequiredField() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        #expect(state.validate() == false)
        #expect(state.fieldErrors["brand"] != nil)
    }

    @Test func validateFlagsANumberBelowMinimum() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        state.setValue(.string("bmw"), for: CarsSchemaFixture.brandField)
        state.setValue(.string("x5"), for: CarsSchemaFixture.modelField)
        state.setValue(.string("used"), for: CarsSchemaFixture.conditionField)
        state.setValue(.number(1900), for: CarsSchemaFixture.yearField)

        #expect(state.validate() == false)
        #expect(state.fieldErrors["year"]?.contains("1970") == true)
    }

    @Test func validateFlagsATextValueOverMaxLength() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        state.setValue(.string("bmw"), for: CarsSchemaFixture.brandField)
        state.setValue(.string("x5"), for: CarsSchemaFixture.modelField)
        state.setValue(.number(2020), for: CarsSchemaFixture.yearField)
        state.setValue(.string("used"), for: CarsSchemaFixture.conditionField)
        state.setValue(.string("THIS_VIN_IS_DEFINITELY_TOO_LONG"), for: CarsSchemaFixture.vinField)

        #expect(state.validate() == false)
        #expect(state.fieldErrors["vin"]?.contains("17") == true)
    }

    @Test func validateSucceedsWithAllRequiredFieldsWithinBounds() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        state.setValue(.string("bmw"), for: CarsSchemaFixture.brandField)
        state.setValue(.string("x5"), for: CarsSchemaFixture.modelField)
        state.setValue(.number(2020), for: CarsSchemaFixture.yearField)
        state.setValue(.string("used"), for: CarsSchemaFixture.conditionField)

        #expect(state.validate() == true)
        #expect(state.fieldErrors.isEmpty)
    }

    @Test func validateIgnoresRequiredOnAHiddenField() {
        // conditionNote isn't required, but this proves the general "skip
        // hidden fields" rule using a field that WOULD otherwise be visible
        // only under a condition we don't meet.
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        state.setValue(.string("bmw"), for: CarsSchemaFixture.brandField)
        state.setValue(.string("x5"), for: CarsSchemaFixture.modelField)
        state.setValue(.number(2020), for: CarsSchemaFixture.yearField)
        state.setValue(.string("new"), for: CarsSchemaFixture.conditionField)

        #expect(state.validate() == true)
    }

    @Test func applyServerErrorsMapsFieldErrorsBackOntoTheForm() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        state.applyServerErrors([FieldError(field: "vin", code: "invalid", message: "VIN looks wrong")])
        #expect(state.fieldErrors["vin"] == "VIN looks wrong")
    }

    @Test func submittableAttributesExcludesHiddenFieldValues() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        state.setValue(.string("bmw"), for: CarsSchemaFixture.brandField)
        state.setValue(.string("x5"), for: CarsSchemaFixture.modelField)
        state.setValue(.string("new"), for: CarsSchemaFixture.conditionField)
        // Set while "used" was selected, then condition flipped back to "new" —
        // the stale note shouldn't leak into the submitted payload.
        state.setValue(.string("stale note"), for: CarsSchemaFixture.conditionNoteField)

        let submitted = state.submittableAttributes

        #expect(submitted["conditionNote"] == nil)
        #expect(submitted["brand"] == .string("bmw"))
    }

    @Test func settingANewValueClearsAnyExistingFieldError() {
        let state = DynamicFormState(schema: CarsSchemaFixture.schema)
        state.applyServerErrors([FieldError(field: "brand", code: "required", message: "Brand is required")])
        #expect(state.fieldErrors["brand"] != nil)

        state.setValue(.string("bmw"), for: CarsSchemaFixture.brandField)

        #expect(state.fieldErrors["brand"] == nil)
    }
}
