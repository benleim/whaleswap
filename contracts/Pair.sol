pragma solidity >=0.4.21 <0.7.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "./libraries/Math.sol";

contract Pair is ERC20 {
    address public factory;
    address public token0;
    address public token1;

    uint112 x;
    uint112 y;
    uint k;

    uint public price0Cumulative;
    uint public price1Cumulative;
    uint32 public lastBlockTimestamp;

    constructor(address _token0, address _token1) public {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    // --- Liquidity Token funcs ---
    // mint()
    function mint(address to) external returns (uint liquidity) {
        // update reserves
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(x);
        uint amount1 = balance1.sub(y);

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1));
        } else {
            liquidity = Math.min(amount0.mul(totalSupply) / x, amount1.mul(totalSupply) / y);
        }
        _mint(to, liquidity); // ERC-20 function
        // TODO: update x & y

    }
    // burn()

    // swap()
}