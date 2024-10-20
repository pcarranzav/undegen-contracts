// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IUndegenRebalancer {
    struct RebalanceOperation {
        uint256[] riskyAssetUSDAmounts;
        address[] riskyAssets;
        uint256 maxDeviationPPM;
        uint256 bondMaturity;
        uint256 bondAmount;
        uint256 minLongDeposit;
        uint256 ethPrice;
        uint256[] assetPrices;
    }

    struct RebalanceReturn {
        uint256 bondProceeds;
        uint256 bondMaturity;
        uint256 bondAmount;
    }

    function rebalance(RebalanceOperation memory _rebalanceOperation) external returns (RebalanceReturn memory);
}
