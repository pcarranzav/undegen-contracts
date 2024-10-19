// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ISafe} from "./interfaces/ISafe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHyperdrive} from "hyperdrive/contracts/src/interfaces/IHyperdrive.sol";
import {IHyperdriveCore} from "hyperdrive/contracts/src/interfaces/IHyperdriveCore.sol";

contract UndegenModule {

    event LongClosed(address safe, uint256 maturityTime, uint256 bondAmount, uint256 proceeds);

    error UndegenModuleBondNotMatured();
    error UndegenModuleUnauthorized(address sender, address safe);

    uint256 bondMaturity;
    uint256 bondAmount;
    address[] riskyAssets;
    address[] chronicleOracles;

    address constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IHyperdriveCore immutable hyperdrivePool;

    constructor(address _hyperdrivePool, address[] memory _riskyAssets, address[] memory _chronicleOracles) {
        hyperdrivePool = IHyperdriveCore(_hyperdrivePool);
        riskyAssets = _riskyAssets;
        chronicleOracles = _chronicleOracles;
    }

    function rebalance(address _safe, uint256[] memory _riskyAssetUSDAmounts) public {
        ISafe safe = ISafe(_safe);
        require(safe.isOwner(msg.sender), UndegenModuleUnauthorized(msg.sender, _safe));

        // If we have a bond on Hyperdrive, it must have matured to rebalance
        // TODO: In the future we could rebalance anyways as long as closing
        // the long would have a positive return.
        require(bondMaturity < block.timestamp, UndegenModuleBondNotMatured());
        if (bondMaturity != 0) {
            _closeLong(safe);
        }

        for (uint i = 0; i < riskyAssets.length; i++) {
            address asset = riskyAssets[i];
            uint256 desiredAmount = _riskyAssetUSDAmounts[i];
            uint256 currentAmount = _getAmountFromChronicle(i);
        }


        
    }

    function _execOnSafe(ISafe _safe, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory) {
        (bool success, bytes memory data) = _safe.execTransactionFromModuleReturnData(_to, _value, _data, 0);
        require(success, string(data));
        return data;
    }

    function _closeLong(ISafe _safe) internal returns (uint256) {
        IHyperdrive.Options memory hyperdriveOpts = IHyperdrive.Options({
            destination: address(_safe),
            asBase: false,
            extraData: ""
        });
        bytes memory data = _execOnSafe(
            _safe,
            address(hyperdrivePool),
            0,
            abi.encodeCall(hyperdrivePool.closeLong, (bondMaturity, bondAmount, 0, hyperdriveOpts))
        );
        uint256 proceeds = abi.decode(data, (uint256));
        bondMaturity = 0;
        bondAmount = 0;
        emit LongClosed(address(_safe), bondMaturity, bondAmount, proceeds);
        return proceeds;
    }

    function _getAmountFromChronicle(uint256 i) internal returns (uint256) {
        // TODO
        // Use Chronicle oracle to get the price of the asset

        // Then use the balance of that asset and the price to convert to a USD amount
        
        return 9000;
    }
}
