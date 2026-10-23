# DPP Remix 실습 가이드 (수강생용)

이 문서는 **처음 해보는 사람도 화면만 따라 하면 끝까지 갈 수 있도록** 쓴 실습 설명서입니다.
강사용 순서표는 [RUN_ORDER.md](./RUN_ORDER.md), 고정 입력값은 [TEST_VALUES.md](./TEST_VALUES.md)를 보세요.

> 한 줄 요약: **원본 개인정보는 체인에 올리지 말고, "검증 가능한 증거"만 남긴다.** 이 실습으로 그 이유를 직접 확인합니다.

---

## 0. 시작하기 전에 (공통 준비)

### 0-1. Remix 열기
1. 브라우저에서 **https://remix.ethereum.org** 에 접속합니다. (자동으로 `app.remix.live` 로 이동할 수 있어요 — 정상입니다.)
2. 왼쪽 세로 아이콘 막대에서 아이콘을 눌러 패널을 바꿉니다.
   - **Files**: 파일 만들기/열기
   - **Solidity Compiler**: 컴파일(코드를 실행 가능한 형태로 변환)
   - **Deploy & Run Transactions**: 배포하고 함수 실행

### 0-2. 컴파일러 버전 맞추기 (중요)
- **Solidity Compiler** 패널 → **COMPILER** 드롭다운에서 **`0.8.26`** 을 선택합니다. (예: `0.8.26+commit.8a97fa7a`)
- *왜?* 덱·교재·컨트랙트 `pragma`가 모두 **0.8.26** 기준이라, 버전을 맞춰야 경고 없이 깔끔하게 컴파일됩니다.

### 0-3. 실행 환경(Environment) 맞추기 (중요)
- **Deploy & Run Transactions** 패널 → **ENVIRONMENT** 에서 반드시 **`Remix VM`** 을 선택합니다.
- *왜?* Remix VM은 브라우저 안의 **연습용 가상 블록체인**입니다. 실제 돈·실제 네트워크를 쓰지 않아 안전합니다.
- **ACCOUNT** 드롭다운에 `100 ETH`를 가진 연습 계정이 여러 개 보입니다. 역할을 이렇게 정합니다.

  | 역할 | 계정 |
  |---|---|
  | Holder(보유자, 사용자 본인) | **첫 번째 계정** |
  | Issuer(발급자) | **두 번째 계정** |
  | 다른 사용자 / 공격자 | **세 번째 계정** |

### 0-4. 파일 만들기
1. **Files** 패널에서 새 파일을 만들고 이름을 `01_BadPrivacyStorage.sol` 처럼 짓습니다.
2. 이 저장소 `contracts/` 폴더의 같은 이름 파일 내용을 **그대로 복사해 붙여넣습니다.**
3. 4개 파일(01~04)을 한 번에 만들어도 되고, Lab을 진행하며 하나씩 만들어도 됩니다.

### 0-5. 안전 규칙
- **실제 이름·전화번호·이메일·생년월일·주민번호를 넣지 않습니다.** (예시 값만 사용)
- 실제 지갑·실제 자산 계정을 쓰지 않습니다. **Remix VM에서만** 실행합니다.
- 모든 코드는 **교육용**입니다. 상용 배포 전에는 EIP-712 서명, OpenZeppelin ECDSA, 자격 상태/폐기(revocation), 지갑 UX, 보안 감사, 법률 검토가 필요합니다.

---

## 입력 형식 빠른 안내 (제일 많이 헷갈리는 부분)

| 형식 | 어떻게 넣나 | 예시 |
|---|---|---|
| **문자열(string)** | 큰따옴표로 감쌈 | `"Alice"`, `"ageOver19"` |
| **숫자(uint256)** | 따옴표 없이 숫자만 | `20000101`, `4102444800` |
| **불린(bool)** | 따옴표 없이 | `true` / `false` |
| **주소(address)** | `0x`+40자리 hex. 계정 주소는 ACCOUNT 옆 **복사 아이콘**으로 복사해 붙여넣기 | `0x5B3...eddC4` |
| **bytes32** | `0x`+**64자리** hex. **직접 글자를 넣지 말고 `hashText("...")` 결과를 복사해서 붙여넣습니다.** | `0x8f2c...a91c` |
| **배열(uint256[])** | **대괄호**로 감쌈 | `[1]`, `[1,2,3]` |
| **bytes** | `0x`+짝수 개 hex. 빈 값은 `0x` | `0x1234`, `0x` |

