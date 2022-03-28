pragma solidity >= 0.8.0;

library TWAMM {
    struct OrderPools {
        uint orderExpireInterval;

        OrderPool orderPoolX;
        OrderPool orderPoolY;
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

    // NOTE: have to pass reserves by reference for updating
    // NOTE: access modifier 'internal' inlines the code into calling contract
    function executeVirtualOrders(OrderPools storage self, uint[2] storage reserves) internal {
        
    }

    function createVirtualOrder(OrderPools storage self, address token1, address token2, uint256 startBlock, uint256 endBlock, uint salesRate) internal {
        
    }

    function cancelVirtualOrder(OrderPools storage self, uint id) internal {

    }

    function withdrawVirtualOrder(OrderPools storage self, uint id) internal {

    }
}