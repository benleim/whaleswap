pragma solidity >=0.4.21;

import "./Pair.sol";

contract Factory {
    mapping(address => mapping(address => address)) public getPair;

    event PairDeployed(address indexed token0, address indexed token1, address pair);

    function createPair(address token0, address token1) external returns (address pair) {
        // requirements
        // TODO: Check not same token
        // TODO: Check pair doesn't exist

        // instantiate new pool
        pair = address(new Pair(token0, token1));
        
        // record new pair address
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        emit PairDeployed(token0, token1, pair);
    }
}