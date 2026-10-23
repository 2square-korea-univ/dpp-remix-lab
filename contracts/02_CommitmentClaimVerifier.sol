// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Lab 2. 원본 claim 대신 commitment만 저장하는 예제입니다.
//
// 수업 목표:
// - 온체인에 원본 개인정보를 직접 저장하지 않고 commitment만 남기는 흐름을 이해합니다.
// - 나중에 claimValue와 salt를 공개했을 때 commitment가 맞는지 검증합니다.
// - commitment는 "일치성 검증"이지, 원본 없는 조건 증명인 ZKP는 아니라는 한계를 봅니다.
contract CommitmentClaimVerifier {
    // holder 주소별로 commitment 하나를 저장합니다.
    // commitment는 H(holder, claimType, claimValue, salt)로 만든 bytes32 값입니다.
    // 여기에는 원본 문자열 "ageOver19"나 "true"가 직접 저장되지 않습니다.
    mapping(address => bytes32) public commitments;

    // event에는 commitment만 남깁니다.
    // Lab 1처럼 원본 email, birthDate를 남기지 않는 것이 핵심 차이입니다.
    event CommitmentRegistered(address indexed holder, bytes32 commitment);

    // Remix 실습 편의를 위한 helper 함수입니다.
    // 문자열을 bytes32 hash로 바꿔서 claimType, claimValue, salt로 사용할 수 있게 합니다.
    // 예: hashText("ageOver19"), hashText("true"), hashText("class-salt-team-1")
    function hashText(string memory text) public pure returns (bytes32) {
        return keccak256(bytes(text));
    }

    // commitment 공식:
    // commitment = H(holder || claimType || claimValue || salt)
    //
    // holder를 넣는 이유:
    // - 다른 사용자가 같은 claimValue와 salt를 가져다 쓰는 것을 줄입니다.
    //
    // salt를 넣는 이유:
    // - true/false, 나이, 국가처럼 후보군이 좁은 값은 단순 hash만으로 추측될 수 있습니다.
    // - salt는 같은 claim이라도 commitment가 달라지게 만들어 사전대입 공격을 어렵게 합니다.
    function makeCommitment(
        address holder,
        bytes32 claimType,
        bytes32 claimValue,
        bytes32 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(holder, claimType, claimValue, salt));
    }

    // holder가 자신의 commitment를 온체인에 등록합니다.
    // 이 시점에는 claimValue나 salt를 공개하지 않고 commitment만 저장합니다.
    function registerCommitment(bytes32 commitment) external {
        commitments[msg.sender] = commitment;
        emit CommitmentRegistered(msg.sender, commitment);
    }

    // holder가 나중에 claimType, claimValue, salt를 공개하면,
    // 컨트랙트가 같은 방식으로 commitment를 다시 계산해서 저장값과 비교합니다.
    //
    // 성공 예:
    // - 등록할 때 쓴 claimValue = hashText("true")
    // - 검증할 때도 같은 claimValue와 같은 salt 사용
    //
    // 실패 예:
    // - claimValue를 hashText("false")로 바꿈
    // - salt를 다른 값으로 바꿈
    function verifyClaim(
        address holder,
        bytes32 claimType,
        bytes32 claimValue,
        bytes32 salt
    ) external view returns (bool) {
        // 공개된 값으로 commitment를 다시 계산합니다.
        bytes32 expected = makeCommitment(
            holder,
            claimType,
            claimValue,
            salt
        );

        // 등록된 commitment와 다시 계산한 commitment가 같으면 true입니다.
        // 다르면 holder가 공개한 claim/salt 조합이 원래 등록값과 맞지 않는다는 뜻입니다.
        return commitments[holder] == expected;
    }

    // Remix에서 눌러볼 수 있는 수업 핵심 문장입니다.
    function lessonPoint() external pure returns (string memory) {
        return "A commitment checks consistency after disclosure; it is not a full zero-knowledge proof.";
    }
}
