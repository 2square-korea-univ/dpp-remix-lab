# DPP Remix 실습 테스트 값

수업 중 입력값이 흔들리면 시간이 많이 소모된다. 아래 값을 고정해서 진행한다.

## 공통 계정 역할

Remix VM 계정을 다음처럼 사용한다.

| 역할 | Remix 계정 |
|---|---|
| Holder | 첫 번째 계정 |
| Issuer | 두 번째 계정 |
| Attacker 또는 다른 사용자 | 세 번째 계정 |

## Lab 1 입력값

`BadPrivacyStorage.saveProfile`

```text
"Alice","alice@example.test",20000101,true
```

## Lab 2 입력값

`CommitmentClaimVerifier.hashText`로 각각 만든다.

| 이름 | 입력 문자열 |
|---|---|
| `claimType` | `ageOver19` |
| `claimValueTrue` | `true` |
| `claimValueFalse` | `false` |
| `salt` | `class-salt-team-1` |
| `wrongSalt` | `class-salt-team-2` |

## Lab 3 입력값

`IssuerNullifierClassDemo.hashText`로 각각 만든다.

| 이름 | 입력 문자열 |
|---|---|
| `claimType` | `ageOver19` |
| `claimValue` | `true` |
| `holderSecret` | `student-1-secret` |
| `context` | `age-check-service-2026-06` |
| `otherContext` | `dao-vote-proposal-7` |

`expiration`은 수업 중 만료되지 않도록 아래 값을 사용한다.

```text
4102444800
```

만료 실패를 보여줄 때는 아래 값을 사용한다.

```text
1
```

## Lab 4 입력값

`ZKSlotExample.submitProof`

성공 입력:

```text
proof: 0x1234
publicSignals: [1]
nullifierHash: 0x1111111111111111111111111111111111111111111111111111111111111111
```

같은 nullifier 재사용 실패:

```text
성공 입력과 같은 값을 그대로 한 번 더 실행한다.
```

빈 proof 실패:

```text
proof: 0x
publicSignals: [1]
nullifierHash: 0x2222222222222222222222222222222222222222222222222222222222222222
```
