pragma solidity >=0.8.0;

import "./Pair.sol";

contract Factory {
    mapping(address => mapping(address => address)) public getPair;

    event PairDeployed(address indexed token0, address indexed token1, address pair);

    function createPair(address _token0, address _token1, uint _interval) external returns (address pair) {
        // requirements
        require(_token0 != _token1, "WHALESWAP: Tokens cannot be the same");
        require(getPair[_token0][_token1] == address(0x0), "WHALESWAP: Pair already exists");

        // instantiate new pool
        pair = address(new Pair(_token0, _token1, _interval));
        
        // record new pair address
        getPair[_token0][_token1] = pair;
        getPair[_token1][_token0] = pair;

        emit PairDeployed(_token0, _token1, pair);
    }
}