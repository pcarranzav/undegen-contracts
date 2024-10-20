// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract MockOracle {
    uint256 public immutable price;
    constructor(uint256 _price) {
        price = _price;
    }

    function read() external view returns (uint256) {
        return price;
    }
}
