// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {SimpleSwap} from "../src/SimpleSwap.sol"; // Import your DEX
import {MockERC20} from "../test/SimpleSwap.t.sol"; // Or a deployed ERC20 address

contract DeploySimpleSwap is Script {
    SimpleSwap public simpleSwap;
    // Pre-deployed token addresses (replace with actual addresses on your target network)
    address constant TOKEN_A_ADDRESS =
        0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97;
    address constant TOKEN_B_ADDRESS =
        0x21a31Ee1afC51d94C2eFcCAa2092aD1028285549;

    function run() public {
        // Optionally deploy mock tokens first if needed for testing
        // vm.startBroadcast();
        // MockERC20 tokenA = new MockERC20("Token A", "TKNA", 18);
        // MockERC20 tokenB = new MockERC20("Token B", "TKNB", 18);
        // vm.stopBroadcast();
        // console.log("Deployed Mock Token A:", address(tokenA));
        // console.log("Deployed Mock Token B:", address(tokenB));
        // Remember to use these deployed addresses below if you deploy them here

        require(
            TOKEN_A_ADDRESS != address(0) && TOKEN_B_ADDRESS != address(0),
            "Set token addresses!"
        );

        vm.startBroadcast();

        // Deploy SimpleSwap with the addresses of the two tokens it will manage
        simpleSwap = new SimpleSwap(TOKEN_A_ADDRESS, TOKEN_B_ADDRESS);

        vm.stopBroadcast();

        console.log("SimpleSwap deployed at:", address(simpleSwap));
        console.log("  Token0:", address(simpleSwap.token0()));
        console.log("  Token1:", address(simpleSwap.token1()));
    }
}
