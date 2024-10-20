// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ISafe} from "./interfaces/ISafe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHyperdrive} from "hyperdrive/contracts/src/interfaces/IHyperdrive.sol";
import {IHyperdriveCore} from "hyperdrive/contracts/src/interfaces/IHyperdriveCore.sol";
import {IUndegenRebalancer} from "./interfaces/IUndegenRebalancer.sol";
import {IChronicle} from "chronicle-std/src/IChronicle.sol";

contract UndegenModule {
    event UndegenModuleCreated(
        address[] riskyAssets, address[] chronicleOracles, address ethOracle, address rebalancer
    );
    event Rebalanced(address safe, uint256 bondProceeds, uint256 bondMaturity, uint256 bondAmount);

    error UndegenModuleBondNotMatured();

    uint256 bondMaturity;
    uint256 bondAmount;
    address[] riskyAssets;
    address[] chronicleOracles;
    address rebalancer;
    address immutable ethOracle;

    constructor(
        address[] memory _riskyAssets,
        address[] memory _chronicleOracles,
        address _ethOracle,
        address _rebalancer
    ) {
        riskyAssets = _riskyAssets;
        chronicleOracles = _chronicleOracles;
        rebalancer = _rebalancer;
        ethOracle = _ethOracle;
        emit UndegenModuleCreated(_riskyAssets, _chronicleOracles, _ethOracle, _rebalancer);
    }

    function rebalance(uint256[] memory _riskyAssetUSDAmounts, uint256 _maxDeviationPPM, uint256 _minLongDeposit)
        public
    {
        ISafe safe = ISafe(msg.sender);

        // If we have a bond on Hyperdrive, it must have matured to rebalance
        // TODO: In the future we could rebalance anyways as long as closing
        // the long would have a positive return.
        require(bondMaturity < block.timestamp, UndegenModuleBondNotMatured());

        uint256 ethPrice = 0;// _getPriceFromChronicle(ethOracle);
        uint256[] memory assetPrices = new uint256[](riskyAssets.length);
        // for (uint256 i = 0; i < riskyAssets.length; i++) {
        //     assetPrices[i] = _getPriceFromChronicle(chronicleOracles[i]);
        // }
        IUndegenRebalancer.RebalanceOperation memory rebalanceOperation = IUndegenRebalancer.RebalanceOperation({
            riskyAssetUSDAmounts: _riskyAssetUSDAmounts,
            riskyAssets: riskyAssets,
            maxDeviationPPM: _maxDeviationPPM,
            bondMaturity: bondMaturity,
            bondAmount: bondAmount,
            minLongDeposit: _minLongDeposit,
            ethPrice: ethPrice,
            assetPrices: assetPrices
        });
        bytes memory data = _delegateCallOnSafe(
            safe, rebalancer, 0, abi.encodeWithSelector(IUndegenRebalancer.rebalance.selector, rebalanceOperation)
        );
        IUndegenRebalancer.RebalanceReturn memory rebalanceReturn =
            abi.decode(data, (IUndegenRebalancer.RebalanceReturn));
        bondMaturity = rebalanceReturn.bondMaturity;
        bondAmount = rebalanceReturn.bondAmount;
        emit Rebalanced(msg.sender, rebalanceReturn.bondProceeds, bondMaturity, bondAmount);
    }

    function _delegateCallOnSafe(ISafe _safe, address _to, uint256 _value, bytes memory _data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory data) = _safe.execTransactionFromModuleReturnData(_to, _value, _data, 1);
        require(success, string(data));
        return data;
    }

    function _getPriceFromChronicle(address _oracle) internal returns (uint256) {
        return IChronicle(_oracle).read();
    }
}
