pragma solidity >=0.8.0;

// NOTE: Need to change s.t. executeVirtualOrders work for all previous blocks (not just intervals)
import "./libraries/Math.sol";

library TWAMM {
    using Math for uint256;

    struct OrderPools {
        uint256 orderExpireInterval;
        uint256 lastExecutedBlock;
        address tokenX;
        address tokenY;
        mapping(address => mapping(address => OrderPool)) pools;
    }

    struct OrderPool {
        // QUESTION: Would a better name be poolId or have i misunderstood what this is...?
        uint256 orderId;
        address tokenX;
        address tokenY;
        uint256 saleRate;
        uint256 lastExecutionBlock;
        mapping(uint256 => LongTermOrder) orders;
        mapping(uint256 => uint256) expirationByBlockInterval;
        // QUESTION: Can we maybe please have a mapping of users/addresses to their orderIds?
    }

    struct LongTermOrder {
        uint256 id;
        address creator;
        uint256 beginBlock;
        uint256 finalBlock;
        uint256 ratePerBlock;
        bool active;
    }

    event OrderCreated(
        uint256 id,
        address token1,
        address token2,
        address creator
    );
    event OrderCancelled(uint256 id, address token1, address token2);

    function initialize(
        OrderPools storage self,
        address _token0,
        address _token1,
        uint256 _orderExpireInterval
    ) internal {
        self.orderExpireInterval = _orderExpireInterval;
        self.lastExecutedBlock = block.number;
        self.tokenX = _token0;
        self.tokenY = _token1;
    }

    // NOTE: have to pass reserves by reference for updating
    // NOTE: access modifier 'internal' inlines the code into calling contract
    function executeVirtualOrders(
        OrderPools storage self,
        uint256[2] storage reserves
    ) internal {
        // calc number of passed intervals
        uint256 prevBlockInterval = block.number -
            (block.number % self.orderExpireInterval);
        uint256 numberIntervals = prevBlockInterval / self.lastExecutedBlock;

        // execute virtual reserve changes for every interval
        OrderPool storage pool1 = self.pools[self.tokenX][self.tokenY];
        OrderPool storage pool2 = self.pools[self.tokenY][self.tokenX];

        // I think this is a nice, intuitive way of doing it
        for (uint16 i = 0; i < numberIntervals; i++) {
            uint256 currBlockInterval = self.lastExecutedBlock +
                ((i + 1) * self.orderExpireInterval);
            // execute order
            uint256 saleRate1 = pool1.saleRate;
            uint256 saleRate2 = pool2.saleRate;

            // TODO: calculate reserves
            //(uint256 xOut, uint256 yOut) = computeVirtualBalances();

            // TODO: update reserves

            // update for expiring orders
            // QUESTION: Set as inactive?
            pool1.saleRate -= pool1.expirationByBlockInterval[
                currBlockInterval
            ];
            pool2.saleRate -= pool2.expirationByBlockInterval[
                currBlockInterval
            ];
        }
    }

    function createVirtualOrder(
        OrderPools storage self,
        address _token1,
        address _token2,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _salesRate
    ) internal {
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: INVALID TOKEN PAIR");

        // argument validation
        require(_startBlock < _endBlock, "WHALESWAP: START / END ORDER");
        require(_salesRate != 0, "WHALESWAP: ZERO SALES RATE");
        require(
            _endBlock % self.orderExpireInterval == 0,
            "WHALESWAP: INVALID ENDING BLOCK"
        );

        // increment sales rate
        // QUESTION: Don't we want to wait until the start block to increment?
        pool.saleRate += _salesRate;

        // instantiate order
        pool.orders[pool.orderId] = LongTermOrder({
            id: pool.orderId,
            creator: msg.sender,
            beginBlock: _startBlock,
            finalBlock: _endBlock,
            ratePerBlock: _salesRate,
            active: false
        });

        // set expiration amount
        // QUESTION: Don't understand :(
        pool.expirationByBlockInterval[_endBlock] += _salesRate;

        // increment counter
        pool.orderId++;

        emit OrderCreated(pool.orderId - 1, _token1, _token2, msg.sender);
    }

    function cancelVirtualOrder(
        OrderPools storage self,
        uint256 _id,
        address _token1,
        address _token2
    ) internal {
        // fetch proper OrderPool
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: INVALID TOKEN PAIR");

        // fetch LongTermOrder by given id
        LongTermOrder storage order = pool.orders[_id];
        require(order.id != 0, "WHALESWAP: INVALID ORDER");
        require(order.creator == msg.sender, "WHALESWAP: PERMISSION DENIED");

        // decrease current sales rate & old expiring block rate change
        pool.saleRate -= order.ratePerBlock;
        // EDIT:
        pool.expirationByBlockInterval[order.finalBlock] -= order.ratePerBlock;

        order.active = false;

        emit OrderCancelled(_id, _token1, _token2);
    }

    function withdrawVirtualOrder(
        OrderPools storage self,
        address _token1,
        address _token2,
        uint256 _id
    ) internal {
        // fetch proper OrderPool
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: invalid token pair");

        // fetch LongTermOrder by given id
        LongTermOrder storage order = pool.orders[_id];
        require(order.id != 0, "WHALESWAP: invalid order id");
        require(order.creator == msg.sender, "WHALESWAP: permission denied");
        require(
            order.finalBlock >= block.timestamp,
            "WHALESWAP: order still executing"
        );

        // execute withdraw
    }

    function computeVirtualBalances(
        uint256 xStart,
        uint256 yStart,
        uint256 xRate,
        uint256 yRate,
        uint256 numberBlocks
    ) internal view returns (uint256 x, uint256 y) {
        uint256 k = xStart * yStart;
        uint256 xIn = xRate * numberBlocks;
        uint256 yIn = yRate * numberBlocks;
        uint256 xAmmEndLefthand = Math.sqrt((k * xIn) / yIn);
        uint256 eExp = 2 * Math.sqrt((xIn * yIn) / k);

        uint256 xAmmStartYIn = Math.sqrt(xStart * yIn);
        uint256 yAmmStartXIn = Math.sqrt(yStart * xIn);
        uint256 c = (xAmmStartYIn - yAmmStartXIn) /
            (xAmmStartYIn + yAmmStartXIn);

        // TODO: Work out how to do exponentials
        //uint xAmmEnd = xAmmEndLefthand
    }
}
