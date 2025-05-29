// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { L2Slpx } from "src/L2Slpx/L2Slpx.sol";

contract SetupL2SlpxContracts is Script {
    function run() external {
        /// @dev declare addresses of the contracts
        /// @dev L2Slpx contract address
        address l2SlpxAddress = 0x62CA64454046BbC18e35066A6350Acb0378EB3c2;
        /// @dev vETH contract address
        address vETHAddress = 0x0E011f93777B00f48B881B1Cabc5F0A6395BdC02;
        /// @dev vDOT contract address
        address vDOTAddress = 0x6C0AAb3F91C4e49F6442CCEb65973778Ab0A177A;
        /// @dev DOT contract address
        address DOTAddress = 0x3A8EDecAb3E4178f06dD57be13676195571fEA2f;

        /// @dev declare the token conversion info
        uint256 MIN_ETH_ORDER_AMOUNT = 0.001 ether;
        uint256 ETH_TO_VETH_TOKEN_CONVERSION_RATE = 0.898e18;
        uint256 ETH_ORDER_FEE = 0.01e18;
        uint256 MIN_DOT_ORDER_AMOUNT = 1 ether;
        uint256 DOT_TO_VDOT_TOKEN_CONVERSION_RATE = 0.6646e18;
        uint256 DOT_ORDER_FEE = 0.01e18;

        console.log("Starting setup");
        /// @dev start the broadcast
        vm.startBroadcast();

        /// @dev set the token conversion info
        L2Slpx(l2SlpxAddress).setTokenConversionInfo(address(0), L2Slpx.Operation.Mint, MIN_ETH_ORDER_AMOUNT, ETH_TO_VETH_TOKEN_CONVERSION_RATE, ETH_ORDER_FEE, vETHAddress);
        L2Slpx(l2SlpxAddress).setTokenConversionInfo(DOTAddress, L2Slpx.Operation.Mint, MIN_DOT_ORDER_AMOUNT, DOT_TO_VDOT_TOKEN_CONVERSION_RATE, DOT_ORDER_FEE, vDOTAddress);
        L2Slpx(l2SlpxAddress).setTokenConversionInfo(vETHAddress, L2Slpx.Operation.Redeem, MIN_ETH_ORDER_AMOUNT, ETH_TO_VETH_TOKEN_CONVERSION_RATE, ETH_ORDER_FEE, address(0));
        L2Slpx(l2SlpxAddress).setTokenConversionInfo(vDOTAddress, L2Slpx.Operation.Redeem, MIN_DOT_ORDER_AMOUNT, DOT_TO_VDOT_TOKEN_CONVERSION_RATE, DOT_ORDER_FEE, DOTAddress);

        /// @dev stop the broadcast
        vm.stopBroadcast();
        console.log("Setup completed");
    }
}