pragma solidity >=0.8.0;

import "./libraries/Math.sol";
import "hardhat/console.sol";

/// @title A library for TWAMM functionality (https://www.paradigm.xyz/2021/07/twamm)
/// @author Ben Leimberger
library TWAMM {
    using Math for uint;

    struct OrderPools {
        uint orderExpireInterval;
        uint lastExecutedBlock;

        address tokenX;
        address tokenY;

        mapping (address => mapping(address => OrderPool)) pools;
    }

    struct OrderPool {
        uint orderId;

        address tokenX;
        address tokenY;

        uint256 saleRate;
        uint256 lastExecutionBlock;

        mapping (uint256 => LongTermOrder) orders;
        mapping (uint => uint) expirationByBlockInterval;
    }

    struct LongTermOrder {
        uint256 id;
        address creator;

        uint256 beginBlock;
        uint256 finalBlock;
        uint ratePerBlock;

        bool active;
    }

    event LongTermOrderCreated(uint id, address token1, address token2, address creator);
    event LongTermOrderCancelled(uint id, address token1, address token2);

    function initialize(OrderPools storage self, address _token0, address _token1, uint _orderExpireInterval) internal {
        self.orderExpireInterval = _orderExpireInterval;
        self.lastExecutedBlock = block.number - 1;
        self.tokenX = _token0;
        self.tokenY = _token1;
    }

    // NOTE: have to pass reserves by reference for updating
    // NOTE: access modifier 'internal' inlines the code into calling contract
    function executeVirtualOrders(OrderPools storage self, uint[2] storage reserves) internal {
        console.log("Current block: %s, Last Executed Block: %s", block.number, self.lastExecutedBlock);
        // calc number of passed intervals
        uint expireInterval = self.orderExpireInterval;

        // execute virtual reserve changes for every interval
        OrderPool storage pool1 = self.pools[self.tokenX][self.tokenY];
        OrderPool storage pool2 = self.pools[self.tokenY][self.tokenX];

        // Iterate over intervals in bounds
        uint lastBlock = self.lastExecutedBlock + 1;
        while (lastBlock <= block.number) {
            console.log("Lower-Bound Block Number=%s", lastBlock);
            // check if lower bound is interval
            if (lastBlock % expireInterval == 0) {
                pool1.saleRate -= pool1.expirationByBlockInterval[lastBlock];
                pool2.saleRate -= pool2.expirationByBlockInterval[lastBlock];
            }

            uint beforeNextInterval = lastBlock + (expireInterval - (lastBlock % expireInterval)) - 1;
            uint nextBlock = (beforeNextInterval < block.number) ? beforeNextInterval : block.number;
            console.log("Upper-Bound Block Number=%s", nextBlock);
            console.log("=============");

            // execute order
            uint saleRate1 = pool1.saleRate;
            uint saleRate2 = pool2.saleRate;

            // TODO: calculate reserves
            // (uint xOut, uint yOut) = computeVirtualBalances();

            // TODO: update reserves

            lastBlock = nextBlock + 1;
        }

        // update last executed block
        self.lastExecutedBlock = block.number;
    }

    /// @notice method for creating a time-weighted average virtual order over time
    /// @dev order begins as soon as function is called
    function createVirtualOrder(OrderPools storage self, address _token1, address _token2, uint256 _endBlock, uint _salesRate) internal {
        // update virtual orders status
        // executeVirtualOrders(self, reserves);

        OrderPool storage pool = self.pools[_token1][_token2];

        // argument validation
        require(block.number < _endBlock, "WHALESWAP: start / end order");
        require(_salesRate != 0, "WHALESWAP: zero sales rate");
        require(_endBlock % self.orderExpireInterval == 0, "WHALESWAP: invalid ending block");

        // increment sales rate immediately
        pool.saleRate += _salesRate;
        
        // instantiate order
        pool.orders[pool.orderId] = LongTermOrder({
            id: pool.orderId,
            creator: msg.sender,
            beginBlock: block.number,
            finalBlock: _endBlock,
            ratePerBlock: _salesRate,
            active: false
        });

        // set expiration amount
        pool.expirationByBlockInterval[_endBlock] += _salesRate;

        // increment counter
        pool.orderId++;

        emit LongTermOrderCreated(pool.orderId - 1, _token1, _token2, msg.sender);
    }

    /// @notice cancels an existing, active virtual order by identifier
    function cancelVirtualOrder(OrderPools storage self, uint _id, address _token1, address _token2) internal {
        // update virtual orders status
        // executeVirtualOrders(self, reserves);

        // calculate reserve changes
        // calculateVirtualReserves()

        // fetch proper OrderPool
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: invalid token pair");

        // fetch LongTermOrder by given id
        LongTermOrder storage order = pool.orders[_id];
        require(order.id != 0, "WHALESWAP: invalid order");
        require(order.finalBlock > block.number, "WHALESWAP: order already finished");
        require(order.creator == msg.sender, "WHALESWAP: permission denied");

        // decrease current sales rate & old expiring block rate change
        pool.saleRate -= order.ratePerBlock;

        // remove expiration penalty on expiration interval
        pool.expirationByBlockInterval[order.finalBlock] -= order.ratePerBlock;

        // mark order inactive
        order.active = false;

        emit LongTermOrderCancelled(_id, _token1, _token2);
    }

    /// @notice withdraw from a completed virtual order
    function withdrawVirtualOrder(OrderPools storage self, address _token1, address _token2, uint _id) internal {
        // update virtual orders status
        // executeVirtualOrders(self, reserves);

        // fetch proper OrderPool
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: invalid token pair");

        // fetch LongTermOrder by given id
        LongTermOrder storage order = pool.orders[_id];
        require(order.id != 0, "WHALESWAP: invalid order id");
        require(order.creator == msg.sender, "WHALESWAP: permission denied");
        require(order.finalBlock < block.timestamp, "WHALESWAP: order still executing");

        // execute withdraw

    }

    /// @notice logic for computing TWAMM virtual change in underlying reserves
    function computeVirtualBalances(uint xStart, uint yStart, uint xRate, uint yRate, uint numberBlocks) view internal returns (uint x, uint y) {
        uint k = xStart * yStart;
        uint xIn = xRate * numberBlocks;
        uint yIn = yRate * numberBlocks;
        uint xAmmEndLefthand = Math.sqrt((k * xIn) / yIn);
        uint eExp = 2 * Math.sqrt(xIn * yIn / k);
        
        uint xAmmStartYIn = Math.sqrt(xStart * yIn);
        uint yAmmStartXIn = Math.sqrt(yStart * xIn);
        uint c = (xAmmStartYIn - yAmmStartXIn) / (xAmmStartYIn + yAmmStartXIn);

        // uint xAmmEnd = xAmmEndLefthand * 
        x = 1;
        y = 1;
    }
}