pragma solidity ^0.5.15;

import {DSTest} from "./ds/test/test.sol";
import {DSToken} from "./ds/token/token.sol";
import {DSValue} from "./ds/value/value.sol";
import {DSRoles} from "./ds/roles/roles.sol";
import {DSGuard} from "./ds/guard/guard.sol";
import {WETH9_} from "./ds/weth/weth9.sol";

import "./MrsDeploy.sol";
import {GemJoin} from "./join.sol";
import {GovActions} from "./govActions.sol";

contract Hevm {
    function warp(uint256) public;
}

contract AuctionLike {
    function tend(uint, uint, uint) public;
    function dent(uint, uint, uint) public;
    function deal(uint) public;
}

contract BinLike {
    uint256 give;

    constructor(
      uint256 give_
    ) public {
      give = give_;
    }

    function swap(address bond, address gov, uint sell) external returns (uint) {
        DSToken(bond).transferFrom(msg.sender, address(this), sell);
        DSToken(gov).transfer(msg.sender, give);
        return give;
    }
}

contract HopeLike {
    function hope(address guy) public;
}

contract FakeUser {
    function doApprove(address token, address guy) public {
        DSToken(token).approve(guy);
    }

    function doCoinJoin(address obj, address urn, uint wad) public {
        CoinJoin(obj).join(urn, wad);
    }

    function doCoinExit(address obj, address guy, uint wad) public {
        CoinJoin(obj).exit(guy, wad);
    }

    function doEthJoin(address payable obj, address gem, address urn, uint wad) public {
        WETH9_(obj).deposit.value(wad)();
        WETH9_(obj).approve(address(gem), uint(-1));
        GemJoin(gem).join(urn, wad);
    }

    function doFrob(address obj, bytes32 ilk, address urn, address gem, address coin, int dink, int dart) public {
        Vat(obj).frob(ilk, urn, gem, coin, dink, dart);
    }

    function doFork(address obj, bytes32 ilk, address src, address dst, int dink, int dart) public {
        Vat(obj).fork(ilk, src, dst, dink, dart);
    }

    function doHope(address obj, address guy) public {
        HopeLike(obj).hope(guy);
    }

    function doTend(address obj, uint id, uint lot, uint bid) public {
        AuctionLike(obj).tend(id, lot, bid);
    }

    function doDent(address obj, uint id, uint lot, uint bid) public {
        AuctionLike(obj).dent(id, lot, bid);
    }

    function doDeal(address obj, uint id) public {
        AuctionLike(obj).deal(id);
    }

    function doEndFree(address end, bytes32 ilk) public {
        End(end).free(ilk);
    }

    function doESMJoin(address gem, address esm, uint256 wad) public {
        DSToken(gem).approve(esm, uint256(-1));
        ESM(esm).join(wad);
    }

    function() external payable {}
}

contract ProxyActions {
    DSPause public pause;
    GovActions public govActions;

    function file(address who, bytes32 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,bytes32)", who, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, address data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,address)", who, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,uint256)", who, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, bytes32 what, address data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,bytes32,address)", who, what, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, bytes32 what, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,bytes32,uint256)", who, what, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, address usr, bool data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,address,bool)", who, usr, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, bytes32 ilk, bytes32 what, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,bytes32,bytes32,uint256)", who, ilk, what, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function file(address who, bytes32 ilk, bytes32 what, address data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("file(address,bytes32,bytes32,address)", who, ilk, what, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function dripAndBack(address who, address addr1, address addr2) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("dripAndBack(address,address,address)", who, addr1, addr2);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function dripAndFile(address who, bytes32 what, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("dripAndFile(address,bytes32,uint256)", who, what, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function dripAndFile(address who, bytes32 ilk, bytes32 what, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("dripAndFile(address,bytes32,bytes32,uint256)", who, ilk, what, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function hire(address who, address data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("hire(address,address)", who, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function fire(address who, address data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("fire(address,address)", who, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function hope(address who, address trg) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("hope(address,address)", who, trg);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function nope(address who, address trg) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("nope(address,address)", who, trg);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function give(address who, address trg, uint wad) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("give(address,address,uint256)", who, trg, wad);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function take(address who, address trg, uint wad) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("take(address,address,uint256)", who, trg, wad);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function move(address who, address trg, uint wad) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("move(address,address,uint256)", who, trg, wad);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function cage(address end) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("cage(address)", end);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function cage(address end, bytes32 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("cage(address,bytes32)", end, data);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function setAuthority(address newAuthority) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("setAuthority(address,address)", pause, newAuthority);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function setDelay(uint newDelay) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("setDelay(address,uint256)", pause, newDelay);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }

    function setAuthorityAndDelay(address newAuthority, uint newDelay) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay);
        uint         eta = now;

        pause.plot(usr, tag, fax, eta);
        pause.exec(usr, tag, fax, eta);
    }
}

