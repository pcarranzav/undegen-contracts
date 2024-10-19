// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IUndegenRebalancer {
    struct RebalanceOperation {
        uint256[] riskyAssetUSDAmounts;
        address[] riskyAssets;
        address[] chronicleOracles;
        uint256 maxDeviationPPM;
        uint256 bondMaturity;
        uint256 bondAmount;
        uint256 minLongDeposit;
    }

    struct RebalanceReturn {
        uint256 bondProceeds;
        uint256 bondMaturity;
        uint256 bondAmount;
    }

    function rebalance(RebalanceOperation memory _rebalanceOperation) external returns (RebalanceReturn memory);
}
