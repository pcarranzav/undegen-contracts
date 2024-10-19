// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UndegenModule} from "../src/UndegenModule.sol";

contract UndegenModuleTest is Test {
    UndegenModule public undegen;

    function setUp() public {
        address[] memory riskyAssets = new address[](1);
        undegen = new UndegenModule(address(0), riskyAssets);
    }

    function test_noop() public {
        console.log("noop");
    }
}
