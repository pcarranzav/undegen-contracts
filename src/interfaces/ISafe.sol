// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ISafe {
    function execTransactionFromModule(address to, uint256 value, bytes memory data, uint8 operation) external returns (bool success);
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation
    ) external returns (bool success, bytes memory returnData);
    function isOwner(address owner) external view returns (bool);
}
