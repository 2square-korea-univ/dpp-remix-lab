// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Lab 1. 일부러 나쁘게 만든 개인정보 저장 예제입니다.
//
// 수업 목표:
// - `private` 키워드가 개인정보보호를 의미하지 않는다는 점을 확인합니다.
// - storage, event log, calldata에 원본 개인정보가 남을 수 있음을 관찰합니다.
// - 좋은 DPP 설계는 "무엇을 저장할까?"가 아니라
//   "무엇을 저장하지 않을까?"에서 출발한다는 점을 이해합니다.
contract BadPrivacyStorage {
    // 실제 서비스라면 이런 원본 개인정보를 온체인 struct에 넣으면 안 됩니다.
    // 이름, 이메일, 생년월일은 직접 식별 또는 재식별에 사용될 수 있습니다.
    // kycPassed처럼 단순한 bool 값도 지갑 주소와 결합되면 민감한 이용 이력이 됩니다.
    struct UserProfile {
        string name;
        string email;
        uint256 birthDateYYYYMMDD;
        bool kycPassed;
    }

    // `private`은 Solidity 코드에서 자동 getter를 만들지 않는다는 뜻에 가깝습니다.
    // 블록체인의 storage 자체가 암호화되거나 비공개가 되는 것은 아닙니다.
    // 블록 탐색기, 노드, 인덱서, 분석 도구는 온체인 데이터를 계속 관찰할 수 있습니다.
    mapping(address => UserProfile) private profiles;

    // event log는 특히 검색과 색인에 최적화된 공개 데이터입니다.
    // 아래처럼 email, birthDate를 event에 넣으면 "삭제하기 어려운 공개 로그"에 남습니다.
    // 이 예제에서는 수업 관찰을 위해 일부러 민감한 값을 event에 넣었습니다.
    event ProfileSaved(
        address indexed user,
        string name,
        string email,
        uint256 birthDateYYYYMMDD,
        bool kycPassed
    );

    // Remix에서 이 함수를 실행한 뒤 하단 transaction log를 펼쳐보세요.
    // `profiles` mapping은 private이지만, event log에는 입력값이 그대로 보입니다.
    // 입력 예시: "Alice","alice@example.test",20000101,true
    function saveProfile(
        string calldata name,
        string calldata email,
        uint256 birthDateYYYYMMDD,
        bool kycPassed
    ) external {
        // storage에 원본 개인정보를 저장합니다.
        // 이것은 DPP 관점에서 피해야 하는 패턴입니다.
        UserProfile storage profile = profiles[msg.sender];
        profile.name = name;
        profile.email = email;
        profile.birthDateYYYYMMDD = birthDateYYYYMMDD;
        profile.kycPassed = kycPassed;

        // event로 다시 한 번 원본 개인정보를 공개합니다.
        // 학생들은 이 event를 보면서 "private != privacy"를 확인하면 됩니다.
        emit ProfileSaved(
            msg.sender,
            name,
            email,
            birthDateYYYYMMDD,
            kycPassed
        );
    }

    // Remix에서 눌러볼 수 있는 수업 핵심 문장입니다.
    function lessonPoint() external pure returns (string memory) {
        return "private is a Solidity access modifier, not privacy.";
    }
}
