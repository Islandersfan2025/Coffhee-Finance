// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@openzeppelin/contracts/utils/math/Math.sol";
import ".../interfaces/IOrderMixin.sol";
import ".../interfaces/IAmountGetter.sol";

import {FHE, euint64, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract EncryptedLimitOrder is IAmountGetter {
    error IncorrectRange();

    modifier correctPrices(euint256 priceStart, euint256 priceEnd) {
        if (priceEnd <= priceStart) revert IncorrectRange();
        _;
    }

    function takingAmountData(
        IOrderMixin.Order calldata order,
        bytes calldata /* extension */,
        bytes32 /* orderHash */,
        eaddress /* taker */,
        euint256 makingAmount,
        euint256 remainingMakingAmount,
        bytes calldata extraData
    ) external pure returns (euint256) {
        (
            euint256 priceStart,
            euint256 priceEnd
        ) = abi.decode(extraData, (euint256, euint256));
        return takingAmountData(priceStart, priceEnd, order.makingAmount, makingAmount, remainingMakingAmount);
    }

    function makingAmountData(
        IOrderMixin.Order calldata order,
        bytes calldata /* extension */,
        bytes32 /* orderHash */,
        eaddress /* taker */,
        euint256 takingAmount,
        euint256 remainingMakingAmount,
        bytes calldata extraData
    ) external pure returns (uint256) {
        (
            euint256 priceStart,
            euint256 priceEnd
        ) = abi.decode(extraData, (euint256, euint256));
        return makingAmountData(priceStart, priceEnd, order.makingAmount, takingAmount, remainingMakingAmount);
    }

    function takerAmountData(
        euint256 priceStart,
        euint256 priceEnd,
        euint256 orderMakingAmount,
        euint256 makingAmount,
        euint256 remainingMakingAmount
    ) public correctPrices(priceStart, priceEnd) pure returns(euint256) {
        euint256 alreadyFilledMakingAmount = orderMakingAmount - remainingMakingAmount;
        /**
         * rangeTakerAmount = (
         *       f(makerAmountFilled) + f(makerAmountFilled + fillAmount)
         *   ) * fillAmount / 2 / 1e18
         *
         *  scaling to 1e18 happens to have better price accuracy
         */
        return (
            (priceEnd - priceStart) * (2 * alreadyFilledMakingAmount + makingAmount) / orderMakingAmount +
            2 * priceStart
        ) * makingAmount / 2e18;
    }

    function makerAmountData(
        euint256 priceStart,
        euint256 priceEnd,
        euint256 orderMakingAmount,
        euint256 takingAmount,
        euint256 remainingMakingAmount
    ) public correctPrices(priceStart, priceEnd) pure returns(euint256) {
        euint256 alreadyFilledMakingAmount = orderMakingAmount - remainingMakingAmount;
        euint256 b = priceStart;
        euint256 k = (priceEnd - priceStart) * 1e18 / orderMakingAmount;
        euint256 bDivK = priceStart * orderMakingAmount / (priceEnd - priceStart);
        return (Math.sqrt(
            (
                b * bDivK +
                alreadyFilledMakingAmount * (2 * b + k * alreadyFilledMakingAmount / 1e18) +
                2 * takingAmount * 1e18
            ) / k * 1e18
        ) - bDivK) - alreadyFilledMakingAmount;
    }
}
