// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHyperdrive} from "hyperdrive/contracts/src/interfaces/IHyperdrive.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IUndegenRebalancer} from "./interfaces/IUndegenRebalancer.sol";

/**
 * @title UndegenRebalancer
 * @notice This is meant to be delegatecalled from a Safe,
 * to rebalance the Safe's assets according to a set of target USD amounts
 * for a set of risky assets, putting the rest in a Hyperdrive long.
 */
contract UndegenRebalancer is IUndegenRebalancer {
    event UndegenRebalancerCreated(address hyperdrivePool, address usdc, address swapRouter);
    event LongClosed(uint256 maturityTime, uint256 bondAmount, uint256 proceeds);
    event LongOpened(uint256 amount, uint256 maturityTime, uint256 bondProceeds);

    uint256 constant MAX_PPM = 1000000;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable usdc;

    IHyperdrive public immutable hyperdrivePool;
    ISwapRouter public immutable swapRouter;

    constructor(address _hyperdrivePool, address _usdc, address _swapRouter) {
        hyperdrivePool = IHyperdrive(_hyperdrivePool);
        swapRouter = ISwapRouter(_swapRouter);
        usdc = _usdc;
        emit UndegenRebalancerCreated(_hyperdrivePool, _usdc, _swapRouter);
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
                // Calculate the amount of the asset to sell based on the price
                uint256 amountToSell = (currentAmounts[i] - _args.riskyAssetUSDAmounts[i]) * 1e18 / _args.assetPrices[i];
                // Sell the difference
                _swap(_args.riskyAssets[i], ETH, amountToSell);
            }
        }
        uint256 ethBalance = address(this).balance;
        uint256 neededEth = 0;
        for (uint256 i = 0; i < _args.riskyAssets.length; i++) {
            // If the current amount is less than the target by more than the max deviation
            // we need to buy
            if (currentAmounts[i] < _args.riskyAssetUSDAmounts[i] * (MAX_PPM - _args.maxDeviationPPM) / MAX_PPM) {
                // Buy the difference
                neededEth = (_args.riskyAssetUSDAmounts[i] - currentAmounts[i]) * 1e18 / _args.assetPrices[i];
            }
        }
        // Add a 10% margin to the needed eth
        neededEth = neededEth * 11 / 10;
        if (ethBalance < neededEth) {
            // Calculate the amount of usdc to sell to get the needed eth
            uint256 amountToSell = (neededEth - ethBalance) * 1e18 / _args.ethPrice;
            // Swap usdc for the needed eth
            _swap(usdc, ETH, amountToSell);
        }

        for (uint256 i = 0; i < _args.riskyAssets.length; i++) {
            // If the current amount is less than the target by more than the max deviation
            // we need to buy
            if (currentAmounts[i] < _args.riskyAssetUSDAmounts[i] * (MAX_PPM - _args.maxDeviationPPM) / MAX_PPM) {
                // Calculate the amount of eth to sell to get the needed amount of the asset
                uint256 amountToSell = (_args.riskyAssetUSDAmounts[i] - currentAmounts[i]) * 1e18 / _args.ethPrice;
                // Buy the difference
                _swap(ETH, _args.riskyAssets[i], amountToSell);
            }
        }

        // Swap all remaining ETH for USDC
        _swap(ETH, usdc, address(this).balance);

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

    function _swap(address _from, address _to, uint256 _amountIn) internal {
        // Use Uniswap to swap the assets
        // https://github.com/delvtech/hyperdrive/blob/e1880a8e341dca44150dc2b1ae0cb99978f66f99/contracts/src/zaps/UniV3Zap.sol#L806
        // (Many thanks to Alex from the Hyperdrive team!)
        uint256 value;
        if (_from == ETH) {
            value = _amountIn;
        } else {
            IERC20(_from).approve(address(swapRouter), _amountIn);
        }
        // TODO: add slippage protection based on the oracle prices
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _from,
                tokenOut: _to,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 1,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        swapRouter.exactInputSingle{ value: value }(params);
    }
}
