// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ISafe} from "../interfaces/ISafe.sol";

contract MockSafe is ISafe {
    function execTransactionFromModule(address to, uint256 value, bytes memory data, uint8 operation)
        external
        override
        returns (bool success)
    {
        revert("MockSafe: operation not supported");
    }

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, uint8 operation)
        external
        override
        returns (bool success, bytes memory returnData)
    {
        require(operation == 1, "MockSafe: operation not supported");
        require(value == 0, "MockSafe: value not supported");
        (success, returnData) = to.delegatecall(data);
    }

    function isOwner(address owner) external view override returns (bool) {
        return true;
    }
}
