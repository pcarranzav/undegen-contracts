// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ISafe} from "./interfaces/ISafe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHyperdrive} from "hyperdrive/contracts/src/interfaces/IHyperdrive.sol";
import {IHyperdriveCore} from "hyperdrive/contracts/src/interfaces/IHyperdriveCore.sol";

contract UndegenModule {

    error UndegenModuleBondNotMatured();

    uint256 bondMaturity;
    uint256 bondAmount;
    address[] riskyAssets;

    address constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IHyperdriveCore immutable hyperdrivePool;

    constructor(address _hyperdrivePool, address[] memory _riskyAssets) {
        hyperdrivePool = IHyperdriveCore(_hyperdrivePool);
        riskyAssets = _riskyAssets;
    }

    function rebalance(address _safe, uint[] memory _riskyAssetUSDAmounts) public {
        ISafe safe = ISafe(_safe);

        // If we have a bond on Hyperdrive, it must have matured to rebalance
        // TODO: In the future we could rebalance anyways as long as closing
        // the long would have a positive return.
        require(bondMaturity < block.timestamp, UndegenModuleBondNotMatured());
        IHyperdrive.Options memory hyperdriveOpts = IHyperdrive.Options({
            destination: _safe,
            asBase: false,
            extraData: ""
        });
        _execOnSafe(
            safe,
            address(hyperdrivePool),
            0,
            abi.encodeCall(hyperdrivePool.closeLong, (bondMaturity, bondAmount, 0, hyperdriveOpts))
        );
    }

    function _execOnSafe(ISafe _safe, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory) {
        (bool success, bytes memory data) = _safe.execTransactionFromModuleReturnData(_to, _value, _data, 0);
        require(success, string(data));
        return data;
    }
}
