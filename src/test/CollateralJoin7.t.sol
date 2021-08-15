
pragma solidity 0.6.7;

import "ds-test/test.sol";
import {SAFEEngine} from 'geb/SAFEEngine.sol';
import {DSDelegateToken} from 'ds-token/delegate.sol';
import {CoinJoin} from 'geb/BasicTokenAdapters.sol';
import '../AdvancedTokenAdapters.sol';

contract TestSAFEEngine is SAFEEngine {
    uint256 constant RAY = 10 ** 27;

    constructor() public {}

    function mint(address usr, uint wad) public {
        coinBalance[usr] += wad * RAY;
        globalDebt += wad * RAY;
    }
    function balanceOf(address usr) public view returns (uint) {
        return uint(coinBalance[usr] / RAY);
    }
}

contract CollateralJoin7Test is DSTest {
    TestSAFEEngine safeEngine;
    DSDelegateToken collateral;
    CollateralJoin7 collateralA;
    CoinJoin coinA;
    DSDelegateToken coin;
    address me;
    address payable feeReceiver = address(0xabc);
    uint256 flashLoanFee = .003 ether;

    uint constant WAD = 10 ** 18;

    function setUp() public {
        safeEngine = new TestSAFEEngine();

        collateral  = new DSDelegateToken("Gem", 'Gem');
        collateralA = new CollateralJoin7(address(safeEngine), "collateral", address(collateral), flashLoanFee, feeReceiver);
        safeEngine.addAuthorization(address(collateralA));

        coin  = new DSDelegateToken("Coin", 'Coin');
        coinA = new CoinJoin(address(safeEngine), address(coin));
        safeEngine.addAuthorization(address(coinA));
        coin.setOwner(address(coinA));

        me = address(this);
    }
    function draw(bytes32 collateralType, int wad, int coin_) internal {
        address self = address(this);
        safeEngine.modifyCollateralBalance(collateralType, self, wad);
        safeEngine.modifySAFECollateralization(collateralType, self, self, self, wad, coin_);
    }
    function try_disable_contract(address a) public payable returns (bool ok) {
        string memory sig = "disableContract()";
        (ok,) = a.call(abi.encodeWithSignature(sig));
    }
    function try_join_tokenCollateral(address usr, uint wad) public returns (bool ok) {
        string memory sig = "join(address,uint256)";
        (ok,) = address(collateralA).call(abi.encodeWithSignature(sig, usr, wad));
    }
    function try_exit_coin(address usr, uint wad) public returns (bool ok) {
        string memory sig = "exit(address,uint256)";
        (ok,) = address(coinA).call(abi.encodeWithSignature(sig, usr, wad));
    }

    receive () external payable {}
    function test_collateral_join() public {
        collateral.mint(20 ether);
        collateral.approve(address(collateralA), 20 ether);
        assertTrue( try_join_tokenCollateral(address(this), 10 ether));
        assertEq(safeEngine.tokenCollateral("collateral", me), 10 ether);
        assertTrue( try_disable_contract(address(collateralA)));
        assertTrue(!try_join_tokenCollateral(address(this), 10 ether));
        assertEq(safeEngine.tokenCollateral("collateral", me), 10 ether);
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_coin_exit() public {
        address safe = address(this);
        safeEngine.mint(address(this), 100 ether);
        safeEngine.approveSAFEModification(address(coinA));
        assertTrue( try_exit_coin(safe, 40 ether));
        assertEq(coin.balanceOf(address(this)), 40 ether);
        assertEq(safeEngine.coinBalance(me), rad(60 ether));
        assertTrue( try_disable_contract(address(coinA)));
        assertTrue(!try_exit_coin(safe, 40 ether));
        assertEq(coin.balanceOf(address(this)), 40 ether);
        assertEq(safeEngine.coinBalance(me), rad(60 ether));
    }
    function test_coin_exit_join() public {
        address safe = address(this);
        safeEngine.mint(address(this), 100 ether);
        safeEngine.approveSAFEModification(address(coinA));
        coinA.exit(safe, 60 ether);
        coin.approve(address(coinA), uint(-1));
        coinA.join(safe, 30 ether);
        assertEq(coin.balanceOf(address(this)), 30 ether);
        assertEq(safeEngine.coinBalance(me), rad(70 ether));
    }
    function test_fallback_reverts() public {
        (bool ok,) = address(collateralA).call("invalid calldata");
        assertTrue(!ok);
    }
    function test_nonzero_fallback_reverts() public {
        (bool ok,) = address(collateralA).call{value: 10}("invalid calldata");
        assertTrue(!ok);
    }
    function testFail_disable_contract_no_access() public {
        collateralA.removeAuthorization(address(this));
        collateralA.disableContract();
    }
    function test_modify_parameters() public {
        assertTrue(collateralA.feeReceiver() != address(this));
        collateralA.modifyParameters("feeReceiver", address(this));
        assertEq(collateralA.feeReceiver(), address(this));

        assertTrue(collateralA.flashLoanFee() != 0);
        collateralA.modifyParameters("flashLoanFee", 0);
        assertEq(collateralA.flashLoanFee(), 0);
    }
    function testFail_modify_parameters_null_address() public {
        collateralA.modifyParameters("feeReceiver", address(0));
    }
    function test_flash_fee() public {
        assertEq(collateralA.flashFee(address(collateral), 1 ether), flashLoanFee);
    }
    function testFail_flash_fee_invalid_token() public {
        assertEq(collateralA.flashFee(address(0x1), 1 ether), flashLoanFee);
    }
    function test_max_flashloan() public {
        assertEq(collateralA.maxFlashLoan(address(collateral)), 0);
        collateral.mint(10 ether);
        collateral.approve(address(collateralA), 10 ether);
        assertTrue( this.try_join_tokenCollateral(address(this), 10 ether));
        assertEq(safeEngine.tokenCollateral("collateral", me), 10 ether);
        assertEq(collateralA.maxFlashLoan(address(collateral)), 10 ether);
    }
    function testFail_max_flashloan_invalid_token() public {
        collateralA.maxFlashLoan(address(0));
    }
    function test_flash_loan(uint loanSize, uint feePercentage) public {
        assertEq(collateralA.maxFlashLoan(address(collateral)), 0);
        feePercentage = feePercentage % 1 ether; // up to 100%
        collateralA.modifyParameters("flashLoanFee", feePercentage);

        loanSize = (loanSize % 10000000000 ether) + 1;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = feePercentage * loanSize / 1 ether;
        uint previousBalance = collateral.balanceOf(address(this));

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(), // return value
            loanSize,
            fee,
            loanSize + fee,                // amount to repay
            previousBalance,
            false                           // revert
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
        assertEq(collateral.balanceOf(address(this)), previousBalance - fee);
        assertEq(collateral.balanceOf(address(collateralA)), loanSize);
        assertEq(collateral.balanceOf(feeReceiver), fee);
    }
    function testFail_flash_loan_pay_less() public {
        uint loanSize = 1000 ether;

        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),        // return value
            loanSize,
            fee,
            loanSize + fee - 1,                    // amount to repay
            collateral.balanceOf(address(this)),   // previous balance
            false                                  // revert
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
    }
    function testFail_flash_loan_pay_nothing() public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),        // return value
            loanSize,
            fee,
            0,                                     // amount to repay
            collateral.balanceOf(address(this)),   // previous balance
            false                                  // revert
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
    }
    function testFail_flash_loan_insuficient_funds() public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),       // return value
            loanSize + 1,
            fee,
            loanSize + fee,                       // amount to repay
            collateral.balanceOf(address(this)),  // previous balance
            false                                 // revert
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize + 1, data);
    }
    function testFail_flash_loan_callback_failed(bytes32 returnValue) public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            returnValue,                         // return value
            loanSize,
            fee,
            loanSize + fee,                      // amount to repay
            collateral.balanceOf(address(this)), // previous balance
            false                                // revert
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
    }
    function testFail_flash_loan_callback_reverts() public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),      // return value
            loanSize,
            fee,
            loanSize + fee,                      // amount to repay
            collateral.balanceOf(address(this)), // previous balance
            true                                 // revert
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
    }
    function testFail_flash_loan_reenter_join() public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),      // return value
            loanSize,
            fee,
            loanSize + fee,                      // amount to repay
            collateral.balanceOf(address(this)), // previous balance
            2                                    // reenter join
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
    }
    function testFail_flash_loan_reenter_exit() public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),      // return value
            loanSize,
            fee,
            loanSize + fee,                      // amount to repay
            collateral.balanceOf(address(this)), // previous balance
            3                                    // reenter exit
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
    }
    function testFail_flash_loan_reenter_loan() public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),      // return value
            loanSize,
            fee,
            loanSize + fee,                      // amount to repay
            collateral.balanceOf(address(this)), // previous balance
            4                                    // reenter flashLoan
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateral), loanSize, data);
    }
    function testFail_flash_loan_invalid_token(address addr) public {
        uint loanSize = 1000 ether;
        collateral.mint(loanSize * 3);
        collateral.approve(address(collateralA), loanSize);
        assertTrue( this.try_join_tokenCollateral(address(this), loanSize));

        uint fee = collateralA.flashLoanFee() * loanSize / 1 ether;

        bytes memory data = abi.encode(
            collateralA.CALLBACK_SUCCESS(),      // return value
            loanSize,
            fee,
            loanSize + fee,                      // amount to repay
            collateral.balanceOf(address(this)), // previous balance
            false                                 // revert
        );

        collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(addr), loanSize, data);
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external payable virtual returns (bytes32) {
        (
            bytes32 returnValue,
            uint loanSize,
            uint fee_,
            uint amountToRepay,
            uint previousBalance,
            uint doRevert
        ) = abi.decode(data, (bytes32, uint, uint, uint, uint, uint));

        uint currentBalance = collateral.balanceOf(address(this));

        assertEq(loanSize, amount);
        assertEq(fee_, fee);
        assertEq(initiator, address(this));
        assertEq(token, address(collateral));
        assertEq(currentBalance, previousBalance + amount);

        if (doRevert == 2)
            collateralA.join(address(this), 1);
        else if (doRevert == 3)
            collateralA.exit(address(this), 1);
        else if (doRevert == 4)
            collateralA.flashLoan(IERC3156FlashBorrowerLike(address(this)), address(collateralA), 1, "");

        collateral.transfer(msg.sender, amountToRepay);
        require(doRevert != 1, "forced revert");
        return returnValue;
    }
}