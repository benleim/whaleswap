pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "./TWAMM.sol";

import "hardhat/console.sol";

contract Pair is ERC20 {
    using UQ112x112 for uint224;

    address public factory;
    address public immutable token0;
    address public immutable token1;

    uint public price0Cumulative;
    uint public price1Cumulative;

    uint112 private x;
    uint112 private y;
    uint32 public lastBlockTimestamp;
    uint[2] private reserves;

    /// @dev twamm state
    TWAMM.OrderPools orderPools;

    event Swap();
    event MintLiquidity();
    event BurnLiquidity();
    event CreateLongTermOrder();
    event CancelLongTermOrder();
    event WithdrawLongTermOrder();

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

    /// @notice method for providing liquidity
    function mint(address _to, uint _amountInX, uint _amountInY) external returns (uint liquidity) {
        // handle transfers
        ERC20(token0).transferFrom(msg.sender, address(this), _amountInX);
        ERC20(token1).transferFrom(msg.sender, address(this), _amountInY);

        // calculate liquidity
        if (totalSupply == 0) {
            liquidity = Math.sqrt(_amountInX * _amountInY);
        } else {
            liquidity = Math.min((_amountInX * totalSupply) / x, (_amountInY * totalSupply) / y);
        }
        _mint(_to, liquidity); // ERC-20 function
        _update(x + _amountInX, y + _amountInY, x, y);

        emit MintLiquidity();
    }

    /// @notice method for burning liquidity
    function burn(address to) external returns (uint amount0, uint amount1) {
        uint liquidity = balanceOf[msg.sender];
        
        // calculate token amounts
        amount0 = (liquidity * x) / totalSupply;
        amount1 = (liquidity * y) / totalSupply;

        // Update balances
        x -= uint112(amount0);
        y -= uint112(amount1);

        // ERC-20 burn liquidity tokens
        _burn(msg.sender, liquidity);

        // Transfer tokens back to LP
        ERC20(token0).transfer(to, amount0);
        ERC20(token1).transfer(to, amount1);

        emit BurnLiquidity();
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
        require(balance0Adjusted * balance1Adjusted >= uint(x) * y * (1000**2), "Whaleswap: K");

        _update(balance0, balance1, x, y);

        emit Swap();
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
        require(_totalXIn == 0 || _totalYIn == 0, "WHALESWAP: invalid parameters");
        // interval calculations
        uint nextIntervalBlock = block.number + (orderPools.orderExpireInterval - (block.number % orderPools.orderExpireInterval));
        uint endIntervalBlock = nextIntervalBlock + (_intervalNumber * orderPools.orderExpireInterval);

        // execute erc20 transfers
        if (_totalXIn == 0) ERC20(token1).transferFrom(msg.sender,address(this),_totalYIn);
        else if (_totalYIn == 0) ERC20(token0).transferFrom(msg.sender,address(this),_totalXIn);

        // calculate block sales rate
        // (works bc either _totalXIn or _totalYIn will always = 0)
        uint blockSalesRate = (_totalXIn + _totalYIn) / (endIntervalBlock - block.number);

        // create LongTermSwap
        TWAMM.createVirtualOrder(orderPools, _token0, _token1, endIntervalBlock, blockSalesRate);
        
        emit CreateLongTermOrder();
    }

    /// @notice retrieve long term swap by id
    function getLongTermSwapXtoY(uint _id) external view returns (TWAMM.LongTermOrder memory order) {
        order = orderPools.pools[token0][token1].orders[_id];
    }

    /// @notice retrieve long term swap by id
    function getLongTermSwapYtoX(uint _id) external view returns (TWAMM.LongTermOrder memory order) {
        order = orderPools.pools[token1][token0].orders[_id];
    }

    /// @notice fetch orders by creator
    function getCreatedLongTermOrders() external view returns (TWAMM.LongTermOrder[] memory ordersXtoY, TWAMM.LongTermOrder[] memory ordersYtoX) {
        ordersXtoY = _getCreatedOrderPool(orderPools.pools[token0][token1]);
        ordersYtoX = _getCreatedOrderPool(orderPools.pools[token1][token0]);
    }

    function _getCreatedOrderPool(TWAMM.OrderPool storage pool) private view returns (TWAMM.LongTermOrder[] memory orders) {
        uint256 count = 0;
        for (uint256 i = 0; i < pool.orderId; i++) {
            if (pool.orders[i].creator == msg.sender) count++;
        }

        uint256 pos = 0;
        orders = new TWAMM.LongTermOrder[](count);
        for (uint256 j = 0; j < pool.orderId; j++) {
            if (pool.orders[j].creator == msg.sender) orders[pos++] = pool.orders[j];
        }
    }

    function cancelLongTermOrder(uint _id, address _token0, address _token1) external {
        TWAMM.cancelVirtualOrder(orderPools, _id, _token0, _token1);
        emit CancelLongTermOrder();
    }

    function withdrawLongTermOrder(uint _id, address _token0, address _token1) external {
        TWAMM.cancelVirtualOrder(orderPools, _id, _token0, _token1);
        emit WithdrawLongTermOrder();
    }

    function executeLongTermOrders() external {
        TWAMM.executeVirtualOrders(orderPools, reserves);
    }
}