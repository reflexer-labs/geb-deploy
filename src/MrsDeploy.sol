/// MrsDeploy.sol

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

import {Vat} from "mrs/vat.sol";
import {Jug} from "mrs/jug.sol";
import {Vow} from "mrs/vow.sol";
import {Cat} from "mrs/cat.sol";
import {MaiJoin} from "mrs/join.sol";
import {Flapper} from "mrs/flap.sol";
import {Flopper} from "mrs/flop.sol";
import {Flipper} from "mrs/flip.sol";
import {Mai} from "mrs/mai.sol";
import {End} from "mrs/end.sol";
import {ESM} from "./ds/esm/ESM.sol";
import {Vox} from "mrs/vox.sol";
import {Spotter} from "mrs/spot.sol";

contract VatFab {
    function newVat() public returns (Vat vat) {
        vat = new Vat();
        vat.rely(msg.sender);
        vat.deny(address(this));
    }
}

contract JugFab {
    function newJug(address vat) public returns (Jug jug) {
        jug = new Jug(vat);
        jug.rely(msg.sender);
        jug.deny(address(this));
    }
}

contract VowFab {
    function newVow(address vat, address flap, address flop) public returns (Vow vow) {
        vow = new Vow(vat, flap, flop);
        vow.rely(msg.sender);
        vow.deny(address(this));
    }
}

contract CatFab {
    function newCat(address vat) public returns (Cat cat) {
        cat = new Cat(vat);
        cat.rely(msg.sender);
        cat.deny(address(this));
    }
}

contract MaiFab {
    function newMai(uint chainId) public returns (Mai mai) {
        mai = new Mai(chainId);
        mai.rely(msg.sender);
        mai.deny(address(this));
    }
}

contract MaiJoinFab {
    function newMaiJoin(address vat, address mai) public returns (MaiJoin maiJoin) {
        maiJoin = new MaiJoin(vat, mai);
    }
}

contract FlapFab {
    function newFlap(address vat) public returns (Flapper flap) {
        flap = new Flapper(vat);
        flap.rely(msg.sender);
        flap.deny(address(this));
    }
}

contract FlopFab {
    function newFlop(address vat, address gov) public returns (Flopper flop) {
        flop = new Flopper(vat, gov);
        flop.rely(msg.sender);
        flop.deny(address(this));
    }
}

contract FlipFab {
    function newFlip(address vat, bytes32 ilk) public returns (Flipper flip) {
        flip = new Flipper(vat, ilk);
        flip.rely(msg.sender);
        flip.deny(address(this));
    }
}

contract SpotFab {
    function newSpotter(address vat) public returns (Spotter spotter) {
        spotter = new Spotter(vat);
        spotter.rely(msg.sender);
        spotter.deny(address(this));
    }
}

contract VoxFab {
    function newVox(address jug, address spot) public returns (Vox vox) {
        vox = new Vox(jug, spot);
        vox.rely(msg.sender);
        vox.deny(address(this));
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
        end.rely(msg.sender);
        end.deny(address(this));
    }
}

contract PauseFab {
    function newPause(uint delay, address owner, DSAuthority authority) public returns(DSPause pause) {
        pause = new DSPause(delay, owner, authority);
    }
}

