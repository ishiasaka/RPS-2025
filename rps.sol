// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "commit-reveal.sol";
import "time-unit.sol";

contract RPS is CommitReveal, TimeUnit {
    struct Player {
        uint8 choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - undefined
        bytes32 hashedChoice;
        bool isCommited;
        bool isRevealed;
        address addr;
    }
    uint8 public numPlayer = 0;
    uint256 public reward = 0;
    mapping(uint8 => Player) public players;
    uint8 public numInput = 0;
    uint8 public numReveal = 0;
    uint256 public constant DURATION = 5 minutes;
    uint256 public constant PRICE = 2 ether;

    mapping(address => bool) public playablePlayers;

    constructor() {
        playablePlayers[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)] = true;
        playablePlayers[address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2)] = true;
        playablePlayers[address(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db)] = true;
        playablePlayers[address(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB)] = true;
    }
    

    function addPlayer() public payable {
        require(numPlayer < 2 , "Error(RPS::addPlayer): Full Player");
        require(msg.value == PRICE, "Error(RPS::addPlayer): Ether is not enough.");
        require(playablePlayers[msg.sender] == true, "Error(RPS:addPlayer: Player is not playable)");
        reward += msg.value;
        uint8 idx = numPlayer++;
        players[idx].addr = msg.sender;
        emit PlayerJoin(msg.sender, idx);
    }

    event PlayerJoin(address addr, uint256 idx);

    function input(bytes32 hashedAnswer, uint8 idx) public {
        require(
            players[idx].addr == msg.sender,
            "Error(RPS::input): You are not owner of this player"
        );
        require(
            !players[idx].isCommited,
            "Error(RPS::input): You are commited"
        );
        require(numPlayer == 2, "Error(RPS::input): Player not enough");
        require(
            numInput < 2,
            "Error(RPS::input): All player inputed, Please revealRequest"
        );
        commit(hashedAnswer);
        players[idx].hashedChoice = hashedAnswer;
        players[idx].isCommited = true;
        numInput++;
        emit PlayerCommited(msg.sender, idx);
    }

    event PlayerCommited(address player, uint8 idx);

    // If player not answered for
    function requestRefund(uint8 idx) public {
        require(
            players[idx].addr == msg.sender,
            "Error(RPS::requestRefund): You are not owner of this player"
        );
        require(
            elapsedSeconds() <= DURATION,
            "Error(RPS::requestRefund): Time not enough"
        );
        require(numPlayer > 0, "Error: No Player!!");
        address payable account = payable(msg.sender);
        // Case: Player waiting long time
        if (numPlayer == 1) {
            account.transfer(reward);
        } else {
            // Case: Player waiting commit long time
            if (numInput < 2) {
                require(
                    players[idx].isCommited,
                    "Error(RPS::requestRefund): You have not commited pls commit if not your money will return to another player."
                );
                account.transfer(reward);
                // Case: Player waiting reveal long time
            } else {
                require(
                    numReveal < 2,
                    "Error(RPS::requestRefund): All player revealed"
                );
                require(
                    players[idx].isRevealed,
                    "Error(RPS::requestRefund): You have not revealed pls reveal if not your money will return to another player."
                );
                account.transfer(reward);
            }
        }

        emit RefundCompleted(idx);
    }

    event RefundCompleted(uint8 idx);

    function revealRequest(
        string memory salt,
        uint8 choice,
        uint8 idx
    ) public {
        require(msg.sender == players[idx].addr, "Error(RPS::revealRequest): You are not owner of this player");
        require(numInput == 2 , "Error(RPS::revealRequest): Some player haven't commited.");
        require(choice >= 0 || choice < 5, "Error(RPS::revealRequest): Choice is not correct.");
        bytes32 bSalt = bytes32(abi.encodePacked(salt));
        bytes32 bChoice = bytes32(abi.encodePacked(choice));

        revealAnswer(bChoice, bSalt);
        players[idx].choice = choice;
        numReveal++;
        if (numReveal == 2) {
            _checkWinnerAndPay();
            return;
        }
        setStartTime();
    }

    function getChoiceHash(uint8 choice, string memory salt)
        public
        view
        returns (bytes32)
    {
        require(choice >= 0 && choice < 5, "Error(RPS::getChoiceHash): Choice is not correct!!!");
        bytes32 bSalt = bytes32(abi.encodePacked(salt));
        bytes32 bChoice = bytes32(abi.encodePacked(choice));
        return getSaltedHash(bChoice, bSalt);
    }

    function _checkWinner(uint256 p0Choice, uint256 p1Choice) private pure returns (uint8) {
        if (p0Choice == p1Choice) {
            return 0; // equal
        }

        if((p0Choice + 1) % 5 == p1Choice || (p0Choice - 2) % 5 == p1Choice) {
            return 1; // p0win
        }

        return 2;
    }

    function _checkWinnerAndPay() private {
        uint256 p0Choice = players[0].choice;
        uint256 p1Choice = players[1].choice;
        address payable account0 = payable(players[0].addr);
        address payable account1 = payable(players[1].addr);
        address winner;

        uint8 win = _checkWinner(p0Choice, p1Choice);

        if(win == 0) {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        } else if (win == 1) {
            account0.transfer(reward);
        } else {
            account1.transfer(reward);
        }

        emit Winner(winner);
        _reset();
    }

    function _reset() private {
        numInput = 0;
        numReveal = 0;
        reward = 0;
        delete players[0];
        delete players[1];
        emit Reset();
    }

    event Winner(address winner);
    event Reset();
}