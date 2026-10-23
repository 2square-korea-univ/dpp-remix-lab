# DPP Remix 실습 실행순서

이 문서는 강사가 수업 중 그대로 따라가며 실행할 수 있는 순서표다.

## 0. Remix 기본 세팅

수업 전에 강사는 로컬에서 한 번 컴파일을 확인한다.

```bash
cd dpp-remix-lab
forge build
```

또는:

```bash
cd dpp-remix-lab
npm run build
```

그 다음 Remix에서 아래 순서로 진행한다.

1. `https://remix.ethereum.org` 접속
2. `contracts/01_BadPrivacyStorage.sol`부터 파일을 하나씩 만든다.
3. Solidity Compiler는 `0.8.26` (덱과 동일 버전) 선택
4. `Deploy & Run Transactions`에서 Environment를 `Remix VM`으로 선택
5. Account 역할을 정한다.

```text
첫 번째 계정 = Holder
두 번째 계정 = Issuer
세 번째 계정 = 다른 사용자 또는 공격자
```

강사 멘트:

> 오늘은 실제 개인정보와 실제 자산 계정을 쓰지 않습니다. Remix VM에서만 실행합니다.

## 1. Lab 1: BadPrivacyStorage

파일:

```text
contracts/01_BadPrivacyStorage.sol
```

배포할 컨트랙트:

```text
BadPrivacyStorage
```

### 실행

1. 첫 번째 계정 선택
2. `BadPrivacyStorage` 배포
3. `saveProfile` 실행

입력:

```text
"Alice","alice@example.test",20000101,true
```

### 관찰

Remix 하단 transaction log를 펼쳐서 `ProfileSaved` event를 본다.

확인할 것:

```text
email = alice@example.test
birthDateYYYYMMDD = 20000101
kycPassed = true
```

### 수업 포인트

말할 것:

```text
private은 Solidity 접근 제한이지 개인정보보호가 아닙니다.
event log와 calldata는 분석 표면입니다.
사용자 주소와 개인정보가 연결되면 장기 추적 위험이 생깁니다.
```

질문:

```text
profiles mapping이 private인데 왜 event log에 값이 보이나요?
이메일과 생년월일이 체인에 남으면 어떤 문제가 생기나요?
```

## 2. Lab 2: CommitmentClaimVerifier

파일:

```text
contracts/02_CommitmentClaimVerifier.sol
```

배포할 컨트랙트:

```text
CommitmentClaimVerifier
```

### 실행 준비

1. 첫 번째 계정 선택
2. `CommitmentClaimVerifier` 배포
3. `hashText`로 아래 값을 만든다.

```text
claimType = hashText("ageOver19")
claimValueTrue = hashText("true")
claimValueFalse = hashText("false")
salt = hashText("class-salt-team-1")
wrongSalt = hashText("class-salt-team-2")
```

### commitment 만들기

`makeCommitment` 실행:

```text
holder = 첫 번째 계정 주소
claimType = hashText("ageOver19") 결과
claimValue = hashText("true") 결과
salt = hashText("class-salt-team-1") 결과
```

반환된 commitment를 복사한다.

### commitment 등록

첫 번째 계정으로 `registerCommitment(commitment)` 실행

### 성공 검증

`verifyClaim`을 실행한다. 입력값은 위 `makeCommitment`에 사용한 `holder`, `claimType`, `claimValue`, `salt`와 동일하다.

예상 결과:

```text
true
```

### 실패 검증 1: claimValue 변경

`verifyClaim` 실행:

```text
holder = 첫 번째 계정 주소
claimType = hashText("ageOver19") 결과
claimValue = hashText("false") 결과
salt = hashText("class-salt-team-1") 결과
```

예상 결과:

```text
false
```

### 실패 검증 2: salt 변경

`verifyClaim` 실행:

```text
holder = 첫 번째 계정 주소
claimType = hashText("ageOver19") 결과
claimValue = hashText("true") 결과
salt = hashText("class-salt-team-2") 결과
```

예상 결과:

```text
false
```

### 수업 포인트

말할 것:

```text
온체인에는 원본 claim이 아니라 commitment만 저장됩니다.
commitment는 원본 없는 조건 증명이 아니라, 나중에 공개한 값의 일치성 검증입니다.
claim을 여는 순간 verifier는 claimValue를 알게 됩니다.
원본 없이 조건만 증명해야 하면 ZKP를 고려합니다.
```

질문:

```text
commitment만 보고 ageOver19가 true인지 바로 알 수 있나요?
생년월일을 열지 않고 성인 여부만 증명하려면 무엇이 더 필요할까요?
```

## 3. Lab 3: IssuerNullifierClassDemo

파일:

```text
contracts/03_IssuerNullifierClassDemo.sol
```

배포할 컨트랙트:

```text
IssuerNullifierClassDemo
```

이 실습은 실서비스의 issuer signature를 `approveDigest`로 시뮬레이션한다.

```text
실서비스 = issuer가 digest에 서명
수업 실습 = issuer 계정이 digest를 approve
```

### 배포

1. 두 번째 계정 주소를 복사한다.
2. Contract 드롭다운에서 `IssuerNullifierClassDemo` 선택
3. constructor 인자 `issuer`에 두 번째 계정 주소 입력
4. 배포
5. `trustedIssuer()`를 눌러 두 번째 계정 주소가 나오는지 확인

