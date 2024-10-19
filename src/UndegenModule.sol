// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IModuleManager } from "./safe/IModuleManager.sol";

contract UndegenModule {
    
    struct Asset {
        address token;
        uint256 dollarAmount;
    }
    function rebalance(address _safe, Asset[] memory _assets) public {
        
    }
}
