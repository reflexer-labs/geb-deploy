pragma solidity ^0.6.7;

import "ds-test/test.sol";
import "ds-weth/weth9.sol";

import "geb/CDPEngine.sol";

import {CollateralJoin6} from "../AdvancedTokenAdapters.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract CollateralJoin6Test is DSTest {
    Hevm hevm;

    WETH9_ weth;

    CDPEngine cdpEngine;
    CollateralJoin6 collateralJoin;

    bytes32 collateralType = bytes32("ETH-A");
    uint256 wethAmount     = 1000 ether;

    function setUp() virtual public {
        cdpEngine = new CDPEngine();

        weth = new WETH9_();
        weth.deposit{value: wethAmount}();

        collateralJoin = new CollateralJoin6(address(cdpEngine), collateralType, address(weth));

        cdpEngine.initializeCollateralType(collateralType);
        cdpEngine.addAuthorization(address(collateralJoin));
    }

    function test_correct_setup() public {
        assertEq(collateralJoin.allowance(address(this)), 0);
        assertTrue(address(collateralJoin.cdpEngine()) == address(cdpEngine));
        assertTrue(collateralJoin.collateralType() == collateralType);
        assertTrue(address(collateralJoin.collateral()) == address(weth));
        assertEq(collateralJoin.decimals(), 18);
        assertEq(collateralJoin.allowed(), 0);
        assertEq(collateralJoin.contractEnabled(), 1);
    }
    function test_set_positive_allowance_when_zero() public {
        collateralJoin.setAllowance(address(0x123), 1 ether);
        assertEq(collateralJoin.allowance(address(0x123)), 1 ether);
    }
    function test_set_positive_allowance_when_positive() public {
        collateralJoin.setAllowance(address(0x123), 1 ether);
        assertEq(collateralJoin.allowance(address(0x123)), 1 ether);

        collateralJoin.setAllowance(address(0x123), 10 ether);
        assertEq(collateralJoin.allowance(address(0x123)), 10 ether);

        collateralJoin.setAllowance(address(0x123), 0);
        assertEq(collateralJoin.allowance(address(0x123)), 0);
    }
    // function testFail_join_when_zero_allowance() public {
    //
    // }
    // function test_exit_when_zero_allowance() public {
    //
    // }
    // function test_exit_when_positive_allowance() public {
    //
    // }
    // function test_exit_when_negative_collateral_joined() public {
    //
    // }
    // function test_exit_when_positive_collateral_joined() public {
    //
    // }
    // function test_exit_when_zero_collateral_joined() public {
    //
    // }
    // function test_join_above_allowance_zero_balance() public {
    //
    // }
    // function test_join_above_allowance_positive_balance() public {
    //
    // }
    // function testFail_join_when_negative_zero_allowance() public {
    //
    // }
    // function test_join_when_negative_positive_allowance() public {
    //
    // }
}
