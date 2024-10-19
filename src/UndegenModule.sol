// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ISafe} from "./safe/ISafe.sol";
import {IHyperdriveCore} from "hyperdrive/contracts/src/interfaces/IHyperdriveCore.sol";

contract UndegenModule {
    
    struct Asset {
        address token;
        uint256 usdAmount;
    }

    uint256 bondMaturity;
    uint256 bondAmount;
    address[] riskyAssets;

    address constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IHyperdriveCore immutable hyperdrivePool;

    constructor(address _hyperdrivePool, address[] memory _riskyAssets) {
        hyperdrivePool = IHyperdriveCore(_hyperdrivePool);
        riskyAssets = _riskyAssets;
    }

    function rebalance(address _safe, Asset[] memory _riskyAssets) public {
        ISafe safe = ISafe(_safe);


    }
}
