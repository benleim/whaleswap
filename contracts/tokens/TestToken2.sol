pragma solidity >= 0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract TestToken2 is ERC20 {

    constructor () ERC20("Token2", "TKN2", 18) {
        _mint(msg.sender, 1000000000);
    }
}