> **핵심 습관 1 — hashText 결과 붙여넣기:** `bytes32` 칸에는 `"ageOver19"` 같은 글자를 **직접 넣으면 안 됩니다.**
> 먼저 `hashText("ageOver19")` 를 실행 → 반환된 `0x....`(64 hex) 값을 **복사** → 다음 함수의 bytes32 칸에 **붙여넣기** 합니다.
>
> **핵심 습관 2 — 여러 칸 입력:** 함수 옆 화살표(▸)를 눌러 입력칸을 펼치면 인자별로 따로 넣을 수 있어 실수가 줄어듭니다.
>
> **핵심 습관 3 — 결과 확인:** 파란 버튼(읽기 전용, `view`/`pure`)은 **값을 바로 반환**하고, 주황 버튼(상태 변경, 트랜잭션)은 **하단 터미널에 로그**를 남깁니다.

---

## Lab 1 — BadPrivacyStorage: `private`는 개인정보보호가 아니다

**목표:** 개인정보를 그대로 저장하는 "나쁜 설계"를 실행해, `private`이어도 `event log`에 값이 다 보인다는 것을 눈으로 확인합니다.

### 실행
1. `BadPrivacyStorage` 배포(Deploy). — *왜? 함수를 실행하려면 먼저 체인에 컨트랙트를 올려야 합니다.*
2. 배포된 인스턴스를 펼치고 **`saveProfile`** 입력칸에 아래를 넣고 실행합니다.
   ```text
   "Alice","alice@example.test",20000101,true
   ```
   - 형식: `name(string), email(string), birthDateYYYYMMDD(uint256), kycPassed(bool)`
   - *왜 이 순서? 함수 선언의 인자 순서와 같아야 합니다.*
3. 하단 **터미널에서 방금 트랜잭션을 클릭해 펼치고**, `logs`(또는 decoded output)에서 **`ProfileSaved`** 이벤트를 봅니다.

### 기대 결과
- `ProfileSaved` 이벤트 안에 입력값이 그대로 보입니다.
  ```text
  email = alice@example.test
  birthDateYYYYMMDD = 20000101
  kycPassed = true
  ```
- `profiles` 매핑은 `private`인데도 **event log에는 원본이 공개**됩니다. ← 이게 이 Lab의 핵심.

### 수업 포인트 / 질문
- `private`은 Solidity의 **접근 제한**이지 암호화·비공개가 아닙니다. event log와 calldata는 **공개 분석 표면**입니다.
- 생각해보기: *mapping이 private인데 왜 event에 값이 보일까? 이메일·생년월일이 체인에 남으면 무슨 문제가 생길까?*

---

## Lab 2 — CommitmentClaimVerifier: 원본 대신 commitment만 남기기

**목표:** 원본 claim을 올리지 않고 **commitment(봉인값)** 만 등록한 뒤, 나중에 값을 공개해 **일치성**을 검증합니다. claimValue나 salt가 틀리면 검증이 실패하는 것을 봅니다.

### 준비: hashText로 bytes32 값 만들기
`hashText`(파란 버튼)로 아래 문자열들을 각각 bytes32로 바꾸고 **결과를 메모(복사)** 해 둡니다.

| 쓸 이름 | hashText 입력 |
|---|---|
| `claimType` | `"ageOver19"` |
| `claimValueTrue` | `"true"` |
| `claimValueFalse` | `"false"` |
| `salt` | `"class-salt-team-1"` |
| `wrongSalt` | `"class-salt-team-2"` |

> *왜 salt를 쓰나?* `true/false`·나이처럼 후보가 적은 값은 단순 해시를 대입해 역추적할 수 있습니다. salt(무작위 값)를 섞으면 같은 claim이라도 commitment가 달라져 추측이 어려워집니다.

