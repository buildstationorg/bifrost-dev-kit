// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {L2Slpx} from "src/L2Slpx/L2Slpx.sol";
import {vETH} from "src/L2Slpx/vETH.sol";
import {vDOT} from "src/L2Slpx/vDOT.sol";
import {DOT} from "src/L2Slpx/DOT.sol";
import {YieldDelegationVault} from "src/YieldDelegationVault.sol";
import {Test, console} from "forge-std/Test.sol";

contract YieldDelegationVaultTest is Test {
    address public constant OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;
    address public constant USER = 0xe3d25540BA6CED36a0ED5ce899b99B5963f43d3F;
    address public constant DOT_OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;
    uint256 public constant MIN_ETH_ORDER_AMOUNT = 0.001 ether;
    uint256 public constant ETH_TO_VETH_TOKEN_CONVERSION_RATE = 0.8e18;
    uint256 public constant ETH_ORDER_FEE = 0.01e18;
    uint256 public constant MIN_DOT_ORDER_AMOUNT = 1 ether;
    uint256 public constant DOT_TO_VDOT_TOKEN_CONVERSION_RATE = 0.7e18;
    uint256 public constant DOT_ORDER_FEE = 0.01e18;

    YieldDelegationVault public yieldDelegationVault;
    L2Slpx public l2Slpx;
    vETH public veth;
    vDOT public vdot;
    DOT public dot;

    function setUp() public {
        l2Slpx = new L2Slpx(OWNER);
        veth = new vETH(address(l2Slpx));
        vdot = new vDOT(address(l2Slpx));
        dot = new DOT(DOT_OWNER);
        yieldDelegationVault = new YieldDelegationVault(OWNER, address(l2Slpx), address(vdot), address(veth));
        vm.deal(USER, 1000 ether);
        vm.startPrank(DOT_OWNER);
        dot.mint(USER, 10000e18);
        vm.stopPrank();
        vm.startPrank(OWNER);
        l2Slpx.setTokenConversionInfo(address(0), L2Slpx.Operation.Mint, MIN_ETH_ORDER_AMOUNT, ETH_TO_VETH_TOKEN_CONVERSION_RATE, ETH_ORDER_FEE, address(veth));
        l2Slpx.setTokenConversionInfo(address(dot), L2Slpx.Operation.Mint, MIN_DOT_ORDER_AMOUNT, DOT_TO_VDOT_TOKEN_CONVERSION_RATE, DOT_ORDER_FEE, address(vdot));
        l2Slpx.setTokenConversionInfo(address(veth), L2Slpx.Operation.Redeem, MIN_ETH_ORDER_AMOUNT, ETH_TO_VETH_TOKEN_CONVERSION_RATE, ETH_ORDER_FEE, address(0));
        l2Slpx.setTokenConversionInfo(address(vdot), L2Slpx.Operation.Redeem, MIN_DOT_ORDER_AMOUNT, DOT_TO_VDOT_TOKEN_CONVERSION_RATE, DOT_ORDER_FEE, address(dot));
        vm.stopPrank();
    }

    function test_depositVeth() public {
        vm.startPrank(USER);
        l2Slpx.createOrder{value: 10 ether}(address(0), 10 ether, L2Slpx.Operation.Mint, "bifrost");
        // check that the user has the correct balance of veth
        assertEq(veth.balanceOf(USER), 7.92e18);
        // approve the veth to be deposited into the vault
        veth.approve(address(yieldDelegationVault), 1.6 * 1e18);
        // deposit 1.6 veth into the vault
        yieldDelegationVault.deposit(address(veth), 1.6 * 1e18);
        vm.stopPrank();
        // check that the depositor record is correct
        assertEq(yieldDelegationVault.getDepositorRecord(USER).totalNumberOfDeposits, 1);
        // check that the deposit id is correct
        uint256[] memory depositIds = yieldDelegationVault.getDepositorRecord(USER).depositIds;
        uint256[] memory expectedIds = new uint256[](1);
        expectedIds[0] = 0;
        assertEq(depositIds, expectedIds);
        // check that the vault deposit record is correct
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositId, 0);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositor, USER);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).tokenAddress, address(veth));
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).amountDeposited, 1.6 * 1e18);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositConversionRate, 0.8e18);
    }

    function test_multipleDeposits() public {
        vm.startPrank(USER);
        l2Slpx.createOrder{value: 10 ether}(address(0), 10 ether, L2Slpx.Operation.Mint, "bifrost");
        // check that the user has the correct balance of veth
        assertEq(veth.balanceOf(USER), 7.92e18);
        // approve the veth to be deposited into the vault
        veth.approve(address(yieldDelegationVault), 1.6 * 2 * 1e18);
        // deposit 1.6 veth into the vault
        yieldDelegationVault.deposit(address(veth), 1.6 * 1e18);
        // deposit another 1.6 veth into the vault
        yieldDelegationVault.deposit(address(veth), 1.6 * 1e18);
        vm.stopPrank();
        // check that the depositor record is correct
        assertEq(yieldDelegationVault.getDepositorRecord(USER).totalNumberOfDeposits, 2);
        // check that the deposit id is correct
        uint256[] memory depositIds = yieldDelegationVault.getDepositorRecord(USER).depositIds;
        uint256[] memory expectedIds = new uint256[](2);
        expectedIds[0] = 0;
        expectedIds[1] = 1;
        assertEq(depositIds, expectedIds);
        // check that the vault deposit record is correct
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositId, 0);
        assertEq(yieldDelegationVault.getVaultDepositRecord(1).depositId, 1);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositor, USER);
        assertEq(yieldDelegationVault.getVaultDepositRecord(1).depositor, USER);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).tokenAddress, address(veth));
        assertEq(yieldDelegationVault.getVaultDepositRecord(1).tokenAddress, address(veth));
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).amountDeposited, 1.6 * 1e18);
        assertEq(yieldDelegationVault.getVaultDepositRecord(1).amountDeposited, 1.6 * 1e18);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositConversionRate, 0.8e18);
        assertEq(yieldDelegationVault.getVaultDepositRecord(1).depositConversionRate, 0.8e18);
    }

    function test_withdrawVethWithNewConversionRate() public {
        vm.startPrank(USER);
        l2Slpx.createOrder{value: 10 ether}(address(0), 10 ether, L2Slpx.Operation.Mint, "bifrost");
        // check that the user has the correct balance of veth
        assertEq(veth.balanceOf(USER), 7.92e18);
        // approve the veth to be deposited into the vault
        veth.approve(address(yieldDelegationVault), 1.6 * 1e18);
        // deposit 1.6 veth into the vault
        yieldDelegationVault.deposit(address(veth), 1.6 * 1e18);
        // check that the user has the correct balance of veth
        assertEq(veth.balanceOf(USER), 6.32e18);
        vm.stopPrank();
        // check that the depositor record is correct
        assertEq(yieldDelegationVault.getDepositorRecord(USER).totalNumberOfDeposits, 1);
        // check that the deposit id is correct
        uint256[] memory depositIds = yieldDelegationVault.getDepositorRecord(USER).depositIds;
        uint256[] memory expectedIds = new uint256[](1);
        expectedIds[0] = 0;
        assertEq(depositIds, expectedIds);
        // check that the vault deposit record is correct
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositId, 0);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositor, USER);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).tokenAddress, address(veth));
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).amountDeposited, 1.6 * 1e18);
        assertEq(yieldDelegationVault.getVaultDepositRecord(0).depositConversionRate, 0.8e18);

        vm.startPrank(OWNER);
        l2Slpx.setTokenConversionInfo(address(veth), L2Slpx.Operation.Redeem, MIN_ETH_ORDER_AMOUNT, 0.6e18, ETH_ORDER_FEE, address(0));
        vm.stopPrank();

        vm.startPrank(USER);
        yieldDelegationVault.withdraw(0);
        vm.stopPrank();

        // check that the user has the correct balance of veth
        assertEq(veth.balanceOf(USER), 6.32e18 + 1.2e18);
        // check that the depositor record is correct
        assertEq(yieldDelegationVault.getDepositorRecord(USER).totalNumberOfDeposits, 0);
        assertEq(yieldDelegationVault.getDepositorRecord(USER).depositIds.length, 0);
    }

    function test_ownerWithdrawYieldVeth() public {
        vm.startPrank(USER);
        l2Slpx.createOrder{value: 10 ether}(address(0), 10 ether, L2Slpx.Operation.Mint, "bifrost");
        // check that the user has the correct balance of veth
        assertEq(veth.balanceOf(USER), 7.92e18);
        // approve the veth to be deposited into the vault
        veth.approve(address(yieldDelegationVault), 1.6 * 2 * 1e18);
        // deposit 1.6 veth into the vault
        yieldDelegationVault.deposit(address(veth), 1.6 * 1e18);
        // deposit another 1.6 veth into the vault
        yieldDelegationVault.deposit(address(veth), 1.6 * 1e18);
        vm.stopPrank();
        vm.startPrank(OWNER);
        l2Slpx.setTokenConversionInfo(address(veth), L2Slpx.Operation.Redeem, MIN_ETH_ORDER_AMOUNT, 0.6e18, ETH_ORDER_FEE, address(0));
        yieldDelegationVault.ownerWithdrawYield(address(veth));
        vm.stopPrank();
        // check that the user has the correct balance of veth
        assertEq(veth.balanceOf(OWNER), 0.8 * 1e18);
    }
}