pragma solidity >=0.4.21;

import "./Pair.sol";

contract Factory {
    mapping(address => mapping(address => address)) public getPair;

    // Makes life easier xx
    // CHANGE (Add):
    address[] public allPairs;

    event PairDeployed(
        address indexed token0,
        address indexed token1,
        address pair
    );

    // CHANGE (Add):
    function getAllPairs() public view returns (address[] memory) {
        return allPairs;
    }

    function createPair(address token0, address token1)
        external
        returns (address pair)
    {
        // requirements
        require(token0 != token1, "WHALESWAP: Tokens cannot be the same");
        require(
            getPair[token0][token1] == address(0x0),
            "WHALESWAP: Pair already exists"
        );

        // instantiate new pool
        pair = address(new Pair(token0, token1));

        // record new pair address
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        // CHANGE (Add):
        allPairs.push(pair);

        emit PairDeployed(token0, token1, pair);
    }
}