### 1) commitment 만들기 — `makeCommitment`
입력(모두 bytes32는 hashText 결과를 붙여넣기):
```text
holder     = 첫 번째 계정 주소          (ACCOUNT 옆 복사 아이콘으로 복사)
claimType  = hashText("ageOver19") 결과
claimValue = hashText("true") 결과
salt       = hashText("class-salt-team-1") 결과
```
→ 반환된 **commitment(bytes32)** 를 복사합니다. *왜 holder를 넣나? 다른 사람이 같은 값을 가져다 쓰는 것을 줄이기 위해서입니다.*

### 2) commitment 등록 — `registerCommitment`
- 첫 번째 계정으로 `registerCommitment(commitment)` 실행(위에서 복사한 값 붙여넣기).
- *왜? 이 순간 체인에는 원본이 아니라 commitment만 저장됩니다.* 터미널에서 `CommitmentRegistered` 이벤트를 확인하세요.

### 3) 성공 검증 — `verifyClaim`
- `makeCommitment`에 넣었던 `holder, claimType, claimValue, salt`와 **똑같이** 넣고 실행.
- **기대 결과: `true`** (공개한 값으로 다시 계산한 commitment가 등록값과 같음)

### 4) 실패 실험
| 실험 | 바꾸는 값 | 기대 결과 | 원인 |
|---|---|---|---|
| claimValue 변경 | `claimValue = hashText("false")` 결과 | `false` | 다시 계산한 commitment가 등록값과 다름 |
| salt 변경 | `salt = hashText("class-salt-team-2")` 결과 | `false` | salt가 달라지면 commitment도 달라짐 |

### 수업 포인트
- 온체인에는 원본 claim이 아니라 **commitment만** 저장됩니다.
- 단, commitment는 **"값을 공개한 뒤 일치성 검증"** 이지, **원본 없이 조건만 증명하는 ZKP는 아닙니다.** 값을 여는 순간 verifier는 claimValue를 알게 됩니다. 원본 없이 조건만 증명하려면 **ZKP**(Lab 4 맥락)를 고려합니다.

---

## Lab 3 — IssuerNullifierClassDemo: 발급자 승인 + 바인딩 + 만료 + 일회성 + 맥락

**목표:** 안전한 claim 사용에 필요한 5요소 — **발급자 승인, holder 바인딩, 만료(expiration), nullifier(일회용 표식), context(맥락)** — 를 한 번에 봅니다.

> **방식 안내(중요):** 실서비스에서는 발급자가 digest에 **ECDSA/EIP-712로 서명**합니다. 이 실습은 오프체인 서명 생성 때문에 수업이 막히지 않도록, 발급자 계정이 digest를 **`approveDigest`로 승인**하는 방식으로 **시뮬레이션**합니다. (동작의 본질은 "발급자가 무엇을 승인해야 안전한가"로 동일합니다.)

### 배포
1. 두 번째 계정(Issuer) 주소를 **복사**합니다.
2. CONTRACT 드롭다운에서 `IssuerNullifierClassDemo` 선택 → constructor 인자 **`issuer`** 에 두 번째 계정 주소를 넣고 **Deploy**.
3. `trustedIssuer()`(파란 버튼)를 눌러 두 번째 계정 주소가 나오는지 확인. *왜? 이 컨트랙트가 신뢰하는 발급자를 고정했는지 확인하는 것입니다.*

### 값 만들기 (hashText)
```text
claimType     = hashText("ageOver19")
claimValue    = hashText("true")
holderSecret  = hashText("student-1-secret")
context       = hashText("age-check-service-2026-06")
otherContext  = hashText("dao-vote-proposal-7")
```
- **nullifierHash**: `makeNullifierHash(holderSecret, context)` 실행 → 반환값을 메모. *왜? 사용자를 직접 드러내지 않으면서 "이 맥락에서 한 번 썼다"는 표식을 만들기 위해서입니다.*

### digest 만들기 — `claimDigest`
```text
holder        = 첫 번째 계정 주소
claimType     = hashText("ageOver19") 결과
claimValue    = hashText("true") 결과
expiration    = 4102444800            (먼 미래 = 만료 안 됨)
nullifierHash = makeNullifierHash(...) 결과
context       = hashText("age-check-service-2026-06") 결과
```
→ 반환된 **digest** 를 복사. *왜 이렇게 많이 묶나? contract·chain·holder·claim·만료·nullifier·context를 함께 서명해 재사용(replay)·도용을 막습니다.*

