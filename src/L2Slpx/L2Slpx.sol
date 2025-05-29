// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVToken} from "src/L2Slpx/IVToken.sol";

contract L2Slpx is Ownable {
    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/
    error InvalidTokenAddress();
    error InvalidMinOrderAmount();
    error InvalidTokenConversionRate();
    error InvalidTokenFee();
    error InvalidVTokenAddress();
    error InvalidOperation();
    error InvalidOrderAmount();
    error InsufficientBalance();
    error InsufficientApproval();
    error InsufficientVTokenBalance();
    error ETHTransferFailed();


    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    event CreateOrder(address tokenAddress, Operation operation, uint256 amount, string remark);


    /*//////////////////////////////////////////////////////////////
                            STRUCTS & ENUMS
    //////////////////////////////////////////////////////////////*/
    enum Operation {
        Mint,
        Redeem
    }

    struct TokenConversionInfo {
        Operation operation;
        uint256 minOrderAmount;
        uint256 tokenConversionRate;
        uint256 orderFee; // 1e18 = 100%, 1e16 = 1%, 1e15 = 0.1%
        address outputTokenAddress;
    }

    /*//////////////////////////////////////////////////////////////
                            MAPPINGS
    //////////////////////////////////////////////////////////////*/
    mapping(address => TokenConversionInfo) public addressToTokenConversionInfo;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initialize the contract
    /// @param _owner The owner of the contract
    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////
                            CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Create an order
    /// @param tokenAddress The address of the token
    /// @param amount The amount of the order
    /// @param operation The operation of the order
    /// @param remark The remark of the order
    function createOrder(address tokenAddress, uint256 amount, Operation operation, string memory remark)
        public
        payable
    {
        // Checks
        if (!checkSupportToken(tokenAddress)) revert InvalidTokenAddress();
        if (amount < addressToTokenConversionInfo[tokenAddress].minOrderAmount) revert InvalidOrderAmount();
        if (operation != addressToTokenConversionInfo[tokenAddress].operation) revert InvalidOperation();
        
        if (tokenAddress == address(0)) {
            // Handle native ETH
            if (msg.value < amount) revert InsufficientBalance();
        } else {
            if (IVToken(tokenAddress).balanceOf(msg.sender) < amount) revert InsufficientBalance();
            if (IVToken(tokenAddress).allowance(msg.sender, address(this)) < amount) revert InsufficientApproval();
        }

        // Effects
        if (operation == Operation.Mint) {
            if (tokenAddress == address(0)) {
                // Native ETH comes with the msg.value
                uint256 fee = (msg.value * addressToTokenConversionInfo[tokenAddress].orderFee) / 1e18;
                uint256 amountAfterFee = msg.value - fee;
                uint256 vTokenAmount = amountAfterFee * addressToTokenConversionInfo[tokenAddress].tokenConversionRate / 1e18;
                IVToken(addressToTokenConversionInfo[tokenAddress].outputTokenAddress).mint(msg.sender, vTokenAmount);
            } else {
                uint256 fee = (amount * addressToTokenConversionInfo[tokenAddress].orderFee) / 1e18;
                uint256 amountAfterFee = amount - fee;
                IVToken(tokenAddress).transferFrom(msg.sender, address(this), amount);
                uint256 vTokenAmount = amountAfterFee * addressToTokenConversionInfo[tokenAddress].tokenConversionRate / 1e18;
                IVToken(addressToTokenConversionInfo[tokenAddress].outputTokenAddress).mint(msg.sender, vTokenAmount);
            }
        }

        if (operation == Operation.Redeem) {
            uint256 fee = (amount * addressToTokenConversionInfo[tokenAddress].orderFee) / 1e18;
            uint256 amountAfterFee = amount - fee;
            uint256 tokenAmount = (amountAfterFee * 1e18) / addressToTokenConversionInfo[tokenAddress].tokenConversionRate;
            IVToken(tokenAddress).transferFrom(msg.sender, address(this), amount);
            IVToken(tokenAddress).burn(amount);
            if (addressToTokenConversionInfo[tokenAddress].outputTokenAddress == address(0)) {
                (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                if (!success) revert ETHTransferFailed();
            } else {
                IVToken(addressToTokenConversionInfo[tokenAddress].outputTokenAddress).transfer(msg.sender, tokenAmount);
            }
        }
        
        emit CreateOrder(tokenAddress, operation, amount, remark);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN SETTERS
    //////////////////////////////////////////////////////////////*/

    function setTokenConversionInfo(
        address tokenAddress,
        Operation operation,
        uint256 minOrderAmount,
        uint256 tokenConversionRate,
        uint256 orderFee,  // 1e18 = 100%, 1e16 = 1%, 1e15 = 0.1%
        address outputTokenAddress
    ) public onlyOwner {
        if (minOrderAmount <= 0) revert InvalidMinOrderAmount();
        if (tokenConversionRate <= 0) revert InvalidTokenConversionRate();
        if (orderFee > 1e18) revert InvalidTokenFee();  // Cannot be more than 100%
        if (operation != Operation.Mint && operation != Operation.Redeem) revert InvalidOperation();
        addressToTokenConversionInfo[tokenAddress] = TokenConversionInfo(operation, minOrderAmount, tokenConversionRate, orderFee, outputTokenAddress);
    }

    function removeTokenConversionInfo(address tokenAddress) external onlyOwner {
        delete addressToTokenConversionInfo[tokenAddress];
    }

    function withdrawFees(address tokenAddress) external onlyOwner {
    if (tokenAddress == address(0)) {
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) revert ETHTransferFailed();
    } else {
        IVToken(tokenAddress).transfer(owner(), IVToken(tokenAddress).balanceOf(address(this)));
    }
}

    /*//////////////////////////////////////////////////////////////
                            SUPPORT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Check if the token is supported
    /// @param tokenAddress The address of the token
    /// @return true if the token is supported, false otherwise
    function checkSupportToken(address tokenAddress) public view returns (bool) {
        TokenConversionInfo memory tokenConversionInfo = addressToTokenConversionInfo[tokenAddress];
        return tokenConversionInfo.minOrderAmount > 0 && tokenConversionInfo.tokenConversionRate > 0
            && tokenConversionInfo.orderFee <= 1e18;  // Cannot be more than 100%
    }

    /// @notice Get the token conversion info
    /// @param tokenAddress The address of the token
    /// @return The token conversion info
    function getTokenConversionInfo(address tokenAddress) public view returns (TokenConversionInfo memory) {
        return addressToTokenConversionInfo[tokenAddress];
    }
}