import Testing
import Foundation
@testable import kps

// MARK: - Error Description Tests

@Test("configNotFound should have helpful error message")
func configNotFoundHasHelpfulMessage() {
    let error = KPSError.configNotFound

    #expect(error.errorDescription?.contains("kps init") == true)
}

@Test("configNotFoundInGitRepo should mention git repository")
func configNotFoundInGitRepoMentionsGitRepo() {
    let error = KPSError.configNotFoundInGitRepo

    #expect(error.errorDescription?.contains("git repository") == true)
    #expect(error.errorDescription?.contains("kps init") == true)
}

@Test("invalidProblemNumber should provide clear message")
func invalidProblemNumberProvidesClearMessage() {
    let error = KPSError.invalidProblemNumber

    #expect(error.errorDescription != nil)
}

@Test("platformRequired should suggest using flags")
func platformRequiredSuggestsFlags() {
    let error = KPSError.platformRequired

    #expect(error.errorDescription?.contains("-b") == true ||
            error.errorDescription?.contains("-p") == true)
}

@Test("conflictingPlatformFlags should mention both flags")
func conflictingPlatformFlagsMentionsBothFlags() {
    let error = KPSError.conflictingPlatformFlags

    #expect(error.errorDescription?.contains("-b") == true)
    #expect(error.errorDescription?.contains("-p") == true)
}

@Test("urlWithPlatformFlag should explain the conflict")
func urlWithPlatformFlagExplainsConflict() {
    let error = KPSError.urlWithPlatformFlag

    #expect(error.errorDescription != nil)
}

@Test("invalidConfigKey should be informative")
func invalidConfigKeyIsInformative() {
    let error = KPSError.invalidConfigKey("invalid")

    #expect(error.errorDescription?.contains("invalid") == true)
}

@Test("fileAlreadyExists should mention the problem")
func fileAlreadyExistsMentionsTheProblem() {
    let error = KPSError.fileAlreadyExists("/path/to/file.swift")

    #expect(error.errorDescription?.contains("file.swift") == true)
}

@Test("fileNotFound should be clear")
func fileNotFoundIsClear() {
    let error = KPSError.fileNotFound("/path/to/file.swift")

    #expect(error.errorDescription?.contains("file.swift") == true)
}

@Test("gitNotAvailable should provide installation hint")
func gitNotAvailableProvidesInstallationHint() {
    let error = KPSError.gitNotAvailable

    #expect(error.errorDescription?.contains("Git") == true)
    #expect(error.errorDescription?.contains("git-scm.com") == true)
}

@Test("notGitRepository should suggest git init")
func notGitRepositorySuggestsGitInit() {
    let error = KPSError.notGitRepository

    #expect(error.errorDescription?.contains("git init") == true)
}

@Test("nothingToCommit should ask if file was saved")
func nothingToCommitAsksIfFileSaved() {
    let error = KPSError.nothingToCommit

    #expect(error.errorDescription?.contains("No changes") == true)
}

@Test("gitFailed should include stderr output")
func gitFailedIncludesStderrOutput() {
    let error = KPSError.gitFailed("test error output")

    #expect(error.errorDescription?.contains("test error output") == true)
}

@Test("gitPushFailed should include stderr output")
func gitPushFailedIncludesStderrOutput() {
    let error = KPSError.gitPushFailed("remote error")

    #expect(error.errorDescription?.contains("remote error") == true)
}

@Test("permissionDenied should mention permissions")
func permissionDeniedMentionsPermissions() {
    let error = KPSError.permissionDenied("/path/to/file")

    #expect(error.errorDescription?.lowercased().contains("permission") == true)
    #expect(error.errorDescription?.contains("/path/to/file") == true)
}

// MARK: - NSError Mapping Tests

@Test("NSFileWriteNoPermissionError should map to permissionDenied")
func nsFileWriteNoPermissionMapsToPermissionDenied() {
    let nsError = NSError(
        domain: NSCocoaErrorDomain,
        code: NSFileWriteNoPermissionError,
        userInfo: [NSFilePathErrorKey: "/test/path"]
    )

    let kpsError = KPSError.from(nsError)

    if case .permissionDenied(let path) = kpsError {
        #expect(path == "/test/path")
    } else {
        Issue.record("Expected permissionDenied, got \(kpsError)")
    }
}

@Test("NSFileReadNoPermissionError should map to permissionDenied")
func nsFileReadNoPermissionMapsToPermissionDenied() {
    let nsError = NSError(
        domain: NSCocoaErrorDomain,
        code: NSFileReadNoPermissionError,
        userInfo: [NSFilePathErrorKey: "/test/path"]
    )

    let kpsError = KPSError.from(nsError)

    if case .permissionDenied(let path) = kpsError {
        #expect(path == "/test/path")
    } else {
        Issue.record("Expected permissionDenied, got \(kpsError)")
    }
}

@Test("other NSErrors should map to fileIOError")
func otherNSErrorsMapsToFileIOError() {
    let nsError = NSError(
        domain: NSCocoaErrorDomain,
        code: 999,
        userInfo: nil
    )

    let kpsError = KPSError.from(nsError)

    if case .fileIOError = kpsError {
        // Success
    } else {
        Issue.record("Expected fileIOError, got \(kpsError)")
    }
}

// MARK: - Equality Tests

@Test("invalidProblemNumber should be equal to itself")
func invalidProblemNumberEqualityWorks() {
    let error1 = KPSError.invalidProblemNumber
    let error2 = KPSError.invalidProblemNumber

    #expect(error1 == error2)
}

@Test("invalidConfigKey with same value should be equal")
func invalidConfigKeyEqualityWorks() {
    let error1 = KPSError.invalidConfigKey("test")
    let error2 = KPSError.invalidConfigKey("test")

    #expect(error1 == error2)
}

@Test("fileAlreadyExists with same path should be equal")
func fileAlreadyExistsEqualityWorks() {
    let error1 = KPSError.fileAlreadyExists("/path/file.swift")
    let error2 = KPSError.fileAlreadyExists("/path/file.swift")

    #expect(error1 == error2)
}