contract MrsDeployTestBase is DSTest, ProxyActions {
    Hevm hevm;

    VatFab vatFab;
    JugFab jugFab;
    VowFab vowFab;
    CatFab catFab;
    CoinFab coinFab;
    CoinJoinFab coinJoinFab;
    FlapFab flapFab;
    FlopFab flopFab;
    FlipFab flipFab;
    SpotFab spotFab;
    Vox1Fab vox1Fab;
    EndFab endFab;
    PotFab potFab;
    PauseFab pauseFab;
    ESMFab esmFab;

    MrsDeploy mrsDeploy;

    DSToken gov;
    DSValue pipETH;
    DSValue pipCOL;
    DSValue pipCOIN;

    DSRoles authority;

    WETH9_ weth;
    GemJoin ethJoin;
    GemJoin colJoin;

    Vat vat;
    Jug jug;
    Vow vow;
    BinLike bin;
    Cat cat;
    Flapper flap;
    Flopper flop;
    Coin coin;
    Pot pot;
    CoinJoin coinJoin;
    Spotter spotter;
    Vox1 vox1;
    End end;
    ESM esm;

    Flipper ethFlip;

    DSToken col;
    Flipper colFlip;

    FakeUser user1;
    FakeUser user2;

    bytes32[] ilks;
    uint256[] chops;

    // Vox vars
    uint v    = 1;
    uint trim = ray(0.03 ether);
    uint dawn = 1000000000158153903837946258; // 0.5% annualy
    uint dusk = ray(1 ether); // 0% annualy
    uint how  = 0.000005 ether;
    uint up   = 1000000000158153903837946258; // 0.5% annualy
    uint down = 1000000000158153903837946258; // 0.5% annualy
    uint span = ray(2 ether);
    uint go   = ray(1 ether);

    // --- Math ---
    uint256 constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function ray(uint x) internal pure returns (uint z) {
        z = x * 10 ** 9;
    }

    function setUp() public {
        vatFab = new VatFab();
        jugFab = new JugFab();
        vowFab = new VowFab();
        catFab = new CatFab();
        coinFab = new CoinFab();
        coinJoinFab = new CoinJoinFab();
        flapFab = new FlapFab();
        flopFab = new FlopFab();
        flipFab = new FlipFab();
        spotFab = new SpotFab();
        vox1Fab = new Vox1Fab();
        endFab = new EndFab();
        pauseFab = new PauseFab();
        govActions = new GovActions();
        esmFab = new ESMFab();
        potFab = new PotFab();

        mrsDeploy = new MrsDeploy();

        mrsDeploy.setFirstFabBatch(
          vatFab,
          jugFab,
          vowFab,
          catFab,
          coinFab,
          coinJoinFab,
          potFab
        );

        mrsDeploy.setSecondFabBatch(
          flapFab,
          flopFab,
          flipFab,
          spotFab,
          vox1Fab,
          endFab,
          esmFab,
          pauseFab
        );

        gov = new DSToken("GOV");
        gov.setAuthority(new DSGuard());
        pipETH = new DSValue();
        pipCOL = new DSValue();
        pipCOIN = new DSValue();
        authority = new DSRoles();
        authority.setRootUser(address(this), true);

        user1 = new FakeUser();
        user2 = new FakeUser();
        address(user1).transfer(100 ether);
        address(user2).transfer(100 ether);

        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);
    }

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function deployBondKeepAuth() public {
        bin = new BinLike(1 ether);

        mrsDeploy.deployVat();
        mrsDeploy.deployCoin("Mai Reflex-Bond", "MAI", 18, 99);
        mrsDeploy.deployTaxation(0);
        mrsDeploy.deployRateSetter(v, address(pipCOIN), span, trim, dawn, dusk, how, up, down, go);
        mrsDeploy.deployAuctions(address(gov), address(bin));
        mrsDeploy.deployVow();
        mrsDeploy.deployLiquidator();
        mrsDeploy.deployShutdown(address(gov), address(0x0), 10);
        mrsDeploy.deployPause(0, authority);

        require(address(mrsDeploy.pot()) == address(0), "Pot incompatible with reflex-bond");

        vat = mrsDeploy.vat();
        jug = mrsDeploy.jug();
        vow = mrsDeploy.vow();
        cat = mrsDeploy.cat();
        flap = mrsDeploy.flap();
        flop = mrsDeploy.flop();
        coin = mrsDeploy.coin();
        coinJoin = mrsDeploy.coinJoin();
        spotter = mrsDeploy.spotter();
        end = mrsDeploy.end();
        esm = mrsDeploy.esm();
        pause = mrsDeploy.pause();
        vox1 = mrsDeploy.vox1();

        authority.setRootUser(address(pause.proxy()), true);
        mrsDeploy.giveControl(address(pause.proxy()));

        weth = new WETH9_();
        ethJoin = new GemJoin(address(vat), "ETH", address(weth));
        mrsDeploy.deployCollateral("ETH", address(ethJoin), address(pipETH), 5 * 10**26);
        mrsDeploy.addAuthToFlip("ETH", address(pause.proxy()));

        col = new DSToken("COL");
        colJoin = new GemJoin(address(vat), "COL", address(col));
        mrsDeploy.deployCollateral("COL", address(colJoin), address(pipCOL), 5 * 10**26);
        mrsDeploy.addAuthToFlip("COL", address(pause.proxy()));

        // Set Vat Params
        this.file(address(vat), bytes32("Line"), uint(10000 * 10 ** 45));
        this.file(address(vat), bytes32("ETH"), bytes32("line"), uint(10000 * 10 ** 45));
        this.file(address(vat), bytes32("COL"), bytes32("line"), uint(10000 * 10 ** 45));

        pipETH.poke(bytes32(uint(300 * 10 ** 18))); // Price 300 COIN = 1 ETH (precision 18)
        pipCOL.poke(bytes32(uint(45 * 10 ** 18))); // Price 45 COIN = 1 COL (precision 18)
        pipCOIN.poke(bytes32(uint(1 * 10 ** 18))); // Price 1 COIN = 1 USD
        (ethFlip,) = mrsDeploy.ilks("ETH");
        (colFlip,) = mrsDeploy.ilks("COL");
        this.file(address(spotter), "ETH", "tam", uint(1500000000 ether));
        this.file(address(spotter), "ETH", "mat", uint(1500000000 ether));
        this.file(address(spotter), "COL", "tam", uint(1100000000 ether));
        this.file(address(spotter), "COL", "mat", uint(1100000000 ether));
        spotter.poke("ETH");
        spotter.poke("COL");
        (,,uint spot,,,uint risk) = vat.ilks("ETH");
        assertEq(spot, 300 * ONE * ONE / 1500000000 ether);
        assertEq(spot, risk);
        (,, spot,,,risk) = vat.ilks("COL");
        assertEq(spot, 45 * ONE * ONE / 1100000000 ether);
        assertEq(spot, risk);

        DSGuard(address(gov.authority())).permit(address(flop), address(gov), bytes4(keccak256("mint(address,uint256)")));
        DSGuard(address(gov.authority())).permit(address(flap), address(gov), bytes4(keccak256("burn(address,uint256)")));

        gov.mint(150 ether);
        gov.push(address(bin), 50 ether);
    }

    function deployStableKeepAuth() public {
        bin = new BinLike(1 ether);

        mrsDeploy.deployVat();
        mrsDeploy.deployCoin("Mai Reflex-Bond", "MAI", 18, 99);
        mrsDeploy.deployTaxation(1);
        mrsDeploy.deployAuctions(address(gov), address(bin));
        mrsDeploy.deployVow();
        mrsDeploy.deployLiquidator();
        mrsDeploy.deployShutdown(address(gov), address(0x0), 10);
        mrsDeploy.deployPause(0, authority);

        vat = mrsDeploy.vat();
        jug = mrsDeploy.jug();
        vow = mrsDeploy.vow();
        cat = mrsDeploy.cat();
        flap = mrsDeploy.flap();
        flop = mrsDeploy.flop();
        coin = mrsDeploy.coin();
        coinJoin = mrsDeploy.coinJoin();
        spotter = mrsDeploy.spotter();
        end = mrsDeploy.end();
        esm = mrsDeploy.esm();
        pause = mrsDeploy.pause();
        pot = mrsDeploy.pot();

        authority.setRootUser(address(pause.proxy()), true);
        mrsDeploy.giveControl(address(pause.proxy()));

        weth = new WETH9_();
        ethJoin = new GemJoin(address(vat), "ETH", address(weth));
        mrsDeploy.deployCollateral("ETH", address(ethJoin), address(pipETH), 5 * 10**26);
        mrsDeploy.addAuthToFlip("ETH", address(pause.proxy()));

        col = new DSToken("COL");
        colJoin = new GemJoin(address(vat), "COL", address(col));
        mrsDeploy.deployCollateral("COL", address(colJoin), address(pipCOL), 5 * 10**26);
        mrsDeploy.addAuthToFlip("COL", address(pause.proxy()));

        // Set Vat Params
        this.file(address(vat), bytes32("Line"), uint(10000 * 10 ** 45));
        this.file(address(vat), bytes32("ETH"), bytes32("line"), uint(10000 * 10 ** 45));
        this.file(address(vat), bytes32("COL"), bytes32("line"), uint(10000 * 10 ** 45));

        pipETH.poke(bytes32(uint(300 * 10 ** 18))); // Price 300 COIN = 1 ETH (precision 18)
        pipCOL.poke(bytes32(uint(45 * 10 ** 18))); // Price 45 COIN = 1 COL (precision 18)
        pipCOIN.poke(bytes32(uint(1 * 10 ** 18))); // Price 1 COIN = 1 USD
        (ethFlip,) = mrsDeploy.ilks("ETH");
        (colFlip,) = mrsDeploy.ilks("COL");
        this.file(address(spotter), "ETH", "tam", uint(1500000000 ether));
        this.file(address(spotter), "ETH", "mat", uint(1500000000 ether));
        this.file(address(spotter), "COL", "tam", uint(1100000000 ether));
        this.file(address(spotter), "COL", "mat", uint(1100000000 ether));
        spotter.poke("ETH");
        spotter.poke("COL");
        (,,uint spot,,,uint risk) = vat.ilks("ETH");
        assertEq(spot, 300 * ONE * ONE / 1500000000 ether);
        assertEq(spot, risk);
        (,, spot,,,risk) = vat.ilks("COL");
        assertEq(spot, 45 * ONE * ONE / 1100000000 ether);
        assertEq(spot, risk);

        DSGuard(address(gov.authority())).permit(address(flop), address(gov), bytes4(keccak256("mint(address,uint256)")));
        DSGuard(address(gov.authority())).permit(address(flap), address(gov), bytes4(keccak256("burn(address,uint256)")));

        gov.mint(150 ether);
        gov.push(address(bin), 50 ether);
    }

    // Bond
    function deployBond() public {
        deployBondKeepAuth();
        mrsDeploy.releaseAuth();
    }

    function deployBondWithVatPermissions() public {
        deployBondKeepAuth();
        mrsDeploy.addCreatorAuth();
        mrsDeploy.releaseAuth();
    }

    function deployBondWithFullPermissions() public {
        deployBondKeepAuth();
        mrsDeploy.addCreatorAuth();
    }

    // Stablecoin
    function deployStable() public {
        deployStableKeepAuth();
        mrsDeploy.releaseAuth();
    }

    function deployStableWithVatPermissions() public {
        deployStableKeepAuth();
        mrsDeploy.addCreatorAuth();
        mrsDeploy.releaseAuth();
    }

    function deployStableWithFullPermissions() public {
        deployStableKeepAuth();
        mrsDeploy.addCreatorAuth();
    }

    // Utils
    function giveVatPermission(address usr) public {
        require(usr != address(0), "MrsDeploy/usr-is-null");
        vat.rely(usr);
    }

    function offerVatPermissionTo(address usr) public {
        vat.rely(usr);
        vat.deny(address(this));
    }

    function release() public {
        mrsDeploy.releaseAuth();
    }

    function() external payable {}
}