contract MrsDeploy is DSAuth {
    VatFab       public vatFab;
    JugFab       public jugFab;
    VowFab       public vowFab;
    CatFab       public catFab;
    MaiFab       public maiFab;
    MaiJoinFab   public maiJoinFab;
    FlapFab      public flapFab;
    FlopFab      public flopFab;
    FlipFab      public flipFab;
    SpotFab      public spotFab;
    VoxFab       public voxFab;
    EndFab       public endFab;
    ESMFab       public esmFab;
    PauseFab     public pauseFab;

    Vat       public vat;
    Jug       public jug;
    Vow       public vow;
    Cat       public cat;
    Mai       public mai;
    MaiJoin   public maiJoin;
    Flapper   public flap;
    Flopper   public flop;
    Spotter   public spotter;
    Vox       public vox;
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
        VatFab vatFab_,
        JugFab jugFab_,
        VowFab vowFab_,
        CatFab catFab_,
        MaiFab maiFab_,
        MaiJoinFab maiJoinFab_
    ) public auth {
        require(address(vatFab) == address(0), "Vat Fab already set");
        vatFab = vatFab_;
        jugFab = jugFab_;
        vowFab = vowFab_;
        catFab = catFab_;
        maiFab = maiFab_;
        maiJoinFab = maiJoinFab_;
    }

    function setSecondFabBatch(
        FlapFab flapFab_,
        FlopFab flopFab_,
        FlipFab flipFab_,
        SpotFab spotFab_,
        VoxFab voxFab_,
        EndFab endFab_,
        ESMFab esmFab_,
        PauseFab pauseFab_
    ) public auth {
        require(address(vatFab) != address(0), "Vat Fab not set");
        require(address(flapFab) == address(0), "Flap Fab already set");
        flapFab = flapFab_;
        flopFab = flopFab_;
        flipFab = flipFab_;
        spotFab = spotFab_;
        voxFab = voxFab_;
        endFab = endFab_;
        esmFab = esmFab_;
        pauseFab = pauseFab_;
    }

    function deployVat() public auth {
        require(address(vat) == address(0), "VAT already deployed");
        vat = vatFab.newVat();
        spotter = spotFab.newSpotter(address(vat));

        // Internal auth
        vat.rely(address(spotter));
    }

    function deployMai(uint256 chainId) public auth {
        require(address(vat) != address(0), "Missing previous step");

        // Deploy
        mai      = maiFab.newMai(chainId);
        maiJoin  = maiJoinFab.newMaiJoin(address(vat), address(mai));
        mai.rely(address(maiJoin));
    }

    function deployTaxation() public auth {
        require(address(vat) != address(0), "Missing previous step");

        // Deploy
        jug = jugFab.newJug(address(vat));

        // Internal auth
        vat.rely(address(jug));
    }

    function deployRateSetter(
        address pip,
        uint span,
        uint trim,
        uint dawn,
        uint dusk,
        uint how,
        uint up,
        uint down
    ) public auth {
        require(address(jug) != address(0), "Missing previous step");
        require(address(spotter) != address(0), "Missing previous step");

        // Deploy
        vox = voxFab.newVox(address(jug), address(spotter));

        // Setup
        vox.file("pip", pip);
        vox.file("span", span);
        vox.file("trim", trim);
        vox.file("dawn", dawn);
        vox.file("dusk", dusk);
        vox.file("how", how);
        vox.file("up", up);
        vox.file("down", down);

        // Internal auth
        spotter.rely(address(vox));
        jug.rely(address(vox));
    }

    function deployAuctions(address gov, address bin) public auth {
        require(gov != address(0), "Missing GOV address");
        require(address(jug) != address(0), "Missing previous step");
        require(address(mai) != address(0), "Missing MAI address");

        // Deploy
        flap = flapFab.newFlap(address(vat));
        flop = flopFab.newFlop(address(vat), gov);

        // Setup
        flap.file("gov", gov);
        flap.file("join", address(maiJoin));
        flap.file("bin", bin);
        flap.file("bond", address(mai));

        // Internal auth
        vat.rely(address(flop));
    }

    function deployVow() public auth {
        vow = vowFab.newVow(address(vat), address(flap), address(flop));

        flap.rely(address(vow));
        flop.rely(address(vow));

        flap.file("safe", address(vow));
        jug.file("vow", address(vow));
    }

    function deployLiquidator() public auth {
        require(address(vow) != address(0), "Missing previous step");

        // Deploy
        cat = catFab.newCat(address(vat));

        // Internal references set up
        cat.file("vow", address(vow));

        // Internal auth
        vat.rely(address(cat));
        vow.rely(address(cat));
    }

    function deployShutdown(address gov, address pit, uint256 min) public auth {
        require(address(cat) != address(0), "Missing previous step");

        // Deploy
        end = endFab.newEnd();

        // Internal references set up
        end.file("vat", address(vat));
        end.file("cat", address(cat));
        end.file("vow", address(vow));
        end.file("spot", address(spotter));

        // Internal auth
        vat.rely(address(end));
        cat.rely(address(end));
        vow.rely(address(end));
        spotter.rely(address(end));

        // Deploy ESM
        esm = esmFab.newESM(gov, address(end), address(pit), min);
        end.rely(address(esm));
    }

    function deployPause(uint delay, DSAuthority authority) public auth {
        require(address(mai) != address(0), "Missing previous step");
        require(address(end) != address(0), "Missing previous step");

        pause = pauseFab.newPause(delay, address(0), authority);
    }

    function giveControl(address usr) public auth {
        vat.rely(address(usr));
        cat.rely(address(usr));
        vow.rely(address(usr));
        jug.rely(address(usr));
        vox.rely(address(usr));
        spotter.rely(address(usr));
        flap.rely(address(usr));
        flop.rely(address(usr));
        end.rely(address(usr));
    }

    function takeControl(address usr) public auth {
        vat.deny(address(usr));
        cat.deny(address(usr));
        vow.deny(address(usr));
        jug.deny(address(usr));
        vox.deny(address(usr));
        spotter.deny(address(usr));
        flap.deny(address(usr));
        flop.deny(address(usr));
        end.deny(address(usr));
    }

    function deployCollateral(bytes32 ilk, address adapter, address pip, uint cut) public auth {
        require(ilk != bytes32(""), "Missing ilk name");
        require(adapter != address(0), "Missing adapter address");
        require(pip != address(0), "Missing PIP address");

        // Deploy
        ilks[ilk].flip = flipFab.newFlip(address(vat), ilk);
        ilks[ilk].adapter = adapter;
        Spotter(spotter).file(ilk, "pip", address(pip)); // Set pip

        // Internal references set up
        cat.file(ilk, "flip", address(ilks[ilk].flip));
        vat.init(ilk);
        jug.init(ilk);

        // Internal auth
        vat.rely(adapter);
        ilks[ilk].flip.rely(address(cat));
        ilks[ilk].flip.rely(address(end));

        // Set bid restrictions
        Flipper(address(ilks[ilk].flip)).file("cut", cut);
        Flipper(address(ilks[ilk].flip)).file("spot", address(spotter));
        Flipper(address(ilks[ilk].flip)).file("feed", address(pip));
    }

    function relyOnCdpManager(address cdpManager) public auth {
        vat.rely(cdpManager);
    }

    function addAuthToFlip(bytes32 ilk, address usr) public auth {
        require(address(ilks[ilk].flip) != address(0), "Flip not initialized");
        ilks[ilk].flip.rely(usr);
    }

    function releaseAuth() public auth {
        vat.deny(address(this));
        cat.deny(address(this));
        vow.deny(address(this));
        jug.deny(address(this));
        vox.deny(address(this));
        mai.deny(address(this));
        spotter.deny(address(this));
        flap.deny(address(this));
        flop.deny(address(this));
        end.deny(address(this));
    }

    function addCreatorAuth() public auth {
        vat.rely(msg.sender);
    }

    function releaseAuthFlip(bytes32 ilk) public auth {
        ilks[ilk].flip.deny(address(this));
    }
}
