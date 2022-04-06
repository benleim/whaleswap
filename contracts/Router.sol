pragma solidity >= 0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

import "./Pair.sol";
import "./Factory.sol";

contract Router {
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
            uint optimalAmount1 = desiredAmount0 * y / x;
            if (optimalAmount1 <= desiredAmount1) {
                // TODO: Add checks
                require(optimalAmount1 >= minAmount1, "Invalid token1 minimum");
                (amount0, amount1) = (desiredAmount0, optimalAmount1);
            } else {
                uint optimalAmount0 = desiredAmount1 * x / y;
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
        // call pair.mint()
        liquidity = Pair(pair).mint(to,amount0,amount1);
    }

    function burnLiquidity(
        address token0,
        address token1,
        uint liq,
        address to
    ) public virtual returns (uint amount0, uint amount1) {
        // Fetch pair address
        address pair = Factory(factory).getPair(token0, token1);
        // Transfer LP tokens
        Pair(pair).transferFrom(msg.sender, pair, liq);
        // Burn liquidity
        (uint amount0Burn, uint amount1Burn) = Pair(pair).burn(to);
        (amount0, amount1) = (amount0Burn, amount1Burn);
    }

    // *** SWAPPING ***
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            // Calculate source & destination
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = _sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? Factory(factory).getPair(output, path[i + 2]) : _to;

            // Execute swap on pair contract
            Pair(Factory(factory).getPair(input, output)).swap(
                amount0Out, amount1Out, to
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        address[] calldata path,
        address to
    ) external returns (uint[] memory amounts) {
        amounts = _getAmountsOut(amountIn, path);

        ERC20(path[0]).transferFrom(msg.sender, Factory(factory).getPair(path[0], path[1]), amounts[0]);

        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to
    ) external returns (uint[] memory amounts) {
        amounts = _getAmountsIn(amountOut, path);

        ERC20(path[0]).transferFrom(msg.sender, Factory(factory).getPair(path[0], path[1]), amounts[0]);

        _swap(amounts, path, to);
    }

    // -------- LIBRARY FUNCTIONS --------
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
    
    function _getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {    
        (address token0,) = _sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1) = Pair(Factory(factory).getPair(tokenA, tokenB)).getAmounts();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function _getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function _getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = _getReserves(path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function _getAmountsIn(uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        amounts[path.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = _getReserves(path[i - 1], path[i]);
            amounts[i - 1] = _getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}