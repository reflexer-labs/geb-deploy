pragma solidity ^0.5.15;

import "./MrsDeploy.t.base.sol";

import "./join.sol";

contract MrsDeployTest is MrsDeployTestBase {
    uint constant ONE = 10 ** 27;
    uint constant HUNDRED = 10 ** 29;

    function testDeployBond() public {
        deployBond();
    }

    function testDeployStable() public {
        deployStable();
    }

    function testFailMissingVat() public {
        mrsDeploy.deployTaxation();
        mrsDeploy.deployAuctions(address(gov), address(bin));
    }

    function testFailMissingTaxationAndAuctions() public {
        mrsDeploy.deployVat();
        mrsDeploy.deployMai(99);
        mrsDeploy.deployLiquidator();
    }

    function testFailMissingLiquidator() public {
        mrsDeploy.deployVat();
        mrsDeploy.deployMai(99);
        mrsDeploy.deployTaxation(false);
        mrsDeploy.deployAuctions(address(gov), address(bin));
        mrsDeploy.deployVow();
        mrsDeploy.deployShutdown(address(gov), address(0x0), 10);
    }

    function testFailMissingEnd() public {
        mrsDeploy.deployVat();
        mrsDeploy.deployMai(99);
        mrsDeploy.deployTaxation(false);
        mrsDeploy.deployAuctions(address(gov), address(bin));
        mrsDeploy.deployVow();
        mrsDeploy.deployPause(0, authority);
    }

    function testJoinETH() public {
        deployBond();
        assertEq(vat.gem("ETH", address(this)), 0);
        weth.deposit.value(1 ether)();
        assertEq(weth.balanceOf(address(this)), 1 ether);
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(address(this), 1 ether);
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(vat.gem("ETH", address(this)), 1 ether);
    }

    function testJoinGem() public {
        deployBond();
        col.mint(1 ether);
        assertEq(col.balanceOf(address(this)), 1 ether);
        assertEq(vat.gem("COL", address(this)), 0);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        assertEq(col.balanceOf(address(this)), 0);
        assertEq(vat.gem("COL", address(this)), 1 ether);
    }

    function testExitETH() public {
        deployBond();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        ethJoin.exit(address(this), 1 ether);
        assertEq(vat.gem("ETH", address(this)), 0);
    }

    function testExitGem() public {
        deployBond();
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        colJoin.exit(address(this), 1 ether);
        assertEq(col.balanceOf(address(this)), 1 ether);
        assertEq(vat.gem("COL", address(this)), 0);
    }

    function testFrobDrawMai() public {
        deployBond();
        assertEq(mai.balanceOf(address(this)), 0);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
        assertEq(vat.gem("ETH", address(this)), 0.5 ether);
        assertEq(vat.mai(address(this)), mul(ONE, 60 ether));

        vat.hope(address(maiJoin));
        maiJoin.exit(address(this), 60 ether);
        assertEq(mai.balanceOf(address(this)), 60 ether);
        assertEq(vat.mai(address(this)), 0);
    }

    function testFrobDrawMaiGem() public {
        deployBond();
        assertEq(mai.balanceOf(address(this)), 0);
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);

        vat.frob("COL", address(this), address(this), address(this), 0.5 ether, 20 ether);

        vat.hope(address(maiJoin));
        maiJoin.exit(address(this), 20 ether);
        assertEq(mai.balanceOf(address(this)), 20 ether);
    }

    function testFrobDrawMaiLimit() public {
        deployBond();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether); // 0.5 * 300 / 1.5 = 100 MAI max
    }

    function testFrobDrawMaiGemLimit() public {
        deployBond();
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        vat.frob("COL", address(this), address(this), address(this), 0.5 ether, 20.454545454545454545 ether); // 0.5 * 45 / 1.1 = 20.454545454545454545 MAI max
    }

    function testFailFrobDrawMaiLimit() public {
        deployBond();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether + 1);
    }

    function testFailFrobDrawMaiGemLimit() public {
        deployBond();
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        vat.frob("COL", address(this), address(this), address(this), 0.5 ether, 20.454545454545454545 ether + 1);
    }

    function testFrobPaybackMai() public {
        deployBondWithVatPermissions();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
        vat.hope(address(maiJoin));
        maiJoin.exit(address(this), 60 ether);
        assertEq(mai.balanceOf(address(this)), 60 ether);
        mai.approve(address(maiJoin), uint(-1));
        maiJoin.join(address(this), 60 ether);
        assertEq(mai.balanceOf(address(this)), 0);

        assertEq(vat.mai(address(this)), mul(ONE, 60 ether));
        vat.frob("ETH", address(this), address(this), address(this), 0 ether, -60 ether);
        assertEq(vat.mai(address(this)), 0);
    }

    function testFrobFromAnotherUser() public {
        deployBond();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.hope(address(user1));
        user1.doFrob(address(vat), "ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
    }

    function testFailFrobDust() public {
        deployBond();
        weth.deposit.value(100 ether)(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.file(address(vat), "ETH", "dust", mul(ONE, 20 ether));
        vat.frob("ETH", address(this), address(this), address(this), 100 ether, 19 ether);
    }

    function testFailFrobFromAnotherUser() public {
        deployBond();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        user1.doFrob(address(vat), "ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
    }

    function testFailBite() public {
        deployBond();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether); // Maximum MAI

        cat.bite("ETH", address(this));
    }

    function testBite() public {
        deployBond();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun MAI generated

        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");

        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 1 ether);
        assertEq(art, 200 ether);
        cat.bite("ETH", address(this));
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 0);
        assertEq(art, 0);
    }

    function testBitePartial() public {
        deployBond();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(10 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 10 ether);
        vat.frob("ETH", address(this), address(this), address(this), 10 ether, 2000 ether); // Maximun MAI generated

        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");

        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 10 ether);
        assertEq(art, 2000 ether);
        cat.bite("ETH", address(this));
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 9 ether);
        assertEq(art, 1800 ether);
    }

    function testFlip() public {
        deployBond();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun MAI generated
        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");
        assertEq(vat.gem("ETH", address(ethFlip)), 0);
        uint batchId = cat.bite("ETH", address(this));
        assertEq(vat.gem("ETH", address(ethFlip)), 1 ether);
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doFrob(address(vat), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doFrob(address(vat), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doHope(address(vat), address(ethFlip));
        user2.doHope(address(vat), address(ethFlip));

        user1.doTend(address(ethFlip), batchId, 1 ether, rad(150 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(160 ether));
        user1.doTend(address(ethFlip), batchId, 1 ether, rad(180 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(200 ether));

        user1.doDent(address(ethFlip), batchId, 0.8 ether, rad(200 ether));
        user2.doDent(address(ethFlip), batchId, 0.7 ether, rad(200 ether));
        hevm.warp(ethFlip.ttl() - 1);
        user1.doDent(address(ethFlip), batchId, 0.6 ether, rad(200 ether));
        hevm.warp(now + ethFlip.ttl() + 1);
        user1.doDeal(address(ethFlip), batchId);
    }

    function testFlop() public {
        deployBond();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun MAI generated
        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");
        uint48 eraBite = uint48(now);
        uint batchId = cat.bite("ETH", address(this));
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doFrob(address(vat), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doFrob(address(vat), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doHope(address(vat), address(ethFlip));
        user2.doHope(address(vat), address(ethFlip));

        user1.doTend(address(ethFlip), batchId, 1 ether, rad(150 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(160 ether));
        user1.doTend(address(ethFlip), batchId, 1 ether, rad(180 ether));

        hevm.warp(now + ethFlip.ttl() + 1);
        user1.doDeal(address(ethFlip), batchId);

        vow.flog(eraBite);
        vow.heal(rad(180 ether));
        this.file(address(vow), "dump", 0.65 ether);
        this.file(address(vow), bytes32("sump"), rad(20 ether));
        batchId = vow.flop();

        (uint bid,,,,) = flop.bids(batchId);
        assertEq(bid, rad(20 ether));
        user1.doHope(address(vat), address(flop));
        user2.doHope(address(vat), address(flop));
        user1.doDent(address(flop), batchId, 0.6 ether, rad(20 ether));
        hevm.warp(now + flop.ttl() - 1);
        user2.doDent(address(flop), batchId, 0.2 ether, rad(20 ether));
        user1.doDent(address(flop), batchId, 0.16 ether, rad(20 ether));
        hevm.warp(now + flop.ttl() + 1);
        uint prevGovSupply = gov.totalSupply();
        user1.doDeal(address(flop), batchId);
        assertEq(gov.totalSupply(), prevGovSupply + 0.16 ether);
        vow.kiss(rad(20 ether));
        assertEq(vat.mai(address(vow)), 0);
        assertEq(vat.sin(address(vow)) - vow.Sin() - vow.Ash(), 0);
        assertEq(vat.sin(address(vow)), 0);
    }

    function testFlap() public {
        deployBond();
        this.dripAndFile(address(jug), bytes32("ETH"), bytes32("duty"), uint(1.05 * 10 ** 27));
        weth.deposit.value(0.5 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 0.5 ether);
        vat.frob("ETH", address(this), address(this), address(this), 0.1 ether, 10 ether);
        hevm.warp(now + 100);
        jug.drip("ETH");

        assertEq(vow.hump(), 0);
        assertEq(vat.mai(address(vow)), 1305012578463034550255975321520000000000000000000);

        this.file(address(vow), bytes32("bump"), rad(1 ether));
        uint batchId = vow.flap();

        assertEq(gov.balanceOf(address(bin)), 49 ether);
        assertEq(gov.totalSupply(), 149 ether);
        assertEq(gov.balanceOf(address(flap)), 0);
        assertEq(mai.balanceOf(address(flap)), 0);
    }

    function testVox() public {
        deployBond();
        jug.drip();
        vox1.back();
        assertEq(vox1.way(), ray(1 ether));
        assertEq(jug.base(), 1000000000158153903837946258);
        pipMAI.poke(bytes32(uint(1.05 ether)));
        hevm.warp(now + 1 seconds);
        jug.drip();
        vox1.back();
        assertEq(vox1.way(), 999999998452874042136787551);
        assertEq(jug.base(), 1000000000158153903837946258); // because of bounds it's kept constant
    }

    function testEnd() public {
        deployBond();
        this.file(address(cat), "ETH", "lump", 1 ether); // 1 unit of collateral per batch
        this.file(address(cat), "ETH", "chop", ONE);
        weth.deposit.value(2 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 2 ether);
        vat.frob("ETH", address(this), address(this), address(this), 2 ether, 400 ether); // Maximum MAI generated
        pipETH.poke(bytes32(uint(300 * 10 ** 18 - 1))); // Decrease price in 1 wei
        spotter.poke("ETH");
        uint batchId = cat.bite("ETH", address(this)); // The CDP remains unsafe after 1st batch is bitten
        address(user1).transfer(10 ether);

        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doFrob(address(vat), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        col.mint(100 ether);
        col.approve(address(colJoin), 100 ether);
        colJoin.join(address(user2), 100 ether);
        user2.doFrob(address(vat), "COL", address(user2), address(user2), address(user2), 100 ether, 1000 ether);

        user1.doHope(address(vat), address(ethFlip));
        user2.doHope(address(vat), address(ethFlip));

        user1.doTend(address(ethFlip), batchId, 1 ether, rad(150 ether));
        user2.doTend(address(ethFlip), batchId, 1 ether, rad(160 ether));
        assertEq(vat.mai(address(user2)), rad(840 ether));

        this.cage(address(end));
        end.cage("ETH");
        end.cage("COL");

        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 1 ether);
        assertEq(art, 200 ether);

        end.skip("ETH", batchId);
        assertEq(vat.mai(address(user2)), rad(1000 ether));
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 2 ether);
        assertEq(art, 400 ether);

        end.skim("ETH", address(this));
        (ink, art) = vat.urns("ETH", address(this));
        uint remainInkVal = 2 ether - 400 * end.tag("ETH") / 10 ** 9; // 2 ETH (deposited) - 400 MAI debt * ETH cage price
        assertEq(ink, remainInkVal);
        assertEq(art, 0);

        end.free("ETH");
        (ink,) = vat.urns("ETH", address(this));
        assertEq(ink, 0);

        (ink, art) = vat.urns("ETH", address(user1));
        assertEq(ink, 10 ether);
        assertEq(art, 1000 ether);

        end.skim("ETH", address(user1));
        end.skim("COL", address(user2));

        vow.heal(vat.mai(address(vow)));

        end.thaw();

        end.flow("ETH");
        end.flow("COL");

        vat.hope(address(end));
        end.pack(400 ether);

        assertEq(vat.gem("ETH", address(this)), remainInkVal);
        assertEq(vat.gem("COL", address(this)), 0);
        end.cash("ETH", 400 ether);
        end.cash("COL", 400 ether);
        assertEq(vat.gem("ETH", address(this)), remainInkVal + 400 * end.fix("ETH") / 10 ** 9);
        assertEq(vat.gem("COL", address(this)), 400 * end.fix("COL") / 10 ** 9);
    }

    function testFireESM() public {
        deployBondKeepAuth();
        gov.mint(address(user1), 10);

        user1.doESMJoin(address(gov), address(esm), 10);
        esm.fire();
    }

    function testFork() public {
        deployBondKeepAuth();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        (uint ink, uint art) = vat.urns("ETH", address(this));
        assertEq(ink, 1 ether);
        assertEq(art, 60 ether);

        user1.doHope(address(vat), address(this));
        vat.fork("ETH", address(this), address(user1), 0.25 ether, 15 ether);

        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 0.75 ether);
        assertEq(art, 45 ether);

        (ink, art) = vat.urns("ETH", address(user1));
        assertEq(ink, 0.25 ether);
        assertEq(art, 15 ether);
    }

    function testFailFork() public {
        deployBondKeepAuth();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        vat.fork("ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testForkFromOtherUsr() public {
        deployBondKeepAuth();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        vat.hope(address(user1));
        user1.doFork(address(vat), "ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testFailForkFromOtherUsr() public {
        deployBondKeepAuth();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        user1.doFork(address(vat), "ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testFailForkUnsafeSrc() public {
        deployBondKeepAuth();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        vat.fork("ETH", address(this), address(user1), 0.9 ether, 1 ether);
    }

    function testFailForkUnsafeDst() public {
        deployBondKeepAuth();
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        vat.frob("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        vat.fork("ETH", address(this), address(user1), 0.1 ether, 59 ether);
    }

    function testFailForkDustSrc() public {
        deployBondKeepAuth();
        weth.deposit.value(100 ether)(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.file(address(vat), "ETH", "dust", mul(ONE, 20 ether));
        vat.frob("ETH", address(this), address(this), address(this), 100 ether, 60 ether);

        user1.doHope(address(vat), address(this));
        vat.fork("ETH", address(this), address(user1), 50 ether, 19 ether);
    }

    function testFailForkDustDst() public {
        deployBondKeepAuth();
        weth.deposit.value(100 ether)(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.file(address(vat), "ETH", "dust", mul(ONE, 20 ether));
        vat.frob("ETH", address(this), address(this), address(this), 100 ether, 60 ether);

        user1.doHope(address(vat), address(this));
        vat.fork("ETH", address(this), address(user1), 50 ether, 41 ether);
    }

    function testSetPauseAuthority() public {
        deployBondKeepAuth();
        assertEq(address(pause.authority()), address(authority));
        this.setAuthority(address(123));
        assertEq(address(pause.authority()), address(123));
    }

    function testSetPauseDelay() public {
        deployBondKeepAuth();
        assertEq(pause.delay(), 0);
        this.setDelay(5);
        assertEq(pause.delay(), 5);
    }

    function testSetPauseAuthorityAndDelay() public {
        deployBondKeepAuth();
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.delay(), 0);
        this.setAuthorityAndDelay(address(123), 5);
        assertEq(address(pause.authority()), address(123));
        assertEq(pause.delay(), 5);
    }

    function testBondAuth() public {
        deployBondKeepAuth();

        assertEq(vat.wards(address(mrsDeploy)), 1);
        assertEq(vat.wards(address(ethJoin)), 1);
        assertEq(vat.wards(address(colJoin)), 1);
        assertEq(vat.wards(address(cat)), 1);
        assertEq(vat.wards(address(jug)), 1);
        assertEq(vat.wards(address(spotter)), 1);
        assertEq(vat.wards(address(end)), 1);
        assertEq(vat.wards(address(pause.proxy())), 1);

        // cat
        assertEq(cat.wards(address(mrsDeploy)), 1);
        assertEq(cat.wards(address(end)), 1);
        assertEq(cat.wards(address(pause.proxy())), 1);

        // vow
        assertEq(vow.wards(address(mrsDeploy)), 1);
        assertEq(vow.wards(address(cat)), 1);
        assertEq(vow.wards(address(end)), 1);
        assertEq(vow.wards(address(pause.proxy())), 1);

        // jug
        assertEq(jug.wards(address(mrsDeploy)), 1);
        assertEq(jug.wards(address(pause.proxy())), 1);

        // vox
        assertEq(vox1.wards(address(mrsDeploy)), 1);
        assertEq(vox1.wards(address(pause.proxy())), 1);

        // mai
        assertEq(mai.wards(address(mrsDeploy)), 1);

        // spotter
        assertEq(spotter.wards(address(mrsDeploy)), 1);
        assertEq(spotter.wards(address(pause.proxy())), 1);

        // flap
        assertEq(flap.wards(address(mrsDeploy)), 1);
        assertEq(flap.wards(address(vow)), 1);
        assertEq(flap.wards(address(pause.proxy())), 1);

        // flop
        assertEq(flop.wards(address(mrsDeploy)), 1);
        assertEq(flop.wards(address(vow)), 1);
        assertEq(flop.wards(address(pause.proxy())), 1);

        // end
        assertEq(end.wards(address(mrsDeploy)), 1);
        assertEq(end.wards(address(esm)), 1);
        assertEq(end.wards(address(pause.proxy())), 1);

        // flips
        assertEq(ethFlip.wards(address(mrsDeploy)), 1);
        assertEq(ethFlip.wards(address(end)), 1);
        assertEq(ethFlip.wards(address(pause.proxy())), 1);
        assertEq(colFlip.wards(address(mrsDeploy)), 1);
        assertEq(colFlip.wards(address(end)), 1);
        assertEq(colFlip.wards(address(pause.proxy())), 1);

        // pause
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.owner(), address(0));

        // root
        assertTrue(authority.isUserRoot(address(this)));

        mrsDeploy.releaseAuth();
        mrsDeploy.releaseAuthFlip("ETH");
        mrsDeploy.releaseAuthFlip("COL");
        assertEq(vat.wards(address(mrsDeploy)), 0);
        assertEq(cat.wards(address(mrsDeploy)), 0);
        assertEq(vow.wards(address(mrsDeploy)), 0);
        assertEq(jug.wards(address(mrsDeploy)), 0);
        assertEq(vox1.wards(address(mrsDeploy)), 0);
        assertEq(mai.wards(address(mrsDeploy)), 0);
        assertEq(spotter.wards(address(mrsDeploy)), 0);
        assertEq(flap.wards(address(mrsDeploy)), 0);
        assertEq(flop.wards(address(mrsDeploy)), 0);
        assertEq(end.wards(address(mrsDeploy)), 0);
        assertEq(ethFlip.wards(address(mrsDeploy)), 0);
        assertEq(colFlip.wards(address(mrsDeploy)), 0);
    }

    function testStableAuth() public {
        deployStableKeepAuth();

        assertEq(vat.wards(address(mrsDeploy)), 1);
        assertEq(vat.wards(address(ethJoin)), 1);
        assertEq(vat.wards(address(colJoin)), 1);
        assertEq(vat.wards(address(cat)), 1);
        assertEq(vat.wards(address(jug)), 1);
        assertEq(vat.wards(address(spotter)), 1);
        assertEq(vat.wards(address(end)), 1);
        assertEq(vat.wards(address(pause.proxy())), 1);

        // cat
        assertEq(cat.wards(address(mrsDeploy)), 1);
        assertEq(cat.wards(address(end)), 1);
        assertEq(cat.wards(address(pause.proxy())), 1);

        // vow
        assertEq(vow.wards(address(mrsDeploy)), 1);
        assertEq(vow.wards(address(cat)), 1);
        assertEq(vow.wards(address(end)), 1);
        assertEq(vow.wards(address(pause.proxy())), 1);

        // jug
        assertEq(jug.wards(address(mrsDeploy)), 1);
        assertEq(jug.wards(address(pause.proxy())), 1);

        // pot
        assertEq(pot.wards(address(mrsDeploy)), 1);
        assertEq(pot.wards(address(pause.proxy())), 1);

        // mai
        assertEq(mai.wards(address(mrsDeploy)), 1);

        // spotter
        assertEq(spotter.wards(address(mrsDeploy)), 1);
        assertEq(spotter.wards(address(pause.proxy())), 1);

        // flap
        assertEq(flap.wards(address(mrsDeploy)), 1);
        assertEq(flap.wards(address(vow)), 1);
        assertEq(flap.wards(address(pause.proxy())), 1);

        // flop
        assertEq(flop.wards(address(mrsDeploy)), 1);
        assertEq(flop.wards(address(vow)), 1);
        assertEq(flop.wards(address(pause.proxy())), 1);

        // end
        assertEq(end.wards(address(mrsDeploy)), 1);
        assertEq(end.wards(address(esm)), 1);
        assertEq(end.wards(address(pause.proxy())), 1);

        // flips
        assertEq(ethFlip.wards(address(mrsDeploy)), 1);
        assertEq(ethFlip.wards(address(end)), 1);
        assertEq(ethFlip.wards(address(pause.proxy())), 1);
        assertEq(colFlip.wards(address(mrsDeploy)), 1);
        assertEq(colFlip.wards(address(end)), 1);
        assertEq(colFlip.wards(address(pause.proxy())), 1);

        // pause
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.owner(), address(0));

        // root
        assertTrue(authority.isUserRoot(address(this)));

        mrsDeploy.releaseAuth();
        mrsDeploy.releaseAuthFlip("ETH");
        mrsDeploy.releaseAuthFlip("COL");
        assertEq(vat.wards(address(mrsDeploy)), 0);
        assertEq(cat.wards(address(mrsDeploy)), 0);
        assertEq(vow.wards(address(mrsDeploy)), 0);
        assertEq(jug.wards(address(mrsDeploy)), 0);
        assertEq(pot.wards(address(mrsDeploy)), 0);
        assertEq(mai.wards(address(mrsDeploy)), 0);
        assertEq(spotter.wards(address(mrsDeploy)), 0);
        assertEq(flap.wards(address(mrsDeploy)), 0);
        assertEq(flop.wards(address(mrsDeploy)), 0);
        assertEq(end.wards(address(mrsDeploy)), 0);
        assertEq(ethFlip.wards(address(mrsDeploy)), 0);
        assertEq(colFlip.wards(address(mrsDeploy)), 0);
    }
}
