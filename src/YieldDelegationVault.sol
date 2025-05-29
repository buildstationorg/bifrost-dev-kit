// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {L2Slpx} from "src/L2Slpx/L2Slpx.sol";
import {vDOT} from "src/L2Slpx/vDOT.sol";
import {vETH} from "src/L2Slpx/vETH.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YieldDelegationVault is Ownable {

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/
    error InvalidTokenAddress();
    error InsufficientShares();
    error NotDepositor();


    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed user, uint256 depositId, address tokenAddress, uint256 depositedAmount, uint256 depositConversionRate);
    event Withdraw(address indexed user, uint256 depositId, address tokenAddress, uint256 withdrawnAmount, uint256 withdrawalConversionRate);
    event OwnerWithdrawYield(address indexed tokenAddress, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    L2Slpx public immutable l2Slpx;
    vDOT public immutable vdot;
    vETH public immutable veth;
    uint256 public currentDepositId;


    /*//////////////////////////////////////////////////////////////
                            STRUCTS & ENUMS
    //////////////////////////////////////////////////////////////*/

    struct VaultDepositRecord {
        uint256 depositId;
        address depositor;
        address tokenAddress;
        uint256 amountDeposited;
        uint256 depositConversionRate;
    }


    /*//////////////////////////////////////////////////////////////
                            MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256[]) public addressToDepositIds;
    mapping(uint256 => VaultDepositRecord) public depositIdToDepositRecord;
    


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
        if (tokenAddress != address(vdot) && tokenAddress != address(veth)) revert InvalidTokenAddress();
        
        if (tokenAddress == address(veth)) {
            veth.transferFrom(msg.sender, address(this), amount);
            uint256 depositConversionRate = l2Slpx.getTokenConversionInfo(address(veth)).tokenConversionRate;
            addressToDepositIds[msg.sender].push(currentDepositId);
            depositIdToDepositRecord[currentDepositId] = VaultDepositRecord({
                depositId: currentDepositId,
                depositor: msg.sender,
                tokenAddress: address(veth),
                amountDeposited: amount,
                depositConversionRate: depositConversionRate
            });
            currentDepositId++;
            emit Deposit(msg.sender, currentDepositId, address(veth), amount, depositConversionRate);
        }

        if (tokenAddress == address(vdot)) {
            vdot.transferFrom(msg.sender, address(this), amount);
            uint256 depositConversionRate = l2Slpx.getTokenConversionInfo(address(vdot)).tokenConversionRate;
            addressToDepositIds[msg.sender].push(currentDepositId);
            depositIdToDepositRecord[currentDepositId] = VaultDepositRecord({
                depositId: currentDepositId,
                depositor: msg.sender,
                tokenAddress: address(vdot),
                amountDeposited: amount,
                depositConversionRate: depositConversionRate
            });
            currentDepositId++;
            emit Deposit(msg.sender, currentDepositId, address(vdot), amount, depositConversionRate);
        }
    }

    /// @notice Withdraw tokens from the vault
    /// @param depositId The id of the deposit
    function withdraw(uint256 depositId) public {
        VaultDepositRecord memory depositRecord = depositIdToDepositRecord[depositId];
        if (depositRecord.depositor != msg.sender) revert NotDepositor();
        if (depositRecord.tokenAddress == address(veth)) {
            uint256 withdrawalConversionRate = l2Slpx.getTokenConversionInfo(address(veth)).tokenConversionRate;
            uint256 amountOfUnderlyingDeposited = depositRecord.amountDeposited * 1e18 / depositRecord.depositConversionRate;
            uint256 amountToWithdraw = amountOfUnderlyingDeposited * withdrawalConversionRate / 1e18;
            veth.transfer(msg.sender, amountToWithdraw);
        }
        if (depositRecord.tokenAddress == address(vdot)) {
            uint256 withdrawalConversionRate = l2Slpx.getTokenConversionInfo(address(veth)).tokenConversionRate;
            uint256 amountOfUnderlyingDeposited = depositRecord.amountDeposited * 1e18 / depositRecord.depositConversionRate;
            uint256 amountToWithdraw = amountOfUnderlyingDeposited * withdrawalConversionRate / 1e18;
            vdot.transfer(msg.sender, amountToWithdraw);
            emit Withdraw(msg.sender, depositId, depositRecord.tokenAddress, amountToWithdraw, withdrawalConversionRate);
        }
    }


    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // TODO: Implement ERC721 logic for positions


    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw yield from the vault for the owner
    /// @dev This function is only callable by the owner
    function ownerWithdrawYield(address tokenAddress) public onlyOwner {
        if (tokenAddress != address(vdot) && tokenAddress != address(veth)) revert InvalidTokenAddress();
        if (tokenAddress == address(veth)) {
            veth.transfer(msg.sender, veth.balanceOf(address(this)));
        }
        if (tokenAddress == address(vdot)) {
            vdot.transfer(msg.sender, vdot.balanceOf(address(this)));
        }
    }
}