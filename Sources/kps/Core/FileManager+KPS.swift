import Foundation

extension FileManager {
    /// 디렉토리를 생성 (중간 디렉토리 자동 생성)
    /// - Parameter url: 생성할 디렉토리 경로
    /// - Throws: 권한 오류 시 KPSError.file(.permissionDenied), 기타 오류 시 KPSError.file(.ioError)
    func createDirectoryIfNeeded(at url: URL) throws {
        guard !fileExists(atPath: url.path) else { return }

        do {
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            throw KPSError.from(error)
        }
    }

    /// 파일이 존재하는지 확인하고, 존재하면 에러를 던짐
    /// - Parameter url: 확인할 파일 경로
    /// - Throws: 파일이 이미 존재하면 KPSError.file(.alreadyExists)
    func ensureFileDoesNotExist(at url: URL) throws {
        if fileExists(atPath: url.path) {
            throw KPSError.file(.alreadyExists(url.path))
        }
    }

    /// 파일에 내용을 작성 (atomic write 사용)
    /// - Parameters:
    ///   - content: 작성할 내용
    ///   - url: 파일 경로
    /// - Throws: 권한 오류 시 KPSError.file(.permissionDenied), 기타 오류 시 KPSError.file(.ioError)
    func writeFile(content: String, to url: URL) throws {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch let error as NSError {
            throw KPSError.from(error)
        }
    }
}