### issuer 승인 — `approveDigest`
1. **ACCOUNT를 두 번째 계정(Issuer)로 변경** ← 안 바꾸면 실패합니다.
2. `approveDigest(digest)` 실행 → `approvedDigests(digest)` 가 `true`인지 확인.

### holder 사용 — `verifyAndUse`
1. **ACCOUNT를 첫 번째 계정(Holder)로 변경.**
2. 아래 값으로 `verifyAndUse` 실행:
   ```text
   claimType     = hashText("ageOver19") 결과
   claimValue    = hashText("true") 결과
   expiration    = 4102444800
   nullifierHash = makeNullifierHash(...) 결과
   context       = hashText("age-check-service-2026-06") 결과
   ```
3. **기대 결과:** 트랜잭션 성공 + `ClaimAccepted` 이벤트, `usedNullifiers(nullifierHash) = true`.

### 실패 실험
| 실험 | 방법 | 오류 메시지 | 원인 |
|---|---|---|---|
| 같은 nullifier 재사용 | 첫 번째 계정에서 같은 값으로 다시 실행 | `nullifier already used` | 같은 일회용 표식을 두 번 쓸 수 없음 |
| 다른 holder가 사용 | 세 번째 계정으로 같은 값 실행 | `untrusted issuer or wrong context` | digest 안에 holder가 들어 있어 `msg.sender`가 바뀌면 digest도 바뀜 |
| 만료된 claim | 새 nullifier로 `expiration = 1` 넣고 실행 | `expired` | 현재 시간이 만료 시간을 지남 |

> 실패 실험 전에는 보통 **nullifier(또는 context)를 새로 만들거나 새로 배포**해야 합니다. 안 그러면 이전 "사용됨" 상태 때문에 다른 이유로 막힐 수 있습니다.

### 수업 포인트
서명 대상은 claim 하나가 아니라 **사용 맥락 전체**입니다. holder·expiration·nullifier·context·contract·chainId를 함께 묶어야 도용·재사용·서비스 간 연결을 줄일 수 있습니다.

---

## Lab 4 — ZKVerifierSlot: ZK verifier가 "들어갈 자리"

**목표:** proof를 만드는 실습이 아니라, **ZK verifier가 서비스 로직의 어디에 들어가는지**와 **public signal 설계의 중요성**을 봅니다.

### 배포 (순서 중요)
1. `MockZKVerifier` 배포 → **배포 주소를 복사.** *왜? 서비스 컨트랙트가 이 verifier를 가리켜야 합니다.*
2. `ZKSlotExample` 선택 → constructor 인자 **`verifierAddress`** 에 방금 복사한 `MockZKVerifier` 주소를 넣고 **Deploy.**

### 성공 실행 — `submitProof`
```text
proof         = 0x1234
publicSignals = [1]
nullifierHash = 0x1111111111111111111111111111111111111111111111111111111111111111
```
- 형식: `proof(bytes)`, `publicSignals(uint256[] → 대괄호 [1])`, `nullifierHash(bytes32 → 0x + 64 hex)`
- **기대 결과:** 트랜잭션 성공 + `ProofAccepted` 이벤트.
- *왜 통과하나? MockZKVerifier는 "proof가 비어있지 않고 publicSignals가 1개 이상이면 통과"라는 가짜 규칙만 봅니다.*

### 실패 실험
| 실험 | 입력 | 오류 메시지 | 원인 |
|---|---|---|---|
| 같은 nullifier 재사용 | 성공 입력을 그대로 다시 실행 | `nullifier already used` | 같은 action을 두 번 쓸 수 없음 |
| 빈 proof | `proof = 0x`, `publicSignals = [1]`, `nullifierHash = 0x2222...2222` | `invalid proof` | proof가 비어 있어 verifier가 false 반환 |

### 수업 포인트
- proof가 유효해도 **nullifier(중복 방지)는 별개 문제**입니다.
- ZKP를 써도 **public signal에 생년월일·고유 ID 같은 값이 들어가면 설계가 실패**합니다. 무엇을 public signal로 둘지가 핵심입니다.

---

## 자주 막히는 곳 (FAQ)

- **Q. bytes32 칸에 `ageOver19`를 넣었더니 빨간 에러가 나요.**
  A. bytes32에는 글자를 직접 넣지 않습니다. `hashText("ageOver19")`를 먼저 실행하고 그 **`0x...` 결과를 붙여넣으세요.**
- **Q. `verifyClaim`이 계속 `false`예요.**
  A. `makeCommitment`에 쓴 **holder·claimType·claimValue·salt와 똑같은 값**인지 확인하세요. 하나라도 다르면 false입니다. (특히 salt, holder 주소)
- **Q. `approveDigest`가 `only trusted issuer`로 실패해요.**
  A. ACCOUNT가 **두 번째 계정(Issuer)** 인지 확인하세요. 배포 때 issuer로 넣은 그 계정이어야 합니다.
- **Q. `verifyAndUse`가 `untrusted issuer or wrong context`로 실패해요.**
  A. (1) 승인(`approveDigest`)에 쓴 digest와 **완전히 같은 값**으로 호출했는지, (2) 지금 계정이 **digest의 holder 계정(첫 번째 계정)** 인지 확인하세요. context를 바꾸면 digest가 달라집니다.
- **Q. 배열은 어떻게 넣나요?**
  A. 대괄호로 감쌉니다. 예: `publicSignals = [1]`. 여러 개면 `[1,2]`.
- **Q. event(로그)가 안 보여요.**
  A. 하단 **터미널에서 방금 트랜잭션 줄을 클릭**해 펼치고 `logs`(decoded) 영역을 확인하세요. 파란 버튼(view/pure)은 로그가 아니라 반환값만 바로 보여줍니다.
- **Q. 컴파일이 안 돼요 / 경고가 떠요.**
  A. **COMPILER 버전을 0.8.26**으로 맞췄는지 확인하세요.
- **Q. 상태를 처음부터 다시 하고 싶어요.**
  A. Deploy 패널의 Environment를 다시 선택하거나 컨트랙트를 새로 배포하면 깨끗한 상태로 시작합니다.

## 오류 메시지 사전
| 메시지 | 뜻 | 보통 원인 |
|---|---|---|
| `only trusted issuer` | 발급자만 호출 가능 | 계정이 Issuer(두 번째)가 아님 |
| `expired` | 만료됨 | `expiration`이 현재 시간보다 과거(예: 1) |
| `untrusted issuer or wrong context` | 승인 안 된 digest | 값/계정/context가 승인 때와 다름 |
| `nullifier already used` | 일회용 표식 재사용 | 같은 nullifierHash를 두 번 사용 |
| `invalid proof` | proof 무효 | `proof = 0x`(빈 값) 또는 publicSignals 비어 있음 |

## 약어 풀이
- **DPP** — Digital Product Passport, 디지털 제품 여권(제품 이력을 검증 가능하게 남기는 설계).
- **DID** — Decentralized Identifier, 분산 식별자.
- **VC / VP** — Verifiable Credential / Verifiable Presentation, 검증 가능한 자격증명 / 제시.
- **ZKP / ZK** — Zero-Knowledge Proof, 영지식 증명(원본 없이 조건 충족만 증명).
- **KYC** — Know Your Customer, 고객 신원확인.
- **commitment** — 커밋먼트(원본을 봉인한 해시값). 나중에 값을 공개해 일치성 검증.
- **nullifier** — 일회용 무효화 표식. 같은 action의 중복 사용을 막음.
- **salt** — 솔트(소금). 추측 방지용 무작위 값.
- **hash / keccak256** — 해시(원본을 지문처럼 바꾼 고정 길이 값).
- **calldata** — 트랜잭션 호출 입력 데이터(공개됨).
- **event log** — 검색·색인에 최적화된 공개 로그.
- **Remix VM** — 브라우저 안의 연습용 가상 블록체인.
- **EIP-712** — 구조화된 데이터 서명 표준(실서비스 발급자 서명에 사용).
