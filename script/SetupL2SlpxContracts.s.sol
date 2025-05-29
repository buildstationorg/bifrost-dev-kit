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
        address l2SlpxAddress = 0x62CA64454046BbC18e35066A6350Acb0378EB3c2;
        address vETHAddress = 0x0E011f93777B00f48B881B1Cabc5F0A6395BdC02;
        address vDOTAddress = 0x6C0AAb3F91C4e49F6442CCEb65973778Ab0A177A;
        address DOTAddress = 0x3A8EDecAb3E4178f06dD57be13676195571fEA2f;
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