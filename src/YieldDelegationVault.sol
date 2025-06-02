// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {L2Slpx} from "src/L2Slpx/L2Slpx.sol";
import {vDOT} from "src/L2Slpx/vDOT.sol";
import {vETH} from "src/L2Slpx/vETH.sol";

contract YieldDelegationVault is Ownable {

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/
    error InvalidTokenAddress();
    error InsufficientShares();
    error NotDepositor();
    error InvalidDepositId();
    error InsufficientDepositAmount();


    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed user, uint256 depositId, address tokenAddress, uint256 depositedAmount, uint256 depositConversionRate);
    event Withdraw(address indexed user, uint256 depositId, address tokenAddress, uint256 withdrawnAmount, uint256 withdrawalConversionRate);
    event OwnerWithdrawYield(address indexed owner, address tokenAddress, uint256 yield, uint256 withdrawalConversionRate);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    L2Slpx public immutable l2Slpx;
    vDOT public immutable vdot;
    vETH public immutable veth;
    uint256 public currentDepositId;
    uint256 public minimumDepositAmount;
    uint256 public totalAmountOfEthDeposited;
    uint256 public totalAmountOfDotDeposited;


    /*//////////////////////////////////////////////////////////////
                            STRUCTS & ENUMS
    //////////////////////////////////////////////////////////////*/

    struct DepositorRecord {
        uint256[] depositIds;
        uint256 totalNumberOfDeposits;
    }

    struct VaultDepositRecord {
        uint256 depositId;
        uint256 indexInDepositorRecord;
        address depositor;
        address tokenAddress;
        uint256 amountDeposited;
        uint256 depositConversionRate;
    }


    /*//////////////////////////////////////////////////////////////
                            MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => DepositorRecord) public addressToDepositorRecord;
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
        if (amount < minimumDepositAmount) revert InsufficientDepositAmount();
        if (tokenAddress == address(veth)) {
            veth.transferFrom(msg.sender, address(this), amount);
            uint256 depositConversionRate = l2Slpx.getTokenConversionInfo(address(veth)).tokenConversionRate;
            addressToDepositorRecord[msg.sender].depositIds.push(currentDepositId);
            addressToDepositorRecord[msg.sender].totalNumberOfDeposits++;
            depositIdToDepositRecord[currentDepositId] = VaultDepositRecord({
                depositId: currentDepositId,
                indexInDepositorRecord: addressToDepositorRecord[msg.sender].totalNumberOfDeposits - 1,
                depositor: msg.sender,
                tokenAddress: address(veth),
                amountDeposited: amount,
                depositConversionRate: depositConversionRate
            });
            totalAmountOfEthDeposited += amount * 1e18 / depositConversionRate;
            emit Deposit(msg.sender, currentDepositId, address(veth), amount, depositConversionRate);
            currentDepositId++;
        }

        if (tokenAddress == address(vdot)) {
            vdot.transferFrom(msg.sender, address(this), amount);
            uint256 depositConversionRate = l2Slpx.getTokenConversionInfo(address(vdot)).tokenConversionRate;
            addressToDepositorRecord[msg.sender].depositIds.push(currentDepositId);
            addressToDepositorRecord[msg.sender].totalNumberOfDeposits++;
            depositIdToDepositRecord[currentDepositId] = VaultDepositRecord({
                depositId: currentDepositId,
                indexInDepositorRecord: addressToDepositorRecord[msg.sender].totalNumberOfDeposits - 1,
                depositor: msg.sender,
                tokenAddress: address(vdot),
                amountDeposited: amount,
                depositConversionRate: depositConversionRate
            });
            totalAmountOfDotDeposited += amount * 1e18 / depositConversionRate;
            emit Deposit(msg.sender, currentDepositId, address(vdot), amount, depositConversionRate);
            currentDepositId++;
        }
    }

    /// @notice Withdraw tokens from the vault
    /// @param depositId The id of the deposit
    function withdraw(uint256 depositId) public {
        VaultDepositRecord memory depositRecord = depositIdToDepositRecord[depositId];
        if (depositRecord.depositor == address(0)) revert InvalidDepositId();
        if (depositRecord.depositor != msg.sender) revert NotDepositor();
        if (depositRecord.tokenAddress == address(veth)) {
            uint256 withdrawalConversionRate = l2Slpx.getTokenConversionInfo(address(veth)).tokenConversionRate;
            uint256 amountOfUnderlyingDeposited = depositRecord.amountDeposited * 1e18 / depositRecord.depositConversionRate;
            uint256 amountToWithdraw = amountOfUnderlyingDeposited * withdrawalConversionRate / 1e18;
            // remove the deposit id from the depositor record
            addressToDepositorRecord[msg.sender].depositIds[depositRecord.indexInDepositorRecord] = addressToDepositorRecord[msg.sender].depositIds[addressToDepositorRecord[msg.sender].totalNumberOfDeposits - 1];
            addressToDepositorRecord[msg.sender].depositIds.pop();
            addressToDepositorRecord[msg.sender].totalNumberOfDeposits--;
            delete depositIdToDepositRecord[depositId];
            // transfer the veth to the user
            veth.transfer(msg.sender, amountToWithdraw);
            emit Withdraw(msg.sender, depositId, depositRecord.tokenAddress, amountToWithdraw, withdrawalConversionRate);
        }
        if (depositRecord.tokenAddress == address(vdot)) {
            uint256 withdrawalConversionRate = l2Slpx.getTokenConversionInfo(address(veth)).tokenConversionRate;
            uint256 amountOfUnderlyingDeposited = depositRecord.amountDeposited * 1e18 / depositRecord.depositConversionRate;
            uint256 amountToWithdraw = amountOfUnderlyingDeposited * withdrawalConversionRate / 1e18;
            // remove the deposit id from the depositor record
            addressToDepositorRecord[msg.sender].depositIds[depositRecord.indexInDepositorRecord] = addressToDepositorRecord[msg.sender].depositIds[addressToDepositorRecord[msg.sender].totalNumberOfDeposits - 1];
            addressToDepositorRecord[msg.sender].depositIds.pop();
            addressToDepositorRecord[msg.sender].totalNumberOfDeposits--;
            delete depositIdToDepositRecord[depositId];
            // transfer the vdot to the user
            vdot.transfer(msg.sender, amountToWithdraw);
            emit Withdraw(msg.sender, depositId, depositRecord.tokenAddress, amountToWithdraw, withdrawalConversionRate);
        }
    }


    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // TODO: Implement ERC721 logic for positions

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/
    function getDepositorRecord(address depositor) public view returns (DepositorRecord memory) {
        return addressToDepositorRecord[depositor];
    }

    function getVaultDepositRecord(uint256 depositId) public view returns (VaultDepositRecord memory) {
        return depositIdToDepositRecord[depositId];
    }


    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw yield from the vault for the owner
    /// @dev This function is only callable by the owner
    function ownerWithdrawYield(address tokenAddress) public onlyOwner {
        if (tokenAddress != address(vdot) && tokenAddress != address(veth)) revert InvalidTokenAddress();
        if (tokenAddress == address(veth)) {
            uint256 withdrawalConversionRate = l2Slpx.getTokenConversionInfo(address(veth)).tokenConversionRate;
            uint256 totalAmountToCoverUnderlying = totalAmountOfEthDeposited * withdrawalConversionRate / 1e18;
            uint256 yield = veth.balanceOf(address(this)) - totalAmountToCoverUnderlying;
            emit OwnerWithdrawYield(msg.sender, address(veth), yield, withdrawalConversionRate);
        }
        if (tokenAddress == address(vdot)) {
            uint256 withdrawalConversionRate = l2Slpx.getTokenConversionInfo(address(vdot)).tokenConversionRate;
            uint256 totalAmountToCoverUnderlying = totalAmountOfDotDeposited * withdrawalConversionRate / 1e18;
            uint256 yield = vdot.balanceOf(address(this)) - totalAmountToCoverUnderlying;
            emit OwnerWithdrawYield(msg.sender, address(vdot), yield, withdrawalConversionRate);
        }
    }

    /// @notice Set the minimum deposit amount
    /// @dev This function is only callable by the owner
    /// @param _minimumDepositAmount The new minimum deposit amount
    function setMinimumDepositAmount(uint256 _minimumDepositAmount) public onlyOwner {
        minimumDepositAmount = _minimumDepositAmount;
    } 
}