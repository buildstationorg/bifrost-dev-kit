// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

interface YieldDelegationVault {
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

    error InsufficientShares();
    error InvalidTokenAddress();
    error NotDepositor();
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);

    event Deposit(
        address indexed user,
        uint256 depositId,
        address tokenAddress,
        uint256 depositedAmount,
        uint256 depositConversionRate
    );
    event OwnerWithdrawYield(address indexed tokenAddress, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Withdraw(
        address indexed user,
        uint256 depositId,
        address tokenAddress,
        uint256 withdrawnAmount,
        uint256 withdrawalConversionRate
    );

    function addressToDepositorRecord(address) external view returns (uint256 totalNumberOfDeposits);
    function currentDepositId() external view returns (uint256);
    function deposit(address tokenAddress, uint256 amount) external payable;
    function depositIdToDepositRecord(uint256)
        external
        view
        returns (
            uint256 depositId,
            uint256 indexInDepositorRecord,
            address depositor,
            address tokenAddress,
            uint256 amountDeposited,
            uint256 depositConversionRate
        );
    function getDepositorRecord(address depositor) external view returns (DepositorRecord memory);
    function getVaultDepositRecord(uint256 depositId) external view returns (VaultDepositRecord memory);
    function l2Slpx() external view returns (address);
    function owner() external view returns (address);
    function ownerWithdrawYield(address tokenAddress) external;
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function vdot() external view returns (address);
    function veth() external view returns (address);
    function withdraw(uint256 depositId) external;
}
