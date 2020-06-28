/// AdvancedTokenAdapters.sol

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.7;

import "geb/Logging.sol";

abstract contract CDPEngineLike {
    function modifyCollateralBalance(bytes32,address,int) virtual public;
}

// CollateralJoin1
abstract contract CollateralLike {
    function decimals() virtual public view returns (uint);
    function transfer(address,uint) virtual public returns (bool);
    function transferFrom(address,address,uint) virtual public returns (bool);
}

contract CollateralJoin1 is Logging {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external emitLog isAuthorized {
        authorizedAccounts[account] = 1;
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external emitLog isAuthorized {
        authorizedAccounts[account] = 0;
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin1/account-not-authorized");
        _;
    }

    CDPEngineLike public cdpEngine;
    bytes32 public collateralType;
    CollateralLike public collateral;
    uint    public decimals;
    uint    public contractEnabled;  // Access Flag

    constructor(address cdpEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
        cdpEngine = CDPEngineLike(cdpEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike(collateral_);
        decimals = collateral.decimals();
    }
    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function disableContract() external emitLog isAuthorized {
        contractEnabled = 0;
    }
    function join(address usr, uint wad) external emitLog {
        require(contractEnabled == 1, "CollateralJoin1/not-contractEnabled");
        require(int(wad) >= 0, "CollateralJoin1/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, usr, int(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin1/failed-transfer");
    }
    function exit(address usr, uint wad) external emitLog {
        require(wad <= 2 ** 255, "CollateralJoin1/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        require(collateral.transfer(usr, wad), "CollateralJoin1/failed-transfer");
    }
}

// CollateralJoin2

// For a token that does not return a bool on transfer or transferFrom (like OMG)
// This is one way of doing it. Check the balances before and after calling a transfer

abstract contract CollateralLike2 {
    function decimals() virtual public view returns (uint);
    function transfer(address,uint) virtual public;
    function transferFrom(address,address,uint) virtual public;
    function balanceOf(address) virtual public view returns (uint);
    function allowance(address,address) virtual public view returns (uint);
}

contract CollateralJoin2 is Logging {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external emitLog isAuthorized {
        authorizedAccounts[account] = 1;
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external emitLog isAuthorized {
        authorizedAccounts[account] = 0;
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "CollateralJoin2/account-not-authorized");
        _;
    }

    CDPEngineLike public cdpEngine;
    bytes32 public collateralType;
    CollateralLike2 public collateral;
    uint public decimals;
    uint public contractEnabled;

    constructor(address cdpEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        cdpEngine = CDPEngineLike(cdpEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike2(collateral_);
        decimals = collateral.decimals();
        contractEnabled = 1;
    }

    function disableContract() external emitLog isAuthorized {
        contractEnabled = 0;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "CollateralJoin2/overflow");
    }

    function transfer(int wad, address guy) internal {
        int256 prevBalance = int(collateral.balanceOf(address(this)));
        require(prevBalance >= wad, "CollateralJoin2/no-funds");
        (bool ok,) = address(collateral).call(
            abi.encodeWithSignature("transfer(address,uint256)", guy, wad)
        );
        require(ok, "CollateralJoin2/failed-transfer");
        require(uint(prevBalance + wad) == collateral.balanceOf(address(this)), "CollateralJoin2/failed-transfer");
    }

    function transferFrom(int wad) internal {
        int256 prevBalance = int(collateral.balanceOf(msg.sender));
        require(prevBalance >= wad, "CollateralJoin2/no-funds");
        require(int(collateral.allowance(msg.sender, address(this))) >= wad, "CollateralJoin2/no-allowance");
        (bool ok,) = address(collateral).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), wad)
        );
        require(ok, "CollateralJoin2/failed-transfer");
        require(uint(prevBalance - wad) == collateral.balanceOf(msg.sender), "CollateralJoin2/failed-transfer");
    }
    function join(address urn, uint wad) public emitLog {
        require(contractEnabled == 1, "CollateralJoin2/contract-not-enabled");
        require(wad <= 2 ** 255, "CollateralJoin2/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, urn, int(wad));
        transferFrom(int256(wad));
    }

    function exit(address guy, uint wad) public emitLog {
        require(wad <= 2 ** 255, "CollateralJoin2/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        transfer(int(wad), guy);
    }
}

// CollateralJoin3
// For a token that has a lower precision than 18 and doesn't have decimals field in place

abstract contract CollateralLike3 {
    function transfer(address,uint) virtual public returns (bool);
    function transferFrom(address,address,uint) virtual public returns (bool);
}

contract CollateralJoin3 is Logging {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address usr) external emitLog isAuthorized { authorizedAccounts[usr] = 1; }
    function removeAuthorization(address usr) external emitLog isAuthorized { authorizedAccounts[usr] = 0; }
    modifier isAuthorized {
      require(authorizedAccounts[msg.sender] == 1, "CollateralJoin3/not-authorized");
      _;
    }

    CDPEngineLike public cdpEngine;
    bytes32 public collateralType;
    CollateralLike3 public collateral;
    uint public decimals;
    uint public contractEnabled;

    constructor(address cdpEngine_, bytes32 collateralType_, address collateral_, uint decimals_) public {
        authorizedAccounts[msg.sender] = 1;
        cdpEngine = CDPEngineLike(cdpEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike3(collateral_);
        require(decimals_ < 18, "CollateralJoin3/decimals-higher-18");
        decimals = decimals_;
        contractEnabled = 1;
    }

    function disableContract() external emitLog isAuthorized {
        contractEnabled = 0;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "CollateralJoin3/overflow");
    }

    function mul(int x, uint y) internal pure returns (int z) {
        require(y == 0 || (z = x * int256(y)) / int256(y) == x, "CollateralJoin3/overflow");
    }

    function join(address urn, uint wad) public emitLog {
        require(contractEnabled == 1, "CollateralJoin3/contract-not-enabled");
        uint wad18 = mul(wad, 10 ** (18 - decimals));
        require(wad18 <= 2 ** 255, "CollateralJoin3/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, urn, int(wad18));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin3/failed-transfer");
    }

    function exit(address guy, uint wad) public emitLog {
        uint wad18 = mul(wad, 10 ** (18 - decimals));
        require(wad18 <= 2 ** 255, "CollateralJoin3/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad18));
        require(collateral.transfer(guy, wad), "CollateralJoin3/failed-transfer");
    }
}

/// CollateralJoin4

// Copyright (C) 2019 Lorenzo Manacorda <lorenzo@mailbox.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// For tokens that do not implement transferFrom (like GNT), meaning the usual adapter
// approach won't work: the adapter cannot call transferFrom and therefore
// has no way of knowing when users deposit gems into it.

// To work around this, we introduce the concept of a bag, which is a trusted
// (it's created by the adapter), personalized component (one for each user).

// Users first have to create their bag with `CollateralJoin4.make`, then transfer
// tokens to it, and then call `CollateralJoin4.join`, which transfer the collateral from the
// bag to the adapter.

abstract contract CollateralLike4 {
    function decimals() virtual public view returns (uint);
    function balanceOf(address) virtual public returns (uint256);
    function transfer(address, uint256) virtual public returns (bool);
}

contract GemBag {
    address  public ada;
    address  public lad;
    CollateralLike4 public collateral;

    constructor(address lad_, address collateral_) public {
        ada = msg.sender;
        lad = lad_;
        collateral = CollateralLike4(collateral_);
    }

    function exit(address usr, uint256 wad) external {
        require(msg.sender == ada || msg.sender == lad, "GemBag/invalid-caller");
        require(collateral.transfer(usr, wad), "GemBag/failed-transfer");
    }
}

contract CollateralJoin4 is Logging {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address usr) external emitLog isAuthorized { authorizedAccounts[usr] = 1; }
    function removeAuthorization(address usr) external emitLog isAuthorized { authorizedAccounts[usr] = 0; }
    modifier isAuthorized {
      require(authorizedAccounts[msg.sender] == 1, "CollateralJoin4/not-authorized");
      _;
    }

    CDPEngineLike  public cdpEngine;
    bytes32  public collateralType;
    CollateralLike4 public collateral;
    uint     public decimals;
    uint public contractEnabled;

    mapping(address => address) public bags;

    constructor(address cdpEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        cdpEngine = CDPEngineLike(cdpEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike4(collateral_);
        decimals = collateral.decimals();
        contractEnabled = 1;
    }

    function disableContract() external emitLog isAuthorized {
        contractEnabled = 0;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    // -- admin --
    function make() external returns (address bag) {
        bag = make(msg.sender);
    }

    function make(address usr) public emitLog returns (address bag) {
        require(bags[usr] == address(0), "CollateralJoin4/bag-already-exists");
        bag = address(new GemBag(address(usr), address(collateral)));
        bags[usr] = bag;
    }

    // -- collateral --
    function join(address urn, uint256 wad) external emitLog {
        require(contractEnabled == 1, "CollateralJoin4/contract-not-enabled");
        require(int256(wad) >= 0, "CollateralJoin4/negative-amount");
        GemBag(bags[msg.sender]).exit(address(this), wad);
        cdpEngine.modifyCollateralBalance(collateralType, urn, int256(wad));
    }

    function exit(address usr, uint256 wad) external emitLog {
        require(int256(wad) >= 0, "CollateralJoin4/negative-amount");

        cdpEngine.modifyCollateralBalance(collateralType, msg.sender, -int256(wad));
        require(collateral.transfer(usr, wad), "CollateralJoin4/failed-transfer");
    }
}

// CollateralLike5
// For a token that has a lower precision than 18 and it has decimals (like USDC)
abstract contract CollateralLike5 {
    function decimals() virtual public view returns (uint8);
    function transfer(address,uint) virtual public returns (bool);
    function transferFrom(address,address,uint) virtual public returns (bool);
}

contract CollateralJoin5 is Logging {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address usr) external emitLog isAuthorized { authorizedAccounts[usr] = 1; }
    function removeAuthorization(address usr) external emitLog isAuthorized { authorizedAccounts[usr] = 0; }
    modifier isAuthorized {
      require(authorizedAccounts[msg.sender] == 1, "CollateralJoin5/not-authorized");
      _;
    }

    CDPEngineLike   public cdpEngine;
    bytes32         public collateralType;
    CollateralLike5 public collateral;
    uint            public decimals;
    uint            public contractEnabled;  // Access Flag

    constructor(address cdpEngine_, bytes32 collateralType_, address collateral_) public {
        collateral = CollateralLike5(collateral_);
        decimals = collateral.decimals();
        require(decimals < 18, "CollateralJoin5/decimals-18-or-higher");
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
        cdpEngine = CDPEngineLike(cdpEngine_);
        collateralType = collateralType_;
    }

    function disableContract() external emitLog isAuthorized {
        contractEnabled = 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "CollateralJoin5/overflow");
    }

    function join(address cdp, uint wad) public emitLog {
        require(contractEnabled == 1, "CollateralJoin5/not-contractEnabled");
        uint wad18 = mul(wad, 10 ** (18 - decimals));
        require(int(wad18) >= 0, "CollateralJoin5/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, cdp, int(wad18));
        require(collateral.transferFrom(msg.sender, address(this), wad), "CollateralJoin5/failed-transfer");
    }

    function exit(address guy, uint wad) public emitLog {
        uint wad18 = mul(wad, 10 ** (18 - decimals));
        require(int(wad18) >= 0, "CollateralJoin5/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad18));
        require(collateral.transfer(guy, wad), "CollateralJoin5/failed-transfer");
    }
}

// AuthCollateralJoin

contract AuthCollateralJoin is Logging {
    CDPEngineLike public cdpEngine;
    bytes32 public collateralType;
    CollateralLike public collateral;
    uint public decimals;
    uint public contractEnabled;

    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address usr) public emitLog isAuthorized { authorizedAccounts[usr] = 1; }
    function removeAuthorization(address usr) public emitLog isAuthorized { authorizedAccounts[usr] = 0; }
    modifier isAuthorized { require(authorizedAccounts[msg.sender] == 1, "AuthCollateralJoin/non-authed"); _; }

    constructor(address cdpEngine_, bytes32 collateralType_, address collateral_) public {
        cdpEngine = CDPEngineLike(cdpEngine_);
        collateralType = collateralType_;
        collateral = CollateralLike(collateral_);
        decimals = collateral.decimals();
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
    }

    function disableContract() external emitLog isAuthorized {
        contractEnabled = 0;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function join(address usr, uint wad) public isAuthorized emitLog {
        require(contractEnabled == 1, "AuthCollateralJoin/contract-not-enabled");
        require(int(wad) >= 0, "AuthCollateralJoin/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, usr, int(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "AuthCollateralJoin/failed-transfer");
    }

    function exit(address usr, uint wad) public isAuthorized emitLog {
        require(wad <= 2 ** 255, "AuthCollateralJoin/overflow");
        cdpEngine.modifyCollateralBalance(collateralType, msg.sender, -int(wad));
        require(collateral.transfer(usr, wad), "AuthCollateralJoin/failed-transfer");
    }
}
