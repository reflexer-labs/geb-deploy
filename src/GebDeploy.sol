/// GebDeploy.sol

// Copyright (C) 2018-2019 Gonzalo Balabasquer <gbalabasquer@gmail.com>

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

pragma solidity ^0.5.15;

import {DSAuth, DSAuthority} from "./ds/auth/auth.sol";
import {DSPause, DSPauseProxy} from "./ds/pause/pause.sol";

import {CDPEngine} from "geb/cdpEngine.sol";
import {TaxCollector} from "geb/taxCollector.sol";
import {Vow} from "geb/vow.sol";
import {Cat} from "geb/cat.sol";
import {CoinJoin} from "geb/join.sol";
import {Flapper} from "geb/flap.sol";
import {Flopper} from "geb/flop.sol";
import {Flipper} from "geb/flip.sol";
import {Coin} from "geb/coin.sol";
import {End} from "geb/end.sol";
import {ESM} from "./ds/esm/ESM.sol";
import {Vox1} from "geb/vox.sol";
import {CoinSavingsAccount} from "geb/CoinSavingsAccount.sol";
import {SettlementSurplusAuction} from "geb/SettlementSurplusAuction.sol";
import {OracleRelayer} from "geb/OracleRelayer.sol";

contract CDPEngineFab {
    function newCDPEngine() public returns (CDPEngine cdpEngine) {
        cdpEngine = new CDPEngine();
        cdpEngine.addAuthorization(msg.sender);
        cdpEngine.removeAuthorization(address(this));
    }
}

contract TaxCollectorFab {
    function newTaxCollector(address cdpEngine) public returns (TaxCollector taxCollector) {
        taxCollector = new TaxCollector(cdpEngine);
        taxCollector.addAuthorization(msg.sender);
        taxCollector.removeAuthorization(address(this));
    }
}

contract VowFab {
    function newVow(address cdpEngine, address flap, address flop) public returns (Vow vow) {
        vow = new Vow(cdpEngine, flap, flop);
        vow.addAuthorization(msg.sender);
        vow.removeAuthorization(address(this));
    }
}

contract CatFab {
    function newCat(address cdpEngine) public returns (Cat cat) {
        cat = new Cat(cdpEngine);
        cat.addAuthorization(msg.sender);
        cat.removeAuthorization(address(this));
    }
}

contract CoinFab {
    function newCoin(string memory name, string memory symbol, uint8 decimals, uint chainId)
      public returns (Coin coin) {
        coin = new Coin(name, symbol, decimals, chainId);
        coin.addAuthorization(msg.sender);
        coin.removeAuthorization(address(this));
    }
}

contract CoinJoinFab {
    function newCoinJoin(address cdpEngine, address coin) public returns (CoinJoin coinJoin) {
        coinJoin = new CoinJoin(cdpEngine, coin);
    }
}

contract FlapFab {
    function newFlap(address cdpEngine) public returns (Flapper flap) {
        flap = new Flapper(cdpEngine);
        flap.addAuthorization(msg.sender);
        flap.removeAuthorization(address(this));
    }
}

contract FlopFab {
    function newFlop(address cdpEngine, address gov) public returns (Flopper flop) {
        flop = new Flopper(cdpEngine, gov);
        flop.addAuthorization(msg.sender);
        flop.removeAuthorization(address(this));
    }
}

contract FlipFab {
    function newFlip(address cdpEngine, bytes32 ilk) public returns (Flipper flip) {
        flip = new Flipper(cdpEngine, ilk);
        flip.addAuthorization(msg.sender);
        flip.removeAuthorization(address(this));
    }
}

contract SpotFab {
    function newSpotter(address cdpEngine) public returns (Spotter spotter) {
        spotter = new Spotter(cdpEngine);
        spotter.addAuthorization(msg.sender);
        spotter.removeAuthorization(address(this));
    }
}

contract PotFab {
    function newPot(address cdpEngine) public returns (Pot pot) {
        pot = new Pot(cdpEngine);
        pot.addAuthorization(msg.sender);
        pot.removeAuthorization(address(this));
    }
}