### claim 값 만들기

`hashText` 실행:

```text
claimType = hashText("ageOver19")
claimValue = hashText("true")
holderSecret = hashText("student-1-secret")
context = hashText("age-check-service-2026-06")
otherContext = hashText("dao-vote-proposal-7")
```

### nullifier 만들기

`makeNullifierHash(holderSecret, context)` 실행

반환값을 `nullifierHash`로 사용한다.

### digest 만들기

`claimDigest` 실행:

```text
holder = 첫 번째 계정 주소
claimType = hashText("ageOver19") 결과
claimValue = hashText("true") 결과
expiration = 4102444800
nullifierHash = makeNullifierHash(...) 결과
context = hashText("age-check-service-2026-06") 결과
```

반환된 digest를 복사한다.

### issuer approve

1. Account를 두 번째 계정으로 변경
2. `approveDigest(digest)` 실행
3. `approvedDigests(digest)`가 `true`인지 확인

### holder 검증 사용

1. Account를 첫 번째 계정으로 변경
2. `verifyAndUse` 실행

```text
claimType = hashText("ageOver19") 결과
claimValue = hashText("true") 결과
expiration = 4102444800
nullifierHash = makeNullifierHash(...) 결과
context = hashText("age-check-service-2026-06") 결과
```

예상 결과:

```text
transaction success
usedNullifiers(nullifierHash) = true
```

### 실패 검증 1: 같은 nullifier 재사용

첫 번째 계정에서 같은 값으로 `verifyAndUse`를 다시 실행한다.

예상 실패:

```text
nullifier already used
```

### 실패 검증 2: 다른 holder가 사용

1. Account를 세 번째 계정으로 변경
2. 같은 값으로 `verifyAndUse` 실행

예상 실패:

```text
untrusted issuer or wrong context
```

이유:

```text
digest 안에 holder가 들어 있으므로 msg.sender가 바뀌면 digest도 바뀐다.
```

### 실패 검증 3: 만료된 claim

새 nullifier를 만들거나 새로 배포한 뒤, `expiration = 1`로 `verifyAndUse` 실행

예상 실패:

```text
expired
```

### 수업 포인트

말할 것:

```text
서명 대상은 claim 하나가 아니라 사용 맥락 전체입니다.
contract address와 chainId를 넣어 replay 위험을 줄입니다.
holder를 넣어 다른 사용자가 가져다 쓰지 못하게 합니다.
expiration을 넣어 오래된 claim 재사용을 막습니다.
nullifier를 넣어 같은 action의 중복 사용을 막습니다.
context를 분리해 서비스 간 연결 가능성을 줄입니다.
```

질문:

```text
같은 nullifier를 여러 서비스에서 쓰면 어떤 문제가 생기나요?
claimValue만 서명하면 어떤 replay 위험이 생길까요?
```

## 4. Lab 4: ZKVerifierSlot

파일:

```text
contracts/04_ZKVerifierSlot.sol
```

배포할 컨트랙트:

```text
MockZKVerifier
ZKSlotExample
```

### Mock verifier 배포

1. `MockZKVerifier` 배포
2. 배포 주소 복사

### ZK slot 컨트랙트 배포

1. `ZKSlotExample` 선택
2. constructor 인자 `verifierAddress`에 `MockZKVerifier` 주소 입력
3. 배포

### 성공 실행

`submitProof` 실행:

```text
proof = 0x1234
publicSignals = [1]
nullifierHash = 0x1111111111111111111111111111111111111111111111111111111111111111
```

예상 결과:

```text
transaction success
ProofAccepted event
```

### 실패 검증 1: 같은 nullifier 재사용

같은 값으로 `submitProof` 다시 실행

예상 실패:

```text
nullifier already used
```

### 실패 검증 2: 빈 proof

`submitProof` 실행:

```text
proof = 0x
publicSignals = [1]
nullifierHash = 0x2222222222222222222222222222222222222222222222222222222222222222
```

예상 실패:

```text
invalid proof
```

### 수업 포인트

말할 것:

```text
오늘은 proof 생성이 아니라 verifier가 서비스 로직 어디에 들어가는지 보는 실습입니다.
ZKP를 써도 public signal에 개인정보가 들어가면 설계가 실패합니다.
proof 유효성과 nullifier 중복 방지는 서로 다른 문제입니다.
```

질문:

```text
public signal에 생년월일이나 고유 ID가 들어가면 괜찮을까요?
ZKP를 써도 nullifier가 필요한 상황은 언제일까요?
```

## 5. 마지막 연결 멘트

실습을 마친 뒤 아래처럼 정리한다.

```text
BadPrivacyStorage는 무엇을 하지 말아야 하는지 보여줍니다.
Commitment는 원본 대신 증거를 남기는 첫 단계입니다.
IssuerNullifierClassDemo는 발급자, 사용자, 만료, 1회성, context를 묶어야 함을 보여줍니다.
ZKVerifierSlot은 원본 없는 조건 증명이 들어갈 위치와 public signal의 위험을 보여줍니다.
```

마지막 문장:

```text
온체인은 개인정보 저장소가 아니라 검증 기준점입니다.
```
