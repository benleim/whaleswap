pragma solidity >= 0.6.0;

contract LongTermOrder {
    
    struct LongTermOrder {
        uint256 id;
        uint256 finalBlock;
        address creator;
    }

    struct OrderPool {
        address token1;
        address token2;

        uint256 lastExecutionBlock;

        mapping (uint256 => LongTermOrder) orders;
    }
}