contract Vox1Fab {
    function newVox1(address taxCollector, address spot) public returns (Vox1 vox) {
        vox = new Vox1(taxCollector, spot);
        vox.addAuthorization(msg.sender);
        vox.removeAuthorization(address(this));
    }
}

contract ESMFab {
    function newESM(address gov, address end, address pit, uint min) public returns (ESM esm) {
        esm = new ESM(gov, end, pit, min);
    }
}

contract EndFab {
    function newEnd() public returns (End end) {
        end = new End();
        end.addAuthorization(msg.sender);
        end.removeAuthorization(address(this));
    }
}

contract PauseFab {
    function newPause(uint delay, address owner, DSAuthority authority) public returns(DSPause pause) {
        pause = new DSPause(delay, owner, authority);
    }
}

contract MrsDeploy is DSAuth {
    CDPEngineFab       public cdpEngineFab;
    TaxCollectorFab       public taxCollectorFab;
    VowFab       public vowFab;
    CatFab       public catFab;
    CoinFab      public coinFab;
    CoinJoinFab  public coinJoinFab;
    FlapFab      public flapFab;
    FlopFab      public flopFab;
    FlipFab      public flipFab;
    SpotFab      public spotFab;
    Vox1Fab      public vox1Fab;
    EndFab       public endFab;
    ESMFab       public esmFab;
    PauseFab     public pauseFab;
    PotFab       public potFab;

    CDPEngine       public cdpEngine;
    TaxCollector       public taxCollector;
    Vow       public vow;
    Cat       public cat;
    Coin      public coin;
    CoinJoin  public coinJoin;
    Flapper   public flap;
    Flopper   public flop;
    Spotter   public spotter;
    Vox1      public vox1;
    Pot       public pot;
    End       public end;
    ESM       public esm;
    DSPause   public pause;

    mapping(bytes32 => Ilk) public ilks;

    uint8 public step = 0;

    uint256 constant ONE = 10 ** 27;

    struct Ilk {
        Flipper flip;
        address adapter;
    }

    constructor() public {}

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function setFirstFabBatch(
        CDPEngineFab cdpEngineFab_,
        TaxCollectorFab taxCollectorFab_,
        VowFab vowFab_,
        CatFab catFab_,
        CoinFab coinFab_,
        CoinJoinFab coinJoinFab_,
        PotFab potFab_
    ) public auth {
        require(address(cdpEngineFab) == address(0), "CDPEngine Fab already set");
        cdpEngineFab = cdpEngineFab_;
        taxCollectorFab = taxCollectorFab_;
        vowFab = vowFab_;
        catFab = catFab_;
        coinFab = coinFab_;
        coinJoinFab = coinJoinFab_;
        potFab = potFab_;
    }

    function setSecondFabBatch(
        FlapFab flapFab_,
        FlopFab flopFab_,
        FlipFab flipFab_,
        SpotFab spotFab_,
        Vox1Fab vox1Fab_,
        EndFab endFab_,
        ESMFab esmFab_,
        PauseFab pauseFab_
    ) public auth {
        require(address(cdpEngineFab) != address(0), "CDPEngine Fab not set");
        require(address(flapFab) == address(0), "Flap Fab already set");
        flapFab = flapFab_;
        flopFab = flopFab_;
        flipFab = flipFab_;
        spotFab = spotFab_;
        vox1Fab = vox1Fab_;
        endFab = endFab_;
        esmFab = esmFab_;
        pauseFab = pauseFab_;
    }

    function deployCDPEngine() public auth {
        require(address(cdpEngine) == address(0), "VAT already deployed");
        cdpEngine = cdpEngineFab.newCDPEngine();
        spotter = spotFab.newSpotter(address(cdpEngine));

        // Internal auth
        cdpEngine.addAuthorization(address(spotter));
    }

    function deployCoin(string memory name, string memory symbol, uint8 decimals, uint256 chainId)
      public auth {
        require(address(cdpEngine) != address(0), "Missing previous step");

        // Deploy
        coin      = coinFab.newCoin(name, symbol, decimals, chainId);
        coinJoin  = coinJoinFab.newCoinJoin(address(cdpEngine), address(coin));
        coin.addAuthorization(address(coinJoin));
    }

    function deployTaxation(uint256 savings) public auth {
        require(address(cdpEngine) != address(0), "Missing previous step");

        // Deploy
        taxCollector = taxCollectorFab.newTaxCollector(address(cdpEngine));
        if (savings >= 1) pot = potFab.newPot(address(cdpEngine));

        // Internal auth
        cdpEngine.addAuthorization(address(taxCollector));
        if (savings >= 1) cdpEngine.addAuthorization(address(pot));
    }

    function deployRateSetter(
        uint version,
        address pip,
        uint span,
        uint trim,
        uint dawn,
        uint dusk,
        uint how,
        uint up,
        uint down,
        uint go
    ) public auth {
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(spotter) != address(0), "Missing previous step");
        if (version == 1) {
          require(address(pot) == address(0), "Vox1 incompatible with Pot");
        }

        // Deploy
        vox1 = vox1Fab.newVox1(address(taxCollector), address(spotter));

        // Setup
        vox1.modifyParameters("pip", pip);
        vox1.modifyParameters("span", span);
        vox1.modifyParameters("trim", trim);
        vox1.modifyParameters("dawn", dawn);
        vox1.modifyParameters("dusk", dusk);
        vox1.modifyParameters("how", how);
        vox1.modifyParameters("up", up);
        vox1.modifyParameters("down", down);
        vox1.modifyParameters("go", go);

        // Internal auth
        spotter.addAuthorization(address(vox1));
        taxCollector.addAuthorization(address(vox1));
    }

    function deployAuctions(address gov, address bin) public auth {
        require(gov != address(0), "Missing GOV address");
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(coin) != address(0), "Missing COIN address");

        // Deploy
        flap = flapFab.newFlap(address(cdpEngine));
        flop = flopFab.newFlop(address(cdpEngine), gov);

        // Setup
        flap.modifyParameters("gov", gov);
        flap.modifyParameters("join", address(coinJoin));
        flap.modifyParameters("bin", bin);
        flap.modifyParameters("bond", address(coin));

        // Internal auth
        cdpEngine.addAuthorization(address(flop));
    }

    function deployVow() public auth {
        vow = vowFab.newVow(address(cdpEngine), address(flap), address(flop));

        flap.addAuthorization(address(vow));
        flop.addAuthorization(address(vow));

        flap.modifyParameters("safe", address(vow));
        taxCollector.modifyParameters("vow", address(vow));
    }

    function deployLiquidator() public auth {
        require(address(vow) != address(0), "Missing previous step");

        // Deploy
        cat = catFab.newCat(address(cdpEngine));

        // Internal references set up
        cat.modifyParameters("vow", address(vow));

        // Internal auth
        cdpEngine.addAuthorization(address(cat));
        vow.addAuthorization(address(cat));
    }

    function deployShutdown(address gov, address pit, uint256 min) public auth {
        require(address(cat) != address(0), "Missing previous step");

        // Deploy
        end = endFab.newEnd();

        // Internal references set up
        end.modifyParameters("cdpEngine", address(cdpEngine));
        end.modifyParameters("cat", address(cat));
        end.modifyParameters("vow", address(vow));
        end.modifyParameters("spot", address(spotter));
        if (address(pot) != address(0)) {
          end.modifyParameters("pot", address(pot));
        }
        if (address(vox1) != address(0)) {
          end.modifyParameters("vox", address(vox1));
        }

        // Internal auth
        cdpEngine.addAuthorization(address(end));
        cat.addAuthorization(address(end));
        vow.addAuthorization(address(end));
        spotter.addAuthorization(address(end));
        if (address(pot) != address(0)) {
          pot.addAuthorization(address(end));
        }
        if (address(vox1) != address(0)) {
          vox1.addAuthorization(address(end));
        }

        // Deploy ESM
        esm = esmFab.newESM(gov, address(end), address(pit), min);
        end.addAuthorization(address(esm));
    }

    function deployPause(uint delay, DSAuthority authority) public auth {
        require(address(coin) != address(0), "Missing previous step");
        require(address(end) != address(0), "Missing previous step");

        pause = pauseFab.newPause(delay, address(0), authority);
    }

    function giveControl(address usr) public auth {
        cdpEngine.addAuthorization(address(usr));
        cat.addAuthorization(address(usr));
        vow.addAuthorization(address(usr));
        taxCollector.addAuthorization(address(usr));
        spotter.addAuthorization(address(usr));
        flap.addAuthorization(address(usr));
        flop.addAuthorization(address(usr));
        end.addAuthorization(address(usr));
        if (address(pot) != address(0)) {
          pot.addAuthorization(address(usr));
        }
        if (address(vox1) != address(0)) {
          vox1.addAuthorization(address(usr));
        }
    }

    function takeControl(address usr) public auth {
        cdpEngine.removeAuthorization(address(usr));
        cat.removeAuthorization(address(usr));
        vow.removeAuthorization(address(usr));
        taxCollector.removeAuthorization(address(usr));
        spotter.removeAuthorization(address(usr));
        flap.removeAuthorization(address(usr));
        flop.removeAuthorization(address(usr));
        end.removeAuthorization(address(usr));
        if (address(pot) != address(0)) {
          pot.removeAuthorization(address(usr));
        }
        if (address(vox1) != address(0)) {
          vox1.removeAuthorization(address(usr));
        }
    }

    function deployCollateral(bytes32 ilk, address adapter, address pip, uint cut) public auth {
        require(ilk != bytes32(""), "Missing ilk name");
        require(adapter != address(0), "Missing adapter address");
        require(pip != address(0), "Missing PIP address");

        // Deploy
        ilks[ilk].flip = flipFab.newFlip(address(cdpEngine), ilk);
        ilks[ilk].adapter = adapter;
        Spotter(spotter).modifyParameters(ilk, "pip", address(pip)); // Set pip

        // Internal references set up
        cat.modifyParameters(ilk, "flip", address(ilks[ilk].flip));
        cdpEngine.initializeCollateralType(ilk);
        taxCollector.initializeCollateralType(ilk);

        // Internal auth
        cdpEngine.addAuthorization(adapter);
        ilks[ilk].flip.addAuthorization(address(cat));
        ilks[ilk].flip.addAuthorization(address(end));

        // Set bid restrictions
        Flipper(address(ilks[ilk].flip)).modifyParameters("cut", cut);
        Flipper(address(ilks[ilk].flip)).modifyParameters("spot", address(spotter));
        Flipper(address(ilks[ilk].flip)).modifyParameters("feed", address(pip));
    }

    function relyOnCdpManager(address cdpManager) public auth {
        cdpEngine.addAuthorization(cdpManager);
    }

    function addAuthToFlip(bytes32 ilk, address usr) public auth {
        require(address(ilks[ilk].flip) != address(0), "Flip not initialized");
        ilks[ilk].flip.addAuthorization(usr);
    }

    function releaseAuth() public auth {
        cdpEngine.removeAuthorization(address(this));
        cat.removeAuthorization(address(this));
        vow.removeAuthorization(address(this));
        taxCollector.removeAuthorization(address(this));
        coin.removeAuthorization(address(this));
        spotter.removeAuthorization(address(this));
        flap.removeAuthorization(address(this));
        flop.removeAuthorization(address(this));
        end.removeAuthorization(address(this));
        if (address(pot) != address(0)) {
          pot.removeAuthorization(address(this));
        }
        if (address(vox1) != address(0)) {
          vox1.removeAuthorization(address(this));
        }
    }

    function addCreatorAuth() public auth {
        cdpEngine.addAuthorization(msg.sender);
    }

    function releaseAuthFlip(bytes32 ilk) public auth {
        ilks[ilk].flip.removeAuthorization(address(this));
    }
}
