pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "./TWAMM.sol";

contract Pair is ERC20 {
    using UQ112x112 for uint224;

    address public factory;
    address public token0;
    address public token1;

    uint112 x;
    uint112 y;
    uint k;

    uint public price0Cumulative;
    uint public price1Cumulative;
    uint32 public lastBlockTimestamp;

    TWAMM.OrderPools orderPools;

    constructor(address _token0, address _token1, uint _twammIntervalSize) ERC20("lWhale", "lWHL", 18) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        TWAMM.initialize(orderPools, _token0, _token1, _twammIntervalSize);
    }

    function getAmounts() view external returns (uint112 amount0, uint112 amount1) {
        amount0 = x;
        amount1 = y;
    }

    function getLongTermOrderInterval() view external returns (uint blockInterval) {
        blockInterval = orderPools.orderExpireInterval;
    }

    // Utility function
    function _update(uint balance0, uint balance1, uint112 _x, uint112 _y) private {
        // Block timestamp calculations
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - lastBlockTimestamp;

        // Add to cumulative price
        if (timeElapsed > 0 && _x != 0 && _y != 0) {
            price0Cumulative += uint(UQ112x112.encode(_y).uqdiv(_x)) * timeElapsed;
            price1Cumulative += uint(UQ112x112.encode(_x).uqdiv(_y)) * timeElapsed;
        }

        // Update contract state variables
        x = uint112(balance0);
        y = uint112(balance1);
        lastBlockTimestamp = blockTimestamp;
    }

    // --- Liquidity functions ---
    function mint(address to) external returns (uint liquidity) {
        // update reserves
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - x;
        uint amount1 = balance1 - y;

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1);
        } else {
            liquidity = Math.min((amount0 * totalSupply) / x, (amount1 * totalSupply) / y);
        }
        _mint(to, liquidity); // ERC-20 function
        _update(balance0, balance1, x, y);
    }

    function burn(address to) external returns (uint amount0, uint amount1) {
        uint balance0 = ERC20(token0).balanceOf(address(this));
        uint balance1 = ERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        
        amount0 = liquidity * (balance0) / totalSupply;
        amount1 = liquidity * (balance1) / totalSupply;

        _burn(address(this), liquidity); // burn liquidity tokens

        // Transfer tokens back to LP
        ERC20(token0).transfer(to, amount0);
        ERC20(token1).transfer(to, amount1);

        // Update balances
        balance0 = ERC20(token0).balanceOf(address(this));
        balance1 = ERC20(token1).balanceOf(address(this));

        _update(balance0, balance1, x, y);
    }

    function swap(uint amount0Out, uint amount1Out, address to) external {
        uint balance0;
        uint balance1;
        if (amount0Out > 0) {
            ERC20(token0).transfer(to, amount0Out);
        }
        if (amount1Out > 0) {
            ERC20(token1).transfer(to, amount1Out);
        }
        balance0 = ERC20(token0).balanceOf(address(this));
        balance1 = ERC20(token1).balanceOf(address(this));

        uint amount0In = balance0 > x - amount0Out ? balance0 - (x - amount0Out) : 0;
        uint amount1In = balance1 > y - amount1Out ? balance1 - (y - amount1Out) : 0;

        uint balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
        require(balance0Adjusted * balance1Adjusted >= uint(x) * y * (1000**2), 'Whaleswap: K');

        _update(balance0, balance1, x, y);
    }

    /// @notice execute long term swap buying Y & selling X
    /// @param _intervalNumber - the block number when LTO ends
    /// @param _totalXIn - total amount of tokenX to transfer
    function longTermSwapTokenXtoY(uint _intervalNumber, uint _totalXIn) external {
        _longTermSwap(token0, token1, _intervalNumber, _totalXIn, 0);
    }

    /// @notice execute long term swap buying X & selling Y
    /// @param _intervalNumber - the block number when LTO ends
    /// @param _totalYIn - total amount of tokenY to transfer
    function longTermSwapTokenYtoX(uint _intervalNumber, uint _totalYIn) external {
        _longTermSwap(token1, token0, _intervalNumber, 0, _totalYIn);
    }

    function _longTermSwap(address _token0, address _token1, uint _intervalNumber, uint _totalXIn, uint _totalYIn) private {
        // interval calculations
        uint nextIntervalBlock = block.number + (orderPools.orderExpireInterval - (block.number % orderPools.orderExpireInterval));
        uint endIntervalBlock = nextIntervalBlock + (_intervalNumber * orderPools.orderExpireInterval);

        // execute erc20 transfers
        // NOTE: msg.sender might not be correct here...
        if (_totalXIn == 0) ERC20(token1).transferFrom(msg.sender,address(this),_totalYIn);
        else if (_totalYIn == 0) ERC20(token0).transferFrom(msg.sender,address(this),_totalXIn);

        // calculate block sales rate
        // (works bc either _totalXIn or _totalYIn will always = 0)
        uint blockSalesRate = (_totalXIn + _totalYIn) / (endIntervalBlock - block.number);

        // create LongTermSwap
        TWAMM.createVirtualOrder(orderPools, _token0, _token1, endIntervalBlock, blockSalesRate);
    }

    /// @notice retrieve long term swap by id
    function getLongTermSwapXtoY(uint _id) external view returns (TWAMM.LongTermOrder memory order) {
        order = orderPools.pools[token0][token1].orders[_id];
    }

    /// @notice retrieve long term swap by id
    function getLongTermSwapYtoX(uint _id) external view returns (TWAMM.LongTermOrder memory order) {
        order = orderPools.pools[token1][token0].orders[_id];
    }
}