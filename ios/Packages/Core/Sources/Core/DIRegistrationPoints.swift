/// `AppLogger`'s Container registration lives here (not the App target) since
/// `OSAppLogger.shared` is a real, environment-independent default — unlike
/// the protocols in `DomainKit`'s `DIRegistrationPoints.swift`, nothing ever
/// needs to override this one.
extension Container {
    public var appLogger: Factory<AppLogger> {
        self { OSAppLogger.shared }
    }
}
