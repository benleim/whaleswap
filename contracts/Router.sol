pragma solidity >= 0.6.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "./Pair.sol";
import "./Factory.sol";

contract Router {
    address public factory;

    constructor (address _factory) {
        factory = _factory;
    }

    // addLiquidity()
    // - Transfer tokens first
    // - Call .mint() on Pair

    // --- ADD LIQUIDITY ---
    function addLiquidity(
        address token0,
        address token1,
        uint amount0,
        uint amount1,
        address to) external returns (uint liquidity) {
        // TODO: Add optimal token amount logic
        // getpair address
        address pair = Factory(factory).getPair(token0, token1);
        // transfer token0 & token1 to pair
        ERC20(token0).transferFrom(msg.sender, pair, amount0);
        ERC20(token1).transferFrom(msg.sender, pair, amount1);
        // // call pair.mint()
        liquidity = Pair(pair).mint(to);
    }
}