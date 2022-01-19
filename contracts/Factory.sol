pragma solidity >=0.4.21 <0.7.0;

import "./Pair.sol";

contract Factory {
    mapping(address => mapping(address => address)) public getPair;

    function createPair(address token0, address token1) {
        // requirements
        // TODO: Check not same token
        // TODO: Check pair doesn't exist

        // instantiate new pool
        address pair = new Pair();
        
        // record new pair address
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
    }
}