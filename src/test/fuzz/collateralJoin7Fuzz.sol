pragma solidity ^0.6.7;

import "../../AdvancedTokenAdapters.sol";
import "../../../lib/ds-weth/lib/ds-test/src/test.sol";
import {SAFEEngine} from "../../../lib/geb/src/SAFEEngine.sol";
import {CoinJoin} from "../../../lib/geb/src/BasicTokenAdapters.sol";

contract Token {
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) allowance;
    uint public totalSupply;
    uint public decimals = 18;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "TaxCollector/add-uint-uint-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "TaxCollector/sub-uint-uint-underflow");
    }

    function mint(address to, uint value) public {
        balanceOf[to] = addition(balanceOf[to], value);
        totalSupply = addition(totalSupply, value);
    }
    function transfer(address to, uint value) public returns (bool) {
        balanceOf[to] = addition(balanceOf[to], value);
        balanceOf[msg.sender] = subtract(balanceOf[msg.sender], value);
        return true;
    }
    function approve(address to, uint value) public returns (bool) {
        allowance[msg.sender][to] = value;
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns (bool) {
        allowance[from][msg.sender] = subtract(allowance[from][msg.sender], value);
        balanceOf[to] = addition(balanceOf[to], value);
        balanceOf[from] = subtract(balanceOf[from], value);
        return true;
    }
}

contract User {
    CollateralJoin7 join;
    bytes32 constant public  CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(CollateralJoin7 join_) public {
        join = join_;
    }

    function doJoin(uint amount) public {
        Token(address(join.collateral())).approve(address(join), amount);
        join.join(address(this), amount);
    }

    function doExit(uint amount) public {
        join.exit(address(this), amount);
    }

    function doFlashLoan(uint amount) public {
        join.flashLoan(
            IERC3156FlashBorrowerLike(address(this)),
            address(join.collateral()),
            amount,
            ""
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external payable virtual returns (bytes32) {
        Token(token).mint(address(this), fee);
        Token(token).transfer(msg.sender, amount + fee);
        return CALLBACK_SUCCESS;
    }

    function deployed() public returns (bool) {
        return true;
    }

}

// @notice Will create an auction, to enable fuzzing the bidding function
contract Fuzz is DSTest{
    SAFEEngine safeEngine;
    Token collateral;
    CollateralJoin7 collateralA;
    address payable feeReceiver = address(0xabc);
    uint256 flashLoanFee = .003 ether;
    mapping(address => User) users;
    address[] userAddrs;
    mapping(User => uint) currentlyJoined;
    uint totalJoined;

    function isContract(address _addr) private returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // will create a new user for every msg.sender, it will use as many users as set on echidna config
    modifier createUser() {
        if (!isContract(address(users[msg.sender]))) {
            users[msg.sender] = new User(collateralA);
            userAddrs.push(address(users[msg.sender]));
        }
        _;
    }

    constructor() public {
        safeEngine = new SAFEEngine();

        collateral  = new Token();
        collateralA = new CollateralJoin7(address(safeEngine), "collateral", address(collateral), flashLoanFee, feeReceiver);
        safeEngine.addAuthorization(address(collateralA));
    }

    function setUp() public {} // needed for ds-test

    function join(uint amount) public createUser {
        collateral.mint(address(users[msg.sender]), amount);

        uint previousUserBalance = collateral.balanceOf(address(users[msg.sender]));
        uint previousJoinBalance = collateral.balanceOf(address(collateralA));
        uint previousUserCollateralBalance = safeEngine.tokenCollateral("collateral", address(users[msg.sender]));

        users[msg.sender].doJoin(amount);

        // join successful
        assert(collateralA.contractEnabled() == 1);
        assert(collateral.balanceOf(address(users[msg.sender])) == previousUserBalance - amount);
        assert(collateral.balanceOf(address(collateralA)) == previousJoinBalance + amount);
        assert(safeEngine.tokenCollateral("collateral", address(users[msg.sender]))
            == previousUserCollateralBalance + amount);

        // local vars for properties
        currentlyJoined[users[msg.sender]] += amount;
        totalJoined += amount;
    }

    function exit(uint amount) public createUser {
        uint previousUserBalance = collateral.balanceOf(address(users[msg.sender]));
        uint previousJoinBalance = collateral.balanceOf(address(collateralA));
        uint previousUserCollateralBalance = safeEngine.tokenCollateral("collateral", address(users[msg.sender]));

        users[msg.sender].doExit(amount);

        // exit successful
        assert(collateralA.contractEnabled() == 1);
        assert(collateral.balanceOf(address(users[msg.sender])) == previousUserBalance + amount);
        assert(collateral.balanceOf(address(collateralA)) == previousJoinBalance - amount);
        assert(safeEngine.tokenCollateral("collateral", address(users[msg.sender]))
            == previousUserCollateralBalance - amount);

        // local vars for properties
        currentlyJoined[users[msg.sender]] -= amount;
        totalJoined -= amount;
    }

    function flashloan(uint amount) public createUser {
        uint previousUserBalance = collateral.balanceOf(address(users[msg.sender]));
        uint previousJoinBalance = collateral.balanceOf(address(collateralA));
        uint previousFeeReceiverBalance = collateral.balanceOf(feeReceiver);

        users[msg.sender].doFlashLoan(amount);

        // flashloan successful
        assert(collateralA.contractEnabled() == 1);
        assert(collateral.balanceOf(address(users[msg.sender])) == previousUserBalance);
        assert(collateral.balanceOf(address(collateralA)) == previousJoinBalance);
        assert(collateral.balanceOf(feeReceiver) == previousFeeReceiverBalance + (amount * collateralA.flashLoanFee() / 1 ether));
    }

    function fuzzFlashLoanFee(uint fee) public {
        fee = fee % 1 ether; // up to 100%
        flashLoanFee = fee;
        collateralA.modifyParameters("flashLoanFee", fee);
    }

    function test_fuzz() public { // dstest, verify if all are executing
        join(1000);
        flashloan(1000);
        exit(1000);
    }

    // properties
    function echidna_total_join() public returns (bool) {
        return collateral.balanceOf(address(collateralA)) == totalJoined;
    }

    function echidna_supply_integrity() public returns (bool) {
        uint totalSupply;
        for (uint i = 0; i < userAddrs.length; i++)
            totalSupply += collateral.balanceOf(userAddrs[i]);
        totalSupply += collateral.balanceOf(address(collateralA));
        totalSupply += collateral.balanceOf(feeReceiver);
        return collateral.totalSupply() == totalSupply;
    }

    function echidna_join_integrity() public returns (bool) {
        for (uint i = 0; i < userAddrs.length; i++)
            if (currentlyJoined[User(userAddrs[i])] != safeEngine.tokenCollateral("collateral", userAddrs[i]))
                return false;

        return true;
    }

    function echidna_enabled() public returns (bool) {
        return collateralA.contractEnabled() == 1;
    }

    function echidna_collateralType() public returns (bool) {
        return collateralA.collateralType() == "collateral";
    }

    function echidna_collateral() public returns (bool) {
        return address(collateralA.collateral()) == address(collateral);
    }

    function echidna_decimals() public returns (bool) {
        return collateralA.decimals() == 18;
    }

    function echidna_feeReceiver() public returns (bool) {
        return collateralA.feeReceiver() == feeReceiver;
    }

    function echidna_loanFee() public returns (bool) {
        return collateralA.flashLoanFee() == flashLoanFee;
    }
}
