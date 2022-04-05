pragma solidity >= 0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract TestToken1 is ERC20 {

    constructor () ERC20("Token1", "TKN1", 18) {
        _mint(msg.sender, 1000000000);
    }
}