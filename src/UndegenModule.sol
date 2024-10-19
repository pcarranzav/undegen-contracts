// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ISafe {
    function execTransactionFromModule(address to, uint256 value, bytes memory data, uint8 operation) external returns (bool success);
}

contract UndegenModule {
    
    struct Asset {
        address token;
        uint256 dollarAmount;
    }
    function rebalance(address _safe, Asset[] memory _assets) public {
        
    }
}
