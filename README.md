# DPP Remix 실습 패키지

이 폴더는 DPP 강의의 Remix 실습을 바로 진행할 수 있도록 구성한 수업용 패키지다.

> **처음이라면 [LAB_GUIDE.md](./LAB_GUIDE.md) 를 보고 그대로 따라 하세요.** (입력 형식·예시·기대 결과·오류 원인·FAQ·약어 풀이 포함)
> 강사용 순서표는 [RUN_ORDER.md](./RUN_ORDER.md), 고정 입력값은 [TEST_VALUES.md](./TEST_VALUES.md).

## 폴더 구성

```text
dpp-remix-lab/
  README.md
  LAB_GUIDE.md      # 수강생용 상세 가이드 (여기부터)
  RUN_ORDER.md      # 강사용 실행 순서표
  TEST_VALUES.md    # 고정 입력값
  contracts/
    01_BadPrivacyStorage.sol
    02_CommitmentClaimVerifier.sol
    03_IssuerNullifierClassDemo.sol
    04_ZKVerifierSlot.sol
```

## 수업 흐름

1. `01_BadPrivacyStorage.sol`
   - 개인정보를 직접 저장하는 나쁜 설계를 실행한다.
   - `private`이 개인정보보호가 아님을 event log로 확인한다.

2. `02_CommitmentClaimVerifier.sol`
   - 원본 claim 대신 commitment만 등록한다.
   - claimValue 또는 salt를 바꿨을 때 검증이 실패하는 것을 확인한다.

3. `03_IssuerNullifierClassDemo.sol`
   - issuer가 claim digest를 승인하는 교육용 signature 시뮬레이션을 실행한다.
   - holder binding, expiration, nullifier, context의 필요성을 확인한다.

4. `04_ZKVerifierSlot.sol`
   - ZK proof 생성이 아니라 verifier가 서비스 로직에 들어가는 위치를 확인한다.
   - proof가 유효해도 nullifier와 public signal 설계가 필요하다는 점을 설명한다.

## Remix 사용 방법

1. `https://remix.ethereum.org` 접속
2. 새 Workspace 또는 새 폴더 생성
3. `contracts/` 안의 `.sol` 파일을 하나씩 Remix에 생성해서 붙여넣기
4. Solidity Compiler에서 `0.8.26` (덱과 동일 버전) 선택
5. Environment는 반드시 `Remix VM` 선택
6. [RUN_ORDER.md](./RUN_ORDER.md)의 순서대로 실행

## 강사용 로컬 검증

Foundry가 설치된 환경에서는 수업 전에 아래 명령으로 Solidity 파일들이 컴파일되는지 확인할 수 있다.

```bash
cd dpp-remix-lab
forge build
```

`npm`을 쓰고 싶으면 같은 검증을 아래처럼 실행할 수 있다.

```bash
cd dpp-remix-lab
npm run build
```

컴파일 산출물은 `out/`와 `cache/`에 생성된다. 이 폴더들은 수업 자료가 아니라 로컬 검증 결과다.

## 강의 핵심 문장

```text
원본 개인정보는 오프체인에 두고,
온체인에는 검증 가능한 증거만 남긴다.
```

## 실습 안전 규칙

- 실제 이름, 전화번호, 이메일, 생년월일을 넣지 않는다.
- 메인넷 또는 실제 자산 계정을 사용하지 않는다.
- 모든 코드는 교육용이다.
- 상용 배포 전에는 EIP-712, OpenZeppelin ECDSA, credential status, revocation, wallet UX, 보안 감사, 법률 검토가 필요하다.
