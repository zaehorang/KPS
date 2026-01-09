# Week 1 Commit Plan

## Overview
Week 1 (Day 1-6) 작업을 6개의 기능별 커밋으로 나누어 진행합니다.

## Commit Strategy

### Commit 1: Project setup
**Files:**
- Package.swift
- Sources/kps/KPS.swift
- Deleted files (README.md, old Sources/kps/*.swift)

**Message:**
```
feat: set up project structure with ArgumentParser

- Update Package.swift to Swift 5.9 and add test target
- Rename main.swift to KPS.swift (Swift 6 compatibility)
- Add ArgumentParser configuration for CLI commands
- Remove old implementation files
```

### Commit 2: Core configuration models
**Files:**
- Sources/kps/Core/KPSError.swift
- Sources/kps/Core/Config.swift
- Sources/kps/Core/ConfigKey.swift
- Sources/kps/Core/ConfigLocator.swift

**Message:**
```
feat: add configuration management system

- Add KPSError enum with Equatable for Swift Testing
- Add KPSConfig model with JSON encoding/decoding
- Add atomic write support for config persistence
- Add ConfigLocator with monorepo support and git detection
- Add ConfigKey enum for configuration fields
```

### Commit 3: Domain models
**Files:**
- Sources/kps/Core/Platform.swift
- Sources/kps/Core/Problem.swift

**Message:**
```
feat: add platform and problem domain models

- Add Platform enum (BOJ, Programmers) with baseURL and folderName
- Add Problem struct with platform-specific function naming
```

### Commit 4: URL parser
**Files:**
- Sources/kps/Core/URLParser.swift

**Message:**
```
feat: add URL parser for problem platforms

- Support BOJ URLs (acmicpc.net, boj.kr)
- Support Programmers URLs (programmers.co.kr, school.programmers.co.kr)
- Normalize URLs for consistent storage
- Handle www prefix, query strings, and fragments
```

### Commit 5: Utility modules
**Files:**
- Sources/kps/Utils/Console.swift
- Sources/kps/Utils/DateFormatter+KPS.swift

**Message:**
```
feat: add console and date formatting utilities

- Add Console with stdout/stderr separation
- Add date formatter with POSIX locale for consistency
```

### Commit 6: Tests and documentation
**Files:**
- Tests/KPSTests/ConfigTests.swift
- Tests/KPSTests/ConfigLocatorTests.swift
- Tests/KPSTests/URLParserTests.swift
- CLAUDE.md
- docs/

**Message:**
```
test: add comprehensive test suite and documentation

- Add ConfigTests with encoding/decoding tests
- Add ConfigLocatorTests with monorepo scenario tests
- Add URLParserTests for all supported platforms
- Add CLAUDE.md with development guidelines and documentation rules
- All 22 tests passing with Swift Testing framework
```

## Execution Order
1. Stage files for commit 1
2. Review staged changes
3. Get user approval
4. Commit
5. Repeat for commits 2-6
