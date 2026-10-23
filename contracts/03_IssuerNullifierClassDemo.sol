// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Lab 3. issuer approval, holder binding, expiration, nullifier, context를 한 번에 보는 예제입니다.
//
// 실서비스에서는 issuer가 ECDSA/EIP-712 방식으로 digest에 서명합니다.
// 이 수업용 컨트랙트에서는 오프체인 서명 생성 때문에 수업이 막히지 않도록
// `approveDigest`로 issuer signature를 단순화해 시뮬레이션합니다.
//
// 핵심은 "어떤 값을 issuer가 승인해야 안전한가?"입니다.
contract IssuerNullifierClassDemo {
    // 신뢰하는 발급자 주소입니다.
    // Remix에서는 두 번째 계정을 issuer로 넣어 배포합니다.
    address public trustedIssuer;

    // issuer가 승인한 digest 목록입니다.
    // 실서비스라면 이 mapping 대신 서명 검증 결과를 사용합니다.
    mapping(bytes32 => bool) public approvedDigests;

    // 이미 사용된 nullifierHash 목록입니다.
    // 같은 증명 또는 같은 action을 두 번 쓰지 못하게 막습니다.
    mapping(bytes32 => bool) public usedNullifiers;

    // issuer가 digest를 승인했음을 보여주는 수업용 event입니다.
    event DigestApproved(bytes32 indexed digest);

    // holder가 claim을 성공적으로 사용했음을 보여주는 event입니다.
    // nullifierHash를 남겨 중복 사용 방지 흐름을 관찰하게 합니다.
    event ClaimAccepted(
        address indexed holder,
        bytes32 indexed claimType,
        bytes32 indexed nullifierHash
    );

    // 배포 시 trusted issuer 주소를 정합니다.
    // 수업에서는 Remix 두 번째 계정 주소를 넣습니다.
    constructor(address issuer) {
        trustedIssuer = issuer;
    }

    // issuer만 특정 함수를 실행할 수 있게 제한합니다.
    // `approveDigest`는 issuer가 claim digest를 승인하는 단계이므로 holder가 실행하면 안 됩니다.
    modifier onlyIssuer() {
        require(msg.sender == trustedIssuer, "only trusted issuer");
        _;
    }

    // Remix 실습 편의를 위한 helper 함수입니다.
    // claimType, claimValue, holderSecret, context를 bytes32로 만들 때 사용합니다.
    function hashText(string memory text) public pure returns (bytes32) {
        return keccak256(bytes(text));
    }

    // nullifierHash 공식:
    // nullifierHash = H(holderSecret || context)
    //
    // holderSecret:
    // - 사용자를 직접 드러내지 않기 위한 비밀값이라고 생각합니다.
    //
    // context:
    // - 어떤 서비스, 어떤 안건, 어떤 action에 대한 nullifier인지 구분합니다.
    // - 같은 nullifier를 여러 서비스에서 재사용하면 사용자를 연결할 수 있으므로 위험합니다.
    function makeNullifierHash(
        bytes32 holderSecret,
        bytes32 context
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(holderSecret, context));
    }

    // issuer가 승인해야 하는 digest를 만듭니다.
    //
    // digest에 여러 필드를 함께 넣는 이유:
    // - address(this): 다른 verifier contract에서 재사용되는 replay 위험 감소
    // - block.chainid: 다른 chain에서 재사용되는 replay 위험 감소
    // - holder: 다른 사용자가 claim을 가져다 쓰는 위험 감소
    // - claimType/claimValue: 어떤 claim인지 명확히 함
    // - expiration: 오래된 claim 재사용 방지
    // - nullifierHash: 같은 action의 중복 사용 방지
    // - context: 서비스별, 안건별, action별 연결성 분리
    function claimDigest(
        address holder,
        bytes32 claimType,
        bytes32 claimValue,
        uint256 expiration,
        bytes32 nullifierHash,
        bytes32 context
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                address(this),
                block.chainid,
                holder,
                claimType,
                claimValue,
                expiration,
                nullifierHash,
                context
            )
        );
    }

    // issuer가 특정 digest를 승인합니다.
    //
    // 수업용 단순화:
    // - 실서비스: issuer가 digest에 서명하고 verifier가 서명을 검증
    // - 이 예제: issuer 계정이 digest를 mapping에 true로 저장
    //
    // 반드시 Remix Account를 두 번째 계정, 즉 trustedIssuer로 바꾼 뒤 실행해야 합니다.
    function approveDigest(bytes32 digest) external onlyIssuer {
        approvedDigests[digest] = true;
        emit DigestApproved(digest);
    }

    // holder가 claim을 제출하고 사용하는 함수입니다.
    //
    // 실행 순서:
    // 1. expiration이 지나지 않았는지 확인
    // 2. msg.sender, 즉 실제 제출자를 holder로 넣고 digest를 다시 계산
    // 3. issuer가 승인한 digest인지 확인
    // 4. nullifierHash가 이미 사용됐는지 확인
    // 5. nullifierHash를 사용 처리하고 event를 발생
    function verifyAndUse(
        bytes32 claimType,
        bytes32 claimValue,
        uint256 expiration,
        bytes32 nullifierHash,
        bytes32 context
    ) external returns (bool) {
        // 만료 시간이 지난 claim은 사용할 수 없습니다.
        // 수업에서 expiration = 1을 넣으면 이 require가 실패합니다.
        require(block.timestamp <= expiration, "expired");

        // holder 인자로 외부 입력을 받지 않고 msg.sender를 사용합니다.
        // 그래야 승인받은 holder가 아닌 다른 계정이 claim을 가져다 쓰기 어렵습니다.
        bytes32 digest = claimDigest(
            msg.sender,
            claimType,
            claimValue,
            expiration,
            nullifierHash,
            context
        );

        // issuer가 승인한 digest가 아니면 실패합니다.
        // 계정이 바뀌거나 context가 바뀌면 digest도 바뀌므로 여기서 실패합니다.
        require(approvedDigests[digest], "untrusted issuer or wrong context");

        // 같은 nullifierHash는 한 번만 사용할 수 있습니다.
        // 수업에서 같은 값으로 두 번 실행하면 이 require가 실패합니다.
        require(!usedNullifiers[nullifierHash], "nullifier already used");

        // nullifierHash를 사용 처리합니다.
        // 이 줄 이후 같은 nullifierHash로 다시 제출하면 중복 사용으로 막힙니다.
        usedNullifiers[nullifierHash] = true;

        emit ClaimAccepted(msg.sender, claimType, nullifierHash);
        return true;
    }

    // Remix에서 눌러볼 수 있는 수업 핵심 문장입니다.
    function lessonPoint() external pure returns (string memory) {
        return "Bind issuer approval to contract, chain, holder, expiration, nullifier, and context.";
    }
}
