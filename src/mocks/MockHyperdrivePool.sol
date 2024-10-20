// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IHyperdrive} from "hyperdrive/contracts/src/interfaces/IHyperdrive.sol";

contract MockHyperdrivePool {
    event OpenLong(
        uint256 amount,
        uint256 minOutput,
        uint256 minVaultSharePrice,
        IHyperdrive.Options options
    );
    event CloseLong(
        uint256 maturityTime,
        uint256 bondAmount,
        uint256 minOutput,
        IHyperdrive.Options options
    );
    uint256 public proceeds;

    function openLong(
        uint256 _amount,
        uint256 _minOutput,
        uint256 _minVaultSharePrice,
        IHyperdrive.Options calldata _options
    ) external payable returns (uint256 maturityTime, uint256 bondProceeds) {
        emit OpenLong(_amount, _minOutput, _minVaultSharePrice, _options);
        proceeds = _amount;
        return (block.timestamp, proceeds);
    }

    function closeLong(
        uint256 _maturityTime,
        uint256 _bondAmount,
        uint256 _minOutput,
        IHyperdrive.Options calldata _options
    ) external returns (uint256) {
        emit CloseLong(_maturityTime, _bondAmount, _minOutput, _options);
        return proceeds;
    }
}
