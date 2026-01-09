# KPS (Korean Problem Solving)

## 0. 프로젝트 정의

> **KPS는 알고리즘 문제 풀이를 '정돈된 개발 기록'으로 남기게 해주는 CLI 도구입니다.**

문제 풀이에 집중하는 동안, 파일 구조와 Git 기록은 KPS가 책임집니다.

## 1. 문제 정의

### 1.1 현재 상황

알고리즘 문제 풀이를 준비하는 개발자들은 백준(BOJ)과 프로그래머스를 주로 사용합니다. 문제를 풀 때마다 다음과 같은 반복 작업이 발생합니다:

1. 새 파일 생성 및 이름 지정
2. 헤더 주석 작성 (문제 번호, 날짜, 링크)
3. 기본 함수 템플릿 작성
4. 풀이 완료 후 Git 커밋 및 푸시

### 1.2 문제점

| 문제 | 영향 |
|------|------|
| 반복 작업으로 인한 시간 낭비 | 하루 10문제 기준 약 20-30분 소요 |
| 파일/폴더 구조 불일치 | 코드 관리 어려움, 가독성 저하 |
| 커밋 메시지 형식 불일치 | Git 히스토리 파악 어려움 |
| 문제 링크 복사 실수 | 나중에 문제 찾기 어려움 |
| 플랫폼별 관리 부재 | BOJ와 프로그래머스 파일 혼재 |

### 1.3 타겟 사용자

- 코딩 테스트를 준비하는 취업준비생
- 알고리즘 실력 향상을 원하는 현직 개발자
- Swift로 알고리즘을 공부하는 iOS 개발자
- 체계적인 문제 풀이 기록을 원하는 사람

### 1.4 스코프

KPS는 **Swift + Xcode 환경에 최적화된 도구**입니다. 이 조합에서 최고의 경험을 제공하는 것이 우선이며, 다른 언어 지원은 핵심 경험이 완성된 후 고려합니다.

## 2. 솔루션

### 2.1 핵심 가치

KPS는 알고리즘 풀이를 **'기록 가능한 학습 자산'**으로 만듭니다.

- 면접에서 꺼내볼 수 있는 **정돈된 코드 히스토리**
- 포트폴리오로 보여줄 수 있는 **체계적인 풀이 기록**
- 성장 과정을 증명하는 **개발자 학습 로그**

### 2.2 기존 방식과의 비교

기존에 알고리즘 풀이 관리는 각자의 스크립트나 수동 작업에 의존했습니다. KPS는 이를 표준화된 워크플로우로 제공합니다.

| 기존 방식 | KPS |
|-----------|-----|
| 수동 파일 생성 | `kps new` 한 줄로 완료 |
| URL에서 문제 번호 직접 추출 | URL 붙여넣기만으로 자동 파싱 |
| 플랫폼 구분 없이 파일 혼재 | BOJ/Programmers 폴더 자동 분리 |
| 매번 다른 커밋 메시지 | 일관된 형식으로 자동 생성 |

## 3. 핵심 기능 목록

### Priority 1 (MVP)

| 기능 | 설명 | 명령어 |
|------|------|--------|
| 프로젝트 초기화 | 설정 파일 생성 | `kps init` |
| 파일 생성 | 템플릿 포함 Swift 파일 생성 | `kps new` |
| Git 자동화 | add, commit, push 자동 실행 | `kps solve` |
| 설정 관리 | 설정 조회 및 수정 | `kps config` |

### Priority 2 (Post-MVP)

| 기능 | 설명 | 명령어 |
|------|------|--------|
| 문제 페이지 열기 | 브라우저에서 문제 페이지 오픈 | `kps open` |
| 풀이 목록 | 풀이한 문제 목록 조회 | `kps list` |
| 풀이 통계 | 플랫폼별, 기간별 통계 | `kps stats` |

### Priority 3 (Future)

| 기능 | 설명 |
|------|------|
| 문제 제목 크롤링 | 헤더에 문제 제목 자동 추가 |
| 테스트케이스 다운로드 | 예제 입출력 자동 다운로드 |

## 4. MVP 범위

### 4.1 포함

- `kps init`: 설정 파일(`.kps/config.json`) 생성
- `kps new`: URL 또는 문제 번호로 Swift 파일 생성
- `kps solve`: Git add, commit, push 자동화
- `kps config`: 설정 조회 및 수정
- 플랫폼 지원: 백준(BOJ), 프로그래머스
- URL 자동 파싱 및 플랫폼 감지
- 플랫폼별 폴더 자동 분리

### 4.2 제외 (MVP 이후)

- 문제 제목 크롤링
- 테스트케이스 다운로드
- 풀이 통계
- GUI 인터페이스
- 다른 언어(Python, Java 등) 지원

## 5. 안전장치 설계

### 5.1 Git 자동화 원칙

`kps solve`는 편리하지만 Git 자동화는 실패 시 신뢰를 잃는 영역입니다. KPS는 다음 원칙을 따릅니다:

- **문제 단위 add**: 의도하지 않은 파일이 포함되지 않도록 해당 문제 파일만 `git add` 수행
- **push 기본, 옵션으로 분리**: 기록을 완성하는 것이 목표이므로 push가 기본값, `--no-push`로 commit만 가능
- **실패 시 즉시 중단**: Git 명령 실패 시 KPS는 즉시 중단하며, 이미 실행된 작업(add, commit)은 사용자가 직접 확인하도록 안내

