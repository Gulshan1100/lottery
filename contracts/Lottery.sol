// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Lottery is VRFConsumerBaseV2 {
    address public manager;
    address[] public players;
    uint256 public startTime;
    uint64 s_subscriptionId;
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    constructor(uint64 subscriptionId)
        public
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        manager = msg.sender;
        startTime = block.timestamp;
    }

    function requestRandomWords() external restricted {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function enter() public payable {
        require(msg.value > .01 ether && block.timestamp < startTime + 30);
        players.push(msg.sender);
    }

    function pickWinner() public restricted {
        this.requestRandomWords();
        uint256 index = s_randomWords[0] % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
        startTime = 0;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}
