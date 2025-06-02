// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console } from "forge-std/Script.sol";
import { YieldDelegationVault } from "src/YieldDelegationVault.sol";

contract DeployYieldDelegationVault is Script {
    function run() external returns (address yieldDelegationVaultAddress) {
        /// @dev declare the address of the owner
        address OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;
        address l2SlpxAddress = 0xC4F238cEdC1f77A0Fe36F60eceDef14336e4eFbe;
        address vETHAddress = 0x66f039Bc124A3f45D3b30BFdD903B72a4857878f;
        address vDOTAddress = 0x1Ed8c557791e0c98D72387423ab5c215d358E5a4;

        /// @dev start the broadcast
        vm.startBroadcast();
        /// @dev deploy the contracts
        
        console.log("Deploying YieldDelegationVault contract");
        /// @dev deploy the YieldDelegationVault contract
        YieldDelegationVault yieldDelegationVault = new YieldDelegationVault(OWNER, l2SlpxAddress, vETHAddress, vDOTAddress, 0.001 ether);
        /// @dev get the address of the YieldDelegationVault contract
        yieldDelegationVaultAddress = address(yieldDelegationVault);
        console.log("YieldDelegationVault contract deployed at", yieldDelegationVaultAddress);

        /// @dev stop the broadcast
        vm.stopBroadcast();

        /// @dev return the addresses
        return (yieldDelegationVaultAddress);
    }
}