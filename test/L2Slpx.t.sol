// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {L2Slpx} from "src/L2Slpx/L2Slpx.sol";
import {vETH} from "src/L2Slpx/vETH.sol";
import {vDOT} from "src/L2Slpx/vDOT.sol";
import {DOT} from "src/L2Slpx/DOT.sol";
import {Test, console} from "forge-std/Test.sol";

contract L2SlpxTest is Test {
    address public constant OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;
    address public constant USER = 0xe3d25540BA6CED36a0ED5ce899b99B5963f43d3F;
    address public constant DOT_OWNER = 0x6FaFF29226219756aa40CE648dbc65FB41DE5F72;
    uint256 public constant MIN_ETH_ORDER_AMOUNT = 0.001 ether;
    uint256 public constant ETH_TO_VETH_TOKEN_CONVERSION_RATE = 0.8e18;
    uint256 public constant ETH_ORDER_FEE = 0.01e18;
    uint256 public constant MIN_DOT_ORDER_AMOUNT = 1 ether;
    uint256 public constant DOT_TO_VDOT_TOKEN_CONVERSION_RATE = 0.7e18;
    uint256 public constant DOT_ORDER_FEE = 0.01e18;

    L2Slpx public l2Slpx;
    vETH public veth;
    vDOT public vdot;
    DOT public dot;

    function setUp() public {
        l2Slpx = new L2Slpx(OWNER);
        veth = new vETH(address(l2Slpx));
        vdot = new vDOT(address(l2Slpx));
        dot = new DOT(DOT_OWNER);
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

    function test_createOrderETH() public {
        vm.startPrank(USER);
        l2Slpx.createOrder{value: 1 ether}(address(0), 1 ether, L2Slpx.Operation.Mint, "bifrost");
        vm.stopPrank();
        assertEq(veth.balanceOf(USER), 0.792e18);
    }

    function test_createOrderERC20() public {
        vm.startPrank(USER);
        dot.approve(address(l2Slpx), 10e18);
        l2Slpx.createOrder(address(dot), 10e18, L2Slpx.Operation.Mint, "bifrost");
        vm.stopPrank();
        assertEq(vdot.balanceOf(USER), 6.93e18);
    }

    function test_createOrderETH_Redeem() public {
        vm.startPrank(USER);
        l2Slpx.createOrder{value: 1 ether}(address(0), 1 ether, L2Slpx.Operation.Mint, "bifrost");
        assertEq(veth.balanceOf(USER), 0.792e18);
        veth.approve(address(l2Slpx), veth.balanceOf(USER));
        l2Slpx.createOrder(address(veth), veth.balanceOf(USER), L2Slpx.Operation.Redeem, "bifrost");
        assertEq(veth.balanceOf(USER), 0);
        assertEq(address(USER).balance, 999 ether + 0.9801 ether);
        vm.stopPrank();
    }

    function test_createOrderERC20_Redeem() public {
        vm.startPrank(USER);
        dot.approve(address(l2Slpx), 10e18);
        l2Slpx.createOrder(address(dot), 10e18, L2Slpx.Operation.Mint, "bifrost");
        assertEq(vdot.balanceOf(USER), 6.93e18);
        vdot.approve(address(l2Slpx), vdot.balanceOf(USER));
        l2Slpx.createOrder(address(vdot), vdot.balanceOf(USER), L2Slpx.Operation.Redeem, "bifrost");
        vm.stopPrank();
        assertEq(vdot.balanceOf(USER), 0);
        assertEq(dot.balanceOf(USER), 9990 ether + 9.801e18);
    }
    
    function test_checkSupportToken() public view {
        assertTrue(l2Slpx.checkSupportToken(address(0)));
        assertTrue(l2Slpx.checkSupportToken(address(dot)));
    }

    function test_getTokenConversionInfoETH() public view {
        L2Slpx.TokenConversionInfo memory tokenConversionInfo = l2Slpx.getTokenConversionInfo(address(0));
        assertEq(tokenConversionInfo.minOrderAmount, 0.001 ether);
        assertEq(tokenConversionInfo.tokenConversionRate, 0.8e18);
        assertEq(tokenConversionInfo.orderFee, 0.01e18);
    }

    function test_getTokenConversionInfoERC20() public view {
        L2Slpx.TokenConversionInfo memory tokenConversionInfo = l2Slpx.getTokenConversionInfo(address(dot));
        assertEq(tokenConversionInfo.minOrderAmount, 1 ether);
        assertEq(tokenConversionInfo.tokenConversionRate, 0.7e18);
        assertEq(tokenConversionInfo.orderFee, 0.01e18);
    }

    function test_removeTokenConversionInfo() public {
        vm.startPrank(OWNER);
        l2Slpx.removeTokenConversionInfo(address(0));
        vm.stopPrank();
        L2Slpx.TokenConversionInfo memory tokenConversionInfo = l2Slpx.getTokenConversionInfo(address(0));
        assertEq(tokenConversionInfo.minOrderAmount, 0);
    }
}                   