// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./OrderMixin.sol";
import "./interfaces/IAmountGetter.sol";

import {FHE, euint64, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract EncryptedLimitOrder is IAmountGetter,
    EIP712("1inch Limit Order Protocol", "4"),
    Ownable,
    Pausable,
    OrderMixin
{
    // solhint-disable-next-line no-empty-blocks
    constructor(IWETH _weth) OrderMixin(_weth) Ownable(msg.sender) {}

    /// @dev Returns the domain separator for the current chain (EIP-712)
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns(bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Pauses all the trading functionality in the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all the trading functionality in the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
