// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { L2Slpx } from "src/L2Slpx/L2Slpx.sol";
import { ICREATE3Factory } from "lib/create3-factory/ICREATE3Factory.sol";
import { vETH } from "src/L2Slpx/vETH.sol";
import { vDOT } from "src/L2Slpx/vDOT.sol";
import { DOT } from "src/L2Slpx/DOT.sol";

contract CREATE3Deploy is Script {
    function run() external returns (address l2SlpxAddress, address vETHAddress, address vDOTAddress, address DOTAddress) {
        /// @dev declare the address of the owner
        address OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;
        address DEPLOYER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;

        /// @dev declare the address of the CREATE3Factory contract. The address is the same for Kaia mainnet and
        /// testnet
        address create3FactoryAddress = 0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf;

        /// @dev initialize the ICREATE3Factory interface
        ICREATE3Factory create3Factory = ICREATE3Factory(create3FactoryAddress);

        
        /// @dev get the creation code of the contracts
        bytes memory l2SlpxCreationCode = abi.encodePacked(
            type(L2Slpx).creationCode,
            abi.encode(OWNER)
        );
        /// @dev start the broadcast
        vm.startBroadcast();
        /// @dev get the predicted address of the L2Slpx contract
        l2SlpxAddress = create3Factory.getDeployed(DEPLOYER, bytes32(abi.encodePacked("l2slpx1")));
        /// @dev stop the broadcast
        vm.stopBroadcast();

        bytes memory vETHCreationCode = abi.encodePacked(
            type(vETH).creationCode,
            abi.encode(l2SlpxAddress)
        );
        bytes memory vDOTCreationCode = abi.encodePacked(
            type(vDOT).creationCode,
            abi.encode(l2SlpxAddress)
        );
        bytes memory DOTCreationCode = abi.encodePacked(
            type(DOT).creationCode,
            abi.encode(OWNER)
        );

        /// @dev the salt is the bytes32 of the string
        bytes32 saltL2Slpx = bytes32(abi.encodePacked("l2slpx1"));
        bytes32 saltVETH = bytes32(abi.encodePacked("veth1"));
        bytes32 saltVDOT = bytes32(abi.encodePacked("vdot1"));
        bytes32 saltDOT = bytes32(abi.encodePacked("dot1"));

        console.log("Starting deployment");
        /// @dev start the broadcast
        vm.startBroadcast();
        /// @dev call the deploy function of the CREATE3Factory contract to deploy the Counter contract with the salt
        l2SlpxAddress = create3Factory.deploy(saltL2Slpx, l2SlpxCreationCode);
        /// @dev deploy the vETH contract
        vETHAddress = create3Factory.deploy(saltVETH, vETHCreationCode);
        /// @dev deploy the vDOT contract
        vDOTAddress = create3Factory.deploy(saltVDOT, vDOTCreationCode);
        /// @dev deploy the DOT contract
        DOTAddress = create3Factory.deploy(saltDOT, DOTCreationCode);
        /// @dev stop the broadcast
        vm.stopBroadcast();

        /// @dev return the counterAddress
        return (l2SlpxAddress, vETHAddress, vDOTAddress, DOTAddress);
    }
}