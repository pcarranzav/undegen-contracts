// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHyperdrive} from "hyperdrive/contracts/src/interfaces/IHyperdrive.sol";

import {IUndegenRebalancer} from "./interfaces/IUndegenRebalancer.sol";

/**
 * @title UndegenRebalancer
 * @notice This is meant to be delegatecalled from a Safe,
 * to rebalance the Safe's assets according to a set of target USD amounts
 * for a set of risky assets, putting the rest in a Hyperdrive long.
 */
contract UndegenRebalancer is IUndegenRebalancer {
    event UndegenRebalancerCreated(address hyperdrivePool, address usdc);
    event LongClosed(uint256 maturityTime, uint256 bondAmount, uint256 proceeds);
    event LongOpened(uint256 amount, uint256 maturityTime, uint256 bondProceeds);

    uint256 constant MAX_PPM = 1000000;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable usdc;
    
    IHyperdrive immutable hyperdrivePool;

    constructor(address _hyperdrivePool, address _usdc) {
        hyperdrivePool = IHyperdrive(_hyperdrivePool);
        usdc = _usdc;
        emit UndegenRebalancerCreated(_hyperdrivePool, _usdc);
    }

    function rebalance(RebalanceOperation memory _args) external override returns (RebalanceReturn memory) {
        RebalanceReturn memory ret =
            RebalanceReturn({bondProceeds: 0, bondMaturity: _args.bondMaturity, bondAmount: _args.bondAmount});
        if (_args.bondMaturity != 0) {
            ret.bondProceeds = _closeLong(_args.bondMaturity, _args.bondAmount);
            ret.bondMaturity = 0;
            ret.bondAmount = 0;
        }

        uint256[] memory currentAmounts = new uint256[](_args.riskyAssets.length);
        for (uint256 i = 0; i < _args.riskyAssets.length; i++) {
            currentAmounts[i] = IERC20(_args.riskyAssets[i]).balanceOf(address(this)) * _args.assetPrices[i];

            // If the current amount is more than the target by more than the max deviation
            // we need to sell
            if (currentAmounts[i] > _args.riskyAssetUSDAmounts[i] * (MAX_PPM + _args.maxDeviationPPM) / MAX_PPM) {
                // Sell the difference
                _swap(_args.riskyAssets[i], ETH, currentAmounts[i] - _args.riskyAssetUSDAmounts[i]);
            }
        }
        // TODO: Buy ETH needed to cover the difference
        for (uint256 i = 0; i < _args.riskyAssets.length; i++) {
            // If the current amount is less than the target by more than the max deviation
            // we need to buy
            if (currentAmounts[i] < _args.riskyAssetUSDAmounts[i] * (MAX_PPM - _args.maxDeviationPPM) / MAX_PPM) {
                // Buy the difference
                _swap(ETH, _args.riskyAssets[i], _args.riskyAssetUSDAmounts[i] - currentAmounts[i]);
            }
        }

        // Swap all ETH for USDC
        _swapAll(ETH, usdc);

        uint256 totalAmount = IERC20(usdc).balanceOf(address(this));
        if (totalAmount > _args.minLongDeposit) {
            // Open a long with the USDC
            (ret.bondMaturity, ret.bondAmount) = _openLong(totalAmount);
        }
        return ret;
    }

    function _closeLong(uint256 _bondMaturity, uint256 _bondAmount) internal returns (uint256) {
        IHyperdrive.Options memory hyperdriveOpts =
            IHyperdrive.Options({destination: address(this), asBase: false, extraData: ""});
        // TODO: check the minimum output
        uint256 proceeds = hyperdrivePool.closeLong(_bondMaturity, _bondAmount, 0, hyperdriveOpts);
        emit LongClosed(_bondMaturity, _bondAmount, proceeds);
        return proceeds;
    }

    function _openLong(uint256 _amount) internal returns (uint256, uint256) {
        IHyperdrive.Options memory hyperdriveOpts =
            IHyperdrive.Options({destination: address(this), asBase: false, extraData: ""});
        // Approve the pool to spend the USDC
        IERC20(usdc).approve(address(hyperdrivePool), _amount);

        (uint256 maturityTime, uint256 bondProceeds) = hyperdrivePool.openLong(
            _amount,
            _amount,
            0, // TODO: add negative interest guard
            hyperdriveOpts
        );
        emit LongOpened(_amount, maturityTime, bondProceeds);
        return (maturityTime, bondProceeds);
    }

    function _swap(address _from, address _to, uint256 _amountUSD) internal {
        // TODO
        // Use Uniswap to swap the assets
    }

    function _swapAll(address _from, address _to) internal {
        // TODO
        // Use Uniswap to swap all the assets
    }
}
