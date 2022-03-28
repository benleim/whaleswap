pragma solidity >= 0.8.0;

library TWAMM {
    struct OrderPools {
        uint orderExpireInterval;

        mapping (address => mapping(address => OrderPool)) pools;
    }

    struct OrderPool {
        uint orderId;

        address tokenX;
        address tokenY;

        uint256 currentRate;
        uint256 lastExecutionBlock;

        mapping (uint256 => LongTermOrder) orders;
    }

    struct LongTermOrder {
        uint256 id;
        address creator;

        uint256 beginBlock;
        uint256 finalBlock;
        uint ratePerBlock;

        bool canceled;
    }

    event OrderCreated(address token1, address token2, address creator);

    // NOTE: have to pass reserves by reference for updating
    // NOTE: access modifier 'internal' inlines the code into calling contract
    function executeVirtualOrders(OrderPools storage self, uint[2] storage reserves) internal {

    }

    function createVirtualOrder(OrderPools storage self, address _token1, address _token2, uint256 _startBlock, uint256 _endBlock, uint _salesRate) internal {
        OrderPool storage pool = self.pools[_token1][_token2];
        require(pool.orderId != 0, "WHALESWAP: INVALID TOKEN PAIR");

        // increment sales rate
        pool.currentRate += _salesRate;
        
        // instantiate order
        pool.orders[pool.orderId] = LongTermOrder({
            id: pool.orderId,
            creator: msg.sender,
            beginBlock: _startBlock,
            finalBlock: _endBlock,
            ratePerBlock: _salesRate,
            canceled: false
        });

        // increment counter
        pool.orderId++;

        emit OrderCreated(_token1, _token2, msg.sender);
    }

    function cancelVirtualOrder(OrderPools storage self, uint id) internal {

    }

    function withdrawVirtualOrder(OrderPools storage self, uint id) internal {

    }
}