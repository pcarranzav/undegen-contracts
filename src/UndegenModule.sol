// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ISafe} from "./safe/ISafe.sol";

contract UndegenModule {
    
    struct Asset {
        address token;
        uint256 dollarAmount;
    }
    function rebalance(address _safe, Asset[] memory _assets) public {
        ISafe safe = ISafe(_safe);
        
    }
}
