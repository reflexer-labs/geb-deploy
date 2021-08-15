pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-weth/weth9.sol";
import {DSToken} from "ds-token/token.sol";

import "geb/SAFEEngine.sol";

import {CollateralJoin6} from "../AdvancedTokenAdapters.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract FakeUser {
    function doApprove(address token, address guy, uint amount) public {
        DSToken(token).approve(guy, amount);
    }

    function doJoin(address obj, address safe, uint wad) public {
        CollateralJoin6(obj).join(safe, wad);
    }

    function doExit(address obj, address guy, uint wad) public {
        CollateralJoin6(obj).exit(guy, wad);
    }

    function doTransferCollateral(address obj, bytes32 collateralType, address src, address dst, uint wad) public {
        SAFEEngine(obj).transferCollateral(
            collateralType,
            src,
            dst,
            wad
        );
    }
}

contract CollateralJoin6Test is DSTest {
    Hevm hevm;

    FakeUser alice;

    WETH9_ weth;

    SAFEEngine safeEngine;
    CollateralJoin6 collateralJoin;

    bytes32 collateralType = bytes32("ETH-A");
    uint256 wethAmount     = 1000 ether;

    function setUp() virtual public {
        safeEngine = new SAFEEngine();

        weth = new WETH9_();
        weth.deposit{value: wethAmount}();

        collateralJoin = new CollateralJoin6(address(safeEngine), collateralType, address(weth));

        weth.approve(address(collateralJoin), uint(-1));
        safeEngine.initializeCollateralType(collateralType);
        safeEngine.addAuthorization(address(collateralJoin));

        alice = new FakeUser();
        weth.transfer(address(alice), wethAmount / 2);
    }

    function test_correct_setup() public {
        assertEq(collateralJoin.allowance(address(this)), 0);
        assertTrue(address(collateralJoin.safeEngine()) == address(safeEngine));
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
    function testFail_join_when_zero_allowance() public {
        collateralJoin.join(address(this), 1);
    }
    function test_exit_when_zero_allowance() public {
        collateralJoin.setAllowance(address(this), 1 ether);
        collateralJoin.join(address(this), 1 ether);
        collateralJoin.setAllowance(address(this), 0);
        collateralJoin.exit(address(this), 1 ether);
        assertEq(weth.balanceOf(address(this)), wethAmount / 2);
    }
    function test_exit_when_positive_allowance() public {
        collateralJoin.setAllowance(address(this), 1 ether);
        collateralJoin.join(address(this), 1 ether);
        collateralJoin.exit(address(this), 1 ether);
        assertEq(weth.balanceOf(address(this)), wethAmount / 2);
    }
    function test_exit_when_negative_collateral_joined() public {
        collateralJoin.setAllowance(address(alice), 1 ether);
        alice.doApprove(address(weth), address(collateralJoin), uint(-1));
        alice.doJoin(address(collateralJoin), address(alice), 1 ether);
        alice.doTransferCollateral(
          address(safeEngine),
          collateralType,
          address(alice),
          address(this),
          1 ether
        );
        collateralJoin.exit(address(this), 0.5 ether);
        collateralJoin.exit(address(this), 0.5 ether);
        assertEq(weth.balanceOf(address(this)), wethAmount / 2 + uint(1 ether));
        assertEq(collateralJoin.collateralJoined(address(this)), 0);
    }
    function test_exit_when_positive_collateral_joined() public {
        collateralJoin.setAllowance(address(this), 1 ether);
        collateralJoin.join(address(this), 1 ether);
        assertEq(collateralJoin.collateralJoined(address(this)), 1 ether);
        collateralJoin.exit(address(this), 1 ether);
        assertEq(weth.balanceOf(address(this)), wethAmount / 2);
    }
    function testFail_join_above_allowance_positive_balance() public {
        collateralJoin.setAllowance(address(this), 1 ether);
        collateralJoin.join(address(this), 1 ether);
        collateralJoin.join(address(this), 1);
    }
    function testFail_join_when_negative_balance_zero_allowance() public {
        collateralJoin.setAllowance(address(alice), 1 ether);
        alice.doApprove(address(weth), address(collateralJoin), uint(-1));
        alice.doJoin(address(collateralJoin), address(alice), 1 ether);
        alice.doTransferCollateral(
          address(safeEngine),
          collateralType,
          address(alice),
          address(this),
          1 ether
        );
        collateralJoin.exit(address(this), 1 ether);
        collateralJoin.join(address(this), 1 ether);
    }
    function test_join_when_negative_balance_positive_allowance() public {
        collateralJoin.setAllowance(address(alice), 1 ether);
        alice.doApprove(address(weth), address(collateralJoin), uint(-1));
        alice.doJoin(address(collateralJoin), address(alice), 1 ether);
        alice.doTransferCollateral(
          address(safeEngine),
          collateralType,
          address(alice),
          address(this),
          1 ether
        );
        collateralJoin.exit(address(this), 1 ether);
        collateralJoin.setAllowance(address(this), 1 ether);
        collateralJoin.join(address(this), 1 ether);
        assertEq(collateralJoin.collateralJoined(address(this)), 1 ether);
    }
}
