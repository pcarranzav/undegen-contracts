// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {UndegenRebalancer} from "../src/UndegenRebalancer.sol";
import {UndegenModule} from "../src/UndegenModule.sol";

contract UndegenDeploy is Script {
    address constant hyperdrivePool = 0xD5D9556052dB810Da774BeC127cd2aFF548a6571;
    address constant usdc = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant wbtc = 0x83c84Ad6614E8e6e31D2e7A8FbeD660b90c06a79; // QuestSwap
    address constant wsteth = 0xB2F2366FF8aA4DfCcb07603cD69D0D7a84feA689; // QuestSwap2

    address constant ethOracle = 0xea347Db6ef446e03745c441c17018eF3d641Bc8f;
    address constant wbtcOracle = 0x8E947Ea7D5881Cd600Ace95F1201825F8C708844;
    address constant wstethOracle = 0x834c4f996B8a6411AEC0f8a0cF6fAfd4423dBEe2;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UndegenRebalancer undegenRebalancer = new UndegenRebalancer(hyperdrivePool, usdc);
        console.log("UndegenRebalancer deployed at:", address(undegenRebalancer));

        address[] memory riskyAssets = new address[](2);
        riskyAssets[0] = wbtc;
        riskyAssets[1] = wsteth;

        address[] memory chronicleOracles = new address[](2);
        chronicleOracles[0] = wbtcOracle;
        chronicleOracles[1] = wstethOracle;

        UndegenModule undegenModule =
            new UndegenModule(riskyAssets, chronicleOracles, ethOracle, address(undegenRebalancer));
        console.log("UndegenModule deployed at:", address(undegenModule));

        vm.stopBroadcast();
    }
}
