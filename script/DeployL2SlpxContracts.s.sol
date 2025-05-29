// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { L2Slpx } from "src/L2Slpx/L2Slpx.sol";
import { vETH } from "src/L2Slpx/vETH.sol";
import { vDOT } from "src/L2Slpx/vDOT.sol";
import { DOT } from "src/L2Slpx/DOT.sol";

contract CREATE3Deploy is Script {
    function run() external returns (address l2SlpxAddress, address vETHAddress, address vDOTAddress, address DOTAddress) {
        /// @dev declare the address of the owner
        address OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;

        /// @dev start the broadcast
        vm.startBroadcast();
        /// @dev deploy the contracts
        console.log("Deploying L2Slpx contract");
        l2SlpxAddress = address(new L2Slpx(OWNER));
        console.log("Deploying vETH contract");
        vETHAddress = address(new vETH(l2SlpxAddress));
        console.log("Deploying vDOT contract");
        vDOTAddress = address(new vDOT(l2SlpxAddress));
        console.log("Deploying DOT contract");
        DOTAddress = address(new DOT(OWNER));
        /// @dev stop the broadcast
        vm.stopBroadcast();

        /// @dev return the addresses
        return (l2SlpxAddress, vETHAddress, vDOTAddress, DOTAddress);
    }
}