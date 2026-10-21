import GRDB

/// Days are stored as plain `YYYY-MM-DD` text.
extension Day: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        iso.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Day? {
        String.fromDatabaseValue(dbValue).flatMap(Day.init)
    }
}