### 5.2 에러 메시지 원칙

사용자가 문제를 스스로 해결할 수 있도록 친절한 에러 메시지를 제공합니다:

```
❌ Unsupported URL
   Supported: acmicpc.net, school.programmers.co.kr
```

```
❌ File not found: AlgorithmStudy/BOJ/1000.swift
   Run 'kps new 1000 -b' first.
```

## 6. 사용자 시나리오

### 6.1 시나리오 1: 첫 설정

> 취준생 A는 알고리즘 스터디를 시작하며 Swift_Algorithm 프로젝트를 만들었다.

```bash
cd ~/Developer/Swift_Algorithm
kps init --author "A" --source AlgorithmStudy
```

**결과**:
```
✅ Config created!
   File: .kps/config.json
   Author: A
   Project: Swift_Algorithm
   Source folder: AlgorithmStudy
```

### 6.2 시나리오 2: 백준 문제 풀이

> A는 백준에서 1000번 문제를 풀기로 했다.

```bash
kps new "https://acmicpc.net/problem/1000"
```

**결과**:
```
✔ Platform: BOJ
✔ Problem: 1000
✔ File: AlgorithmStudy/BOJ/1000.swift
🔗 https://acmicpc.net/problem/1000
💡 Next: solve with 'kps solve 1000 -b'
```

생성된 파일:
```swift
//
//  1000.swift
//  Swift_Algorithm
//
//  Created by A on 2025/1/9.
//  https://acmicpc.net/problem/1000
//

func _1000() {
    
}
```

### 6.3 시나리오 3: 프로그래머스 문제 풀이

> A는 프로그래머스에서 340207번 문제를 풀기로 했다.

```bash
kps new "https://school.programmers.co.kr/learn/courses/30/lessons/340207"
```

**결과**:
```
✔ Platform: Programmers
✔ Problem: 340207
✔ File: AlgorithmStudy/Programmers/340207.swift
🔗 https://school.programmers.co.kr/learn/courses/30/lessons/340207
💡 Next: solve with 'kps solve 340207 -p'
```

생성된 파일:
```swift
//
//  340207.swift
//  Swift_Algorithm
//
//  Created by A on 2025/1/9.
//  https://school.programmers.co.kr/learn/courses/30/lessons/340207
//

func _340207() {
    
}
```

### 6.4 시나리오 4: 풀이 완료 및 커밋

> A는 1000번 문제를 풀고 GitHub에 기록을 남기려 한다.

```bash
kps solve 1000 -b
```

**결과**:
```
📦 Adding: AlgorithmStudy/BOJ/1000.swift
💾 Committing: solve: [BOJ] 1000
✔ Commit: a1b2c3d
🚀 Pushing to origin...
✅ Done!
```

### 6.5 시나리오 5: 에러 상황

> A가 지원하지 않는 URL을 입력했다.

```bash
kps new "https://leetcode.com/problems/two-sum"
```

**결과**:
```
❌ Unsupported URL
   Supported: acmicpc.net, school.programmers.co.kr
```

## 7. 네이밍 규칙

| 항목 | 규칙 | 이유 |
|------|------|------|
| 파일명 | `{문제번호}.swift` | 단순하고 검색 용이 |
| 함수명 | `_{문제번호}()` | Swift는 숫자로 시작하는 함수명 불가 |
| 폴더 구조 | `{sourceFolder}/{Platform}/{문제번호}.swift` | 플랫폼별 분류로 관리 용이 |

## 8. 성공 지표 (KPI)

### 8.1 채택 지표

| 지표 | 목표 (3개월) | 의미 |
|------|-------------|------|
| GitHub Stars | 50+ | 커뮤니티 관심 확인 |
| 설치 수 | 100+ | 실사용 검증 진입 |
| Fork 수 | 10+ | 기여 가능성 확인 |

### 8.2 품질 지표

| 지표 | 목표 | 의미 |
|------|------|------|
| GitHub Issues 해결율 | 80%+ | 유지보수 신뢰도 |
| 크리티컬 버그 | 0개 | 안정성 확보 |
| 빌드 성공률 | 100% | 배포 신뢰도 |

## 9. 릴리즈 계획

### Phase 1: MVP (현재)

- [x] `kps init` 구현
- [x] `kps new` 구현 (URL 파싱, 플랫폼 감지)
- [x] `kps solve` 구현 (Git 자동화)
- [x] `kps config` 구현
- [x] GitHub 오픈소스 공개

### Phase 2: 배포 확대

- [ ] Homebrew tap 배포
- [ ] README 영문화
- [ ] 사용 가이드 문서 작성
- [ ] 출력 메시지 UX 개선

### Phase 3: 기능 확장

- [ ] `kps open` 구현
- [ ] `kps list` 구현
- [ ] `kps stats` 구현

## 10. 장기 비전

KPS의 궁극적인 목표는 **"개발자 학습 로그 시스템"**입니다.

문제 풀이 기록을 단순 파일 저장이 아닌, 성장 과정을 증명하는 데이터로 만들고자 합니다. 이를 위해 풀이 날짜 인덱스, 재도전 추적, 난이도 메타데이터 등을 검토하고 있습니다.
