pragma solidity=0.5.16;

contract PennPair {

    address public token0;
    address public token1;

    uint112 quantity0;
    uint112 quantity1;
    uint32 lastBlockTimestamp;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;

    function getReserves() public view returns (uint112 _quantity0, uint112 _quantity1, uint132 _lastBlockTimestamp) {
        _quantity0 = quantity0;
        _quantity1 = quantity1;
        _lastBlockTimestamp = lastBlockTimestamp;
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint Amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 quantity0, uint112 quantity1);

    constructor() public {
        // Clearly expected to be constructed by the factory contract
        factory = msg.sender
    }

    // called once by the factory at the time of deployment
    function init(address _token0, address _token1) external {
        require(msg.sender = factory, 'PennAMM: FORBIDDEN'); // check caller
        token0 = _token0;
        token1 = _token1;
    }
}