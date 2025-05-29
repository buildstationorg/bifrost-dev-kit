// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IL2Slpx {
    type Operation is uint8;

    struct TokenConversionInfo {
        Operation operation;
        uint256 minOrderAmount;
        uint256 tokenConversionRate;
        uint256 orderFee;
        address outputTokenAddress;
    }

    error ETHTransferFailed();
    error InsufficientApproval();
    error InsufficientBalance();
    error InsufficientVTokenBalance();
    error InvalidMinOrderAmount();
    error InvalidOperation();
    error InvalidOrderAmount();
    error InvalidTokenAddress();
    error InvalidTokenConversionRate();
    error InvalidTokenFee();
    error InvalidVTokenAddress();
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);

    event CreateOrder(address tokenAddress, Operation operation, uint256 amount, string remark);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function addressToTokenConversionInfo(address)
        external
        view
        returns (
            Operation operation,
            uint256 minOrderAmount,
            uint256 tokenConversionRate,
            uint256 orderFee,
            address outputTokenAddress
        );
    function checkSupportToken(address tokenAddress) external view returns (bool);
    function createOrder(address tokenAddress, uint256 amount, Operation operation, string memory remark)
        external
        payable;
    function getTokenConversionInfo(address tokenAddress) external view returns (TokenConversionInfo memory);
    function owner() external view returns (address);
    function removeTokenConversionInfo(address tokenAddress) external;
    function renounceOwnership() external;
    function setTokenConversionInfo(
        address tokenAddress,
        Operation operation,
        uint256 minOrderAmount,
        uint256 tokenConversionRate,
        uint256 orderFee,
        address outputTokenAddress
    ) external;
    function transferOwnership(address newOwner) external;
    function withdrawFees(address tokenAddress) external;
}
