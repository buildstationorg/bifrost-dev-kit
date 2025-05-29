// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { L2Slpx } from "src/L2Slpx/L2Slpx.sol";
import { vETH } from "src/L2Slpx/vETH.sol";
import { vDOT } from "src/L2Slpx/vDOT.sol";
import { DOT } from "src/L2Slpx/DOT.sol";

contract DeployL2SlpxContracts is Script {
    function run() external returns (address l2SlpxAddress, address vETHAddress, address vDOTAddress, address DOTAddress) {
        /// @dev declare the address of the owner
        address OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;

        /// @dev start the broadcast
        vm.startBroadcast();
        /// @dev deploy the contracts
        
        console.log("Deploying L2Slpx contract");
        /// @dev deploy the L2Slpx contract
        L2Slpx l2Slpx = new L2Slpx(OWNER);
        /// @dev get the address of the L2Slpx contract
        l2SlpxAddress = address(l2Slpx);
        console.log("L2Slpx contract deployed at", l2SlpxAddress);

        
        console.log("Deploying vETH contract");
        /// @dev deploy the vETH contract
        vETH veth = new vETH(l2SlpxAddress);
        /// @dev get the address of the vETH contract
        vETHAddress = address(veth);
        console.log("vETH contract deployed at", vETHAddress);

        
        console.log("Deploying vDOT contract");
        /// @dev deploy the vDOT contract
        vDOT vdot = new vDOT(l2SlpxAddress);
        /// @dev get the address of the vDOT contract
        vDOTAddress = address(vdot);
        console.log("vDOT contract deployed at", vDOTAddress);


        console.log("Deploying DOT contract");
        /// @dev deploy the DOT contract
        DOT dot = new DOT(OWNER);
        /// @dev get the address of the DOT contract
        DOTAddress = address(dot);
        console.log("DOT contract deployed at", DOTAddress);


        /// @dev stop the broadcast
        vm.stopBroadcast();

        /// @dev return the addresses
        return (l2SlpxAddress, vETHAddress, vDOTAddress, DOTAddress);
    }
}