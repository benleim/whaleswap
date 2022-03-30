pragma solidity >=0.8.0;

library TWAMM {
    struct OrderPools {
        uint orderExpireInterval;
        uint lastExecutedBlock;

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

    event OrderCreated(uint id, address token1, address token2, address creator);
    event OrderCancelled(uint id, address token1, address token2);

    function initialize(OrderPools storage self, uint _orderExpireInterval) internal {
        self.orderExpireInterval = _orderExpireInterval;
        self.lastExecutedBlock = block.number;
    }

    // NOTE: have to pass reserves by reference for updating
    // NOTE: access modifier 'internal' inlines the code into calling contract
    function executeVirtualOrders(OrderPools storage self, uint[2] storage reserves) internal {
        // execute virtual reserve changes for every interval

        // 
    }

    function createVirtualOrder(OrderPools storage self, address _token1, address _token2, uint256 _startBlock, uint256 _endBlock, uint _salesRate) internal {
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: INVALID TOKEN PAIR");

        // argument validation
        require(_startBlock < _endBlock, "WHALESWAP: START / END ORDER");
        require(_salesRate != 0, "WHALESWAP: ZERO SALES RATE");

        // increment sales rate
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
        pool.expirationByBlockInterval[_endBlock] += _salesRate;

        // increment counter
        pool.orderId++;

        emit OrderCreated(pool.orderId - 1, _token1, _token2, msg.sender);
    }

    function cancelVirtualOrder(OrderPools storage self, uint _id, address _token1, address _token2) internal {
        // fetch proper OrderPool
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: INVALID TOKEN PAIR");

        // fetch LongTermOrder by given id
        LongTermOrder storage order = pool.orders[_id];
        require(order.id != 0, "WHALESWAP: INVALID ORDER");
        require(order.creator == msg.sender, "WHALESWAP: PERMISSION DENIED");

        pool.saleRate -= order.ratePerBlock;

        order.active = true;

        emit OrderCancelled(_id, _token1, _token2);
    }

    function withdrawVirtualOrder(OrderPools storage self, address _token1, address _token2, uint _id) internal {
        // fetch proper OrderPool
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: INVALID TOKEN PAIR");

        // fetch LongTermOrder by given id
        LongTermOrder storage order = pool.orders[_id];
        require(order.id != 0, "WHALESWAP: INVALID ORDER");
        require(order.creator == msg.sender, "WHALESWAP: PERMISSION DENIED");
        require(order.finalBlock >= block.timestamp, "WHALESWAP: order still executing");

        // execute withdrawl

    }
}