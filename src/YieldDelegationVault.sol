// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import {L2Slpx} from "src/L2Slpx/L2Slpx.sol";
import {vDOT} from "src/L2Slpx/vDOT.sol";
import {vETH} from "src/L2Slpx/vETH.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract YieldDelegationVault is Ownable {

    L2Slpx public immutable l2Slpx;
    vDOT public immutable vdot;
    vETH public immutable veth;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initialize the contract
    /// @param _owner The owner of the contract
    /// @param _l2Slpx The address of the L2Slpx contract
    /// @param _vDOT The address of the vDOT contract
    /// @param _vETH the address of the vETH contract
    constructor(address _owner, address _l2Slpx, address _vDOT, address _vETH) Ownable(_owner) {
        l2Slpx = L2Slpx(_l2Slpx);
        vdot = vDOT(_vDOT);
        veth = vETH(_vETH);
    }

    /*//////////////////////////////////////////////////////////////
                            CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit tokens into the vault
    /// @param tokenAddress The address of the token
    /// @param amount The amount of the token
    function deposit(address tokenAddress, uint256 amount) public payable {
        if (tokenAddress == address(0)) {
            if (msg.value < amount) revert InsufficientBalance();
        } else {
            if (IVToken(tokenAddress).balanceOf(msg.sender) < amount) revert InsufficientBalance();
        }
    }

    /// @notice Withdraw tokens from the vault
    /// @param tokenAddress The address of the token
    /// @param amount The amount of the token
    function withdraw(address tokenAddress, uint256 amount) public {
        if (tokenAddress == address(0)) {
            if (address(this).balance < amount) revert InsufficientBalance();
        } else {
            if (IVToken(tokenAddress).balanceOf(address(this)) < amount) revert InsufficientBalance();
        }
    }

    /// @notice Withdraw yield from the vault for the owner
    /// @dev This function is only callable by the owner
    function ownerWithdrawYield() public onlyOwner {
        l2Slpx.withdrawFees(address(vdot));
        l2Slpx.withdrawFees(address(veth));
    }
}