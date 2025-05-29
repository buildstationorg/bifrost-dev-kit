// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { L2Slpx } from "src/L2Slpx/L2Slpx.sol";
import { ICREATE3Factory } from "lib/create3-factory/ICREATE3Factory.sol";
import { vETH } from "src/L2Slpx/vETH.sol";
import { vDOT } from "src/L2Slpx/vDOT.sol";
import { DOT } from "src/L2Slpx/DOT.sol";

contract SetupAllContracts is Script {
    function run() external {
        /// @dev declare the address of the owner
        address l2SlpxAddress = 0x85bb6d27571C3175c81fe212c0decCA2202147b9;
        address vETHAddress = 0x7f6708716FDDFA4c2674eFa4ee20deF1b4d5C5aD;
        address vDOTAddress = 0x5fD7476f615C53929922130DC8bf297e1a011f75;
        address DOTAddress = 0x61E214E7d4DF2e619AF3F2eF4E590ABa4480259F;
        uint256 MIN_ETH_ORDER_AMOUNT = 0.001 ether;
        uint256 ETH_TO_VETH_TOKEN_CONVERSION_RATE = 0.898e18;
        uint256 ETH_ORDER_FEE = 0.01e18;
        uint256 MIN_DOT_ORDER_AMOUNT = 1 ether;
        uint256 DOT_TO_VDOT_TOKEN_CONVERSION_RATE = 0.6646e18;
        uint256 DOT_ORDER_FEE = 0.01e18;

        console.log("Starting setup");
        /// @dev start the broadcast
        vm.startBroadcast();

        L2Slpx(l2SlpxAddress).setTokenConversionInfo(address(0), L2Slpx.Operation.Mint, MIN_ETH_ORDER_AMOUNT, ETH_TO_VETH_TOKEN_CONVERSION_RATE, ETH_ORDER_FEE, vETHAddress);
        L2Slpx(l2SlpxAddress).setTokenConversionInfo(DOTAddress, L2Slpx.Operation.Mint, MIN_DOT_ORDER_AMOUNT, DOT_TO_VDOT_TOKEN_CONVERSION_RATE, DOT_ORDER_FEE, vDOTAddress);
        L2Slpx(l2SlpxAddress).setTokenConversionInfo(vETHAddress, L2Slpx.Operation.Redeem, MIN_ETH_ORDER_AMOUNT, ETH_TO_VETH_TOKEN_CONVERSION_RATE, ETH_ORDER_FEE, address(0));
        L2Slpx(l2SlpxAddress).setTokenConversionInfo(vDOTAddress, L2Slpx.Operation.Redeem, MIN_DOT_ORDER_AMOUNT, DOT_TO_VDOT_TOKEN_CONVERSION_RATE, DOT_ORDER_FEE, DOTAddress);

        vm.stopBroadcast();
        console.log("Setup completed");
    }
}