pragma solidity >= 0.6.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

import "./libraries/SafeMath.sol";
import "./Pair.sol";
import "./Factory.sol";

contract Router {
    using SafeMath for uint;

    address public factory;

    constructor (address _factory) {
        factory = _factory;
    }

    function _optimalLiquidity(
        address token0,
        address token1,
        uint desiredAmount0,
        uint desiredAmount1,
        uint minAmount0,
        uint minAmount1
    ) view internal returns (uint amount0, uint amount1) {
        address pair = Factory(factory).getPair(token0, token1);
        (uint x, uint y) = Pair(pair).getAmounts();
        // Empty pair with no liquidity
        if (x == 0 && y == 0) {
            (amount0, amount1) = (desiredAmount0, desiredAmount1);
        } else {
            uint optimalAmount1 = desiredAmount0.mul(y) / x;
            if (optimalAmount1 <= desiredAmount1) {
                // TODO: Add checks
                require(optimalAmount1 >= minAmount1, "Invalid token1 minimum");
                (amount0, amount1) = (desiredAmount0, optimalAmount1);
            } else {
                uint optimalAmount0 = desiredAmount1.mul(x) / y;
                require(optimalAmount0 >= minAmount0, "Invalid Token0 minimum");
                (amount0, amount1) = (optimalAmount0, desiredAmount1);
            }
        }
    }

    function addLiquidity(
        address token0,
        address token1,
        uint desiredAmount0,
        uint desiredAmount1,
        uint minAmount0,
        uint minAmount1,
        address to
    ) external returns (uint liquidity) {
        // Calculate optimal liquidity provision
        // (Don't allow LPs to shift price)
        (uint amount0, uint amount1) = _optimalLiquidity(token0, token1, desiredAmount0, desiredAmount1, minAmount0, minAmount1);
        // Fetch pair address
        address pair = Factory(factory).getPair(token0, token1);
        // transfer token0 & token1 to pair
        ERC20(token0).transferFrom(msg.sender, pair, amount0);
        ERC20(token1).transferFrom(msg.sender, pair, amount1);
        // call pair.mint()
        liquidity = Pair(pair).mint(to);
    }


}