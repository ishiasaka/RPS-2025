# RPS (Big bang Theory's version)

## Entry file
RPS.sol

## How to play

1. Players call addPlayer to join this contract and pay 2 ether into contracts
2. Players select their choice that choice is

| Choice   | Number |
| -------- | ------ |
| scissors | 0      |
| paper    | 1      |
| rock     | 2      |
| lizard   | 3      |
| spock    | 4      |

3. Players hash their choices using `getChoiceHash`. Each player must create a salt for hashing their choices (the salt can be anything likes `"Hello"`). Then,players commit their hashed message by calling `input`
4. When all players commited their choice completely, they revealed their choices by calling `revealRequest` that takes the choice that you chose in the first time and their salts.
5. When all players revealed their choice completely, winner will get the money from the contract and the contract will be reseted.

## Security

### Front Runner

Fixed with the Commit-Reveal strategy by player must hash his/her choice with salt then commit his/her hash to contract another player can't know about choice that player selected. When two players have selected completely, Two players will reveal his choice and compare their choices.

## Timeout

### No another player join the contract

In `addPlayer` contract give 5 minutes to waiting another player join but if no player join to contract, player can refund his/her money from the contract to his/her pocket.

### Player decision for long time

Contract gives you 5 minutes for decision your choice and commit the hash if another player doesn't commit the hash player can refund money and take another player's money to his/her pocket.

### Player not revealed for long time

Contract gives you 3 minutes from last player committing for reveal your choice if another player doesn't reveal the choice player can refund money and take another player's money to his/her pocket.
