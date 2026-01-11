# Commit Convention

[Conventional Commits](https://www.conventionalcommits.org/) 기반의 커밋 메시지 규칙입니다.

## Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

- `scope`, `body`, `footer`는 선택 사항입니다.

## Types

| Type | 설명 |
|------|------|
| `feat` | 새로운 기능 추가 |
| `fix` | 버그 수정 |
| `docs` | 문서 수정 |
| `style` | 코드 포맷팅, 세미콜론 누락 등 (로직 변경 없음) |
| `refactor` | 코드 리팩토링 (기능 변경 없음) |
| `test` | 테스트 코드 추가/수정 |
| `chore` | 빌드 설정, 패키지 설정 등 |
| `perf` | 성능 개선 |
| `ci` | CI/CD 설정 변경 |

## Subject

- 50자 이내로 작성
- 마침표 사용하지 않음
- 명령문으로 작성 (Add, Fix, Update, Remove 등)

## Body

- Subject와 한 줄 띄워서 작성
- **무엇을**, **왜** 변경했는지 설명
- 각 항목은 `-`로 시작

## Footer

- Breaking Change 또는 Issue 참조 시 사용

## Examples

### 기본 형태

```
feat: add user authentication
```

### Scope 포함

```
feat(auth): add JWT token validation
```

### Body 포함

```
fix: prevent race condition in cache

- Add mutex lock before cache access
- Handle timeout for lock acquisition
```

### Breaking Change

```
feat!: change API response format

BREAKING CHANGE: Response now returns data wrapped in 'result' field.
Clients need to update their parsing logic.
```

### Issue 참조

```
fix: resolve memory leak in image processing

Fixes #123
Refs #456, #789
```

## Commit 단위

- 하나의 커밋 = 하나의 논리적 변경
- 작동하는 상태로 커밋 (빌드 깨지지 않게)
- 관련 테스트는 구현과 함께 커밋

## 제외 사항

- 커밋 메시지는 작성자 본인의 의도와 변경 내용만 기록
