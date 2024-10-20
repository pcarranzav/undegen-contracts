// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UndegenModule} from "../src/UndegenModule.sol";
import {UndegenRebalancer} from "../src/UndegenRebalancer.sol";
import {MockSafe} from "../src/mocks/MockSafe.sol";

contract UndegenModuleTest is Test {
    UndegenModule public undegenModule;
    UndegenRebalancer public undegenRebalancer;
    MockSafe public safe;

    function setUp() public {
        address[] memory riskyAssets = new address[](1);
        address[] memory oracles = new address[](1);
        safe = new MockSafe();
        undegenRebalancer = new UndegenRebalancer(address(0), address(0));
        undegenModule = new UndegenModule(riskyAssets, oracles, address(0), address(undegenRebalancer));
    }

    function test_noop() public {
        console.log("noop");
    }
}
