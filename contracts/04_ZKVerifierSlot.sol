// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Lab 4. ZK proof 생성이 아니라 verifier가 들어갈 "자리"를 이해하는 예제입니다.
//
// 실제 ZKP 서비스에서는 별도의 circuit/prover가 proof를 만들고,
// 온체인 verifier contract가 proof와 publicSignals를 검증합니다.
// 이 파일은 그 구조가 서비스 컨트랙트 안에서 어떻게 연결되는지 보여줍니다.

// 실제 verifier가 가져야 할 최소 인터페이스입니다.
// proof와 publicSignals를 받아 bool 결과를 반환한다고 가정합니다.
interface IZKVerifier {
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata publicSignals
    ) external view returns (bool);
}

// 수업용 가짜 verifier입니다.
//
// 주의:
// - 이 컨트랙트는 진짜 ZKP 검증을 하지 않습니다.
// - proof가 비어 있지 않고 publicSignals가 1개 이상이면 true를 반환합니다.
// - 목적은 "ZK verifier가 서비스 로직 어디에 들어가는가"를 보여주는 것입니다.
contract MockZKVerifier is IZKVerifier {
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata publicSignals
    ) external pure returns (bool) {
        // proof = 0x 이면 false입니다.
        // publicSignals = [] 이면 false입니다.
        return proof.length > 0 && publicSignals.length > 0;
    }
}

// 서비스 컨트랙트가 ZK verifier를 사용하는 예제입니다.
//
// 흐름:
// 1. constructor에서 verifier contract 주소를 연결합니다.
// 2. 사용자가 proof, publicSignals, nullifierHash를 제출합니다.
// 3. nullifierHash가 이미 사용됐는지 먼저 확인합니다.
// 4. verifier.verifyProof(...)가 true인지 확인합니다.
// 5. 성공하면 nullifierHash를 사용 처리합니다.
contract ZKSlotExample {
    // 실제 proof 검증을 담당하는 외부 verifier contract입니다.
    IZKVerifier public verifier;

    // ZKP를 쓰더라도 같은 action을 두 번 쓰지 못하게 하려면 nullifier가 필요합니다.
    mapping(bytes32 => bool) public usedNullifiers;

    // proof가 받아들여졌음을 보여주는 event입니다.
    // publicSignals 전체를 event에 남기지 않고 개수만 남깁니다.
    // 실제 서비스에서는 event에 무엇을 남길지도 개인정보 관점에서 검토해야 합니다.
    event ProofAccepted(bytes32 indexed nullifierHash, uint256 signalCount);

    // verifierAddress에는 MockZKVerifier 또는 실제 ZK verifier 주소를 넣습니다.
    constructor(address verifierAddress) {
        verifier = IZKVerifier(verifierAddress);
    }

    // 사용자가 proof를 제출하는 함수입니다.
    //
    // 수업 성공 입력:
    // - proof = 0x1234
    // - publicSignals = [1]
    // - nullifierHash = 0x1111...1111
    //
    // 실패 입력:
    // - 같은 nullifierHash를 다시 사용하면 "nullifier already used"
    // - proof = 0x 를 넣으면 "invalid proof"
    function submitProof(
        bytes calldata proof,
        uint256[] calldata publicSignals,
        bytes32 nullifierHash
    ) external returns (bool) {
        // proof가 유효하더라도 같은 nullifier를 두 번 쓰면 안 됩니다.
        require(!usedNullifiers[nullifierHash], "nullifier already used");

        // verifier가 proof와 publicSignals를 검증합니다.
        // 이 예제에서는 MockZKVerifier라서 단순 조건만 보지만,
        // 실서비스에서는 circuit 조건을 만족하는 proof인지 확인합니다.
        require(verifier.verifyProof(proof, publicSignals), "invalid proof");

        // nullifier를 사용 처리합니다.
        // 같은 사용자가 같은 action을 다시 수행하는 것을 막는 핵심 상태입니다.
        usedNullifiers[nullifierHash] = true;
        emit ProofAccepted(nullifierHash, publicSignals.length);
        return true;
    }

    // Remix에서 눌러볼 수 있는 수업 핵심 문장입니다.
    function lessonPoint() external pure returns (string memory) {
        return "ZK privacy depends on public signal design, not only on proof verification.";
    }
}
