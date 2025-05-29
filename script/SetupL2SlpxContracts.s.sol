// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { L2Slpx } from "src/L2Slpx/L2Slpx.sol";

contract SetupL2SlpxContracts is Script {
    function run() external {
        /// @dev declare addresses of the contracts
        /// @dev L2Slpx contract address
        address l2SlpxAddress = 0xC4F238cEdC1f77A0Fe36F60eceDef14336e4eFbe;
        /// @dev vETH contract address
        address vETHAddress = 0x66f039Bc124A3f45D3b30BFdD903B72a4857878f;
        /// @dev vDOT contract address
        address vDOTAddress = 0x1Ed8c557791e0c98D72387423ab5c215d358E5a4;
        /// @dev DOT contract address
        address DOTAddress = 0x1dB58359534600b08Fe7061608920f1C47E7b0b0;

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