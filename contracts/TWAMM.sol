pragma solidity >= 0.8.0;

library TWAMM {
    struct OrderPools {
        uint orderExpireInterval;

        OrderPool orderPoolX;
        OrderPool orderPool;
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

        uint256 startBlock;
        uint256 finalBlock;
        uint ratePerBlock;

        bool canceled;
    }

    function executeVirtualOrders(OrderPools storage self) external {

    }

    function createVirtualOrder(OrderPools storage self) external {

    }

    function cancelVirtualOrder(OrderPools storage self, uint id) external {

    }

    function withdrawVirtualOrder(OrderPools storage self, uint id) external {

    }
}