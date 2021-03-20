pragma solidity 0.6.7;

import "./GebDeploy.t.base.sol";

import "../AdvancedTokenAdapters.sol";

contract GebDeployTest is GebDeployTestBase {
    uint constant HUNDRED = 10 ** 29;

    function testDeployIndex() public {
        deployIndex(bytes32("ENGLISH"));
    }

    function testDeployStable() public {
        deployStable(bytes32("ENGLISH"));
    }

    function testFailMissingSAFEEngine() public {
        gebDeploy.deployTaxation();
        gebDeploy.deployAuctions(address(prot), address(0x123), "recycling");
    }

    function testFailMissingTaxationAndAuctions() public {
        gebDeploy.deploySAFEEngine();
        gebDeploy.deployCoin("Rai Reflex Index", "RAI", 99);
        gebDeploy.deployLiquidator();
    }

    function testFailMissingLiquidator() public {
        gebDeploy.deploySAFEEngine();
        gebDeploy.deployCoin("Rai Reflex Index", "RAI", 99);
        gebDeploy.deployTaxation();
        gebDeploy.deployAuctions(address(prot), address(0x123), "recycling");
        gebDeploy.deployAccountingEngine();
        gebDeploy.deployShutdown(address(prot), address(0x0), address(0x0), 10);
    }

    function testFailMissingEnd() public {
        gebDeploy.deploySAFEEngine();
        gebDeploy.deployCoin("Rai Reflex Index", "RAI", 99);
        gebDeploy.deployTaxation();
        gebDeploy.deployAuctions(address(prot), address(0x123), "recycling");
        gebDeploy.deployAccountingEngine();
        gebDeploy.deployPause(0, authority);
    }

    function testJoinETH() public {
        deployIndex(bytes32("ENGLISH"));
        assertEq(safeEngine.tokenCollateral("ETH", address(this)), 0);
        weth.deposit{value: 1 ether}();
        assertEq(weth.balanceOf(address(this)), 1 ether);
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(address(this), 1 ether);
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(safeEngine.tokenCollateral("ETH", address(this)), 1 ether);
    }

    function testJoinCollateral() public {
        deployIndex(bytes32("ENGLISH"));
        col.mint(1 ether);
        assertEq(col.balanceOf(address(this)), 1 ether);
        assertEq(safeEngine.tokenCollateral("COL", address(this)), 0);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        assertEq(col.balanceOf(address(this)), 0);
        assertEq(safeEngine.tokenCollateral("COL", address(this)), 1 ether);
    }

    function testExitETH() public {
        deployIndex(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        ethJoin.exit(address(this), 1 ether);
        assertEq(safeEngine.tokenCollateral("ETH", address(this)), 0);
    }

    function testExitCollateral() public {
        deployIndex(bytes32("ENGLISH"));
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        colJoin.exit(address(this), 1 ether);
        assertEq(col.balanceOf(address(this)), 1 ether);
        assertEq(safeEngine.tokenCollateral("COL", address(this)), 0);
    }

    function testModifySAFECollateralizationDrawCoin() public {
        deployIndex(bytes32("ENGLISH"));
        assertEq(coin.balanceOf(address(this)), 0);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
        assertEq(safeEngine.tokenCollateral("ETH", address(this)), 0.5 ether);
        assertEq(safeEngine.coinBalance(address(this)), mul(ONE, 60 ether));

        safeEngine.approveSAFEModification(address(coinJoin));
        coinJoin.exit(address(this), 60 ether);
        assertEq(coin.balanceOf(address(this)), 60 ether);
        assertEq(safeEngine.coinBalance(address(this)), 0);
    }

    function testModifySAFECollateralizationDrawCoinCollateral() public {
        deployIndex(bytes32("ENGLISH"));
        assertEq(coin.balanceOf(address(this)), 0);
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("COL", address(this), address(this), address(this), 0.5 ether, 20 ether);

        safeEngine.approveSAFEModification(address(coinJoin));
        coinJoin.exit(address(this), 20 ether);
        assertEq(coin.balanceOf(address(this)), 20 ether);
    }

    function testModifySAFECollateralizationDrawCoinLimit() public {
        deployIndex(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether); // 0.5 * 300 / 1.5 = 100 COIN max
    }

    function testModifySAFECollateralizationDrawCoinCollateralLimit() public {
        deployIndex(bytes32("ENGLISH"));
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("COL", address(this), address(this), address(this), 0.5 ether, 20.454545454545454545 ether); // 0.5 * 45 / 1.1 = 20.454545454545454545 COIN max
    }

    function testFailModifySAFECollateralizationDrawCoinLimit() public {
        deployIndex(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether + 1);
    }

    function testFailModifySAFECollateralizationDrawCoinCollateralLimit() public {
        deployIndex(bytes32("ENGLISH"));
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("COL", address(this), address(this), address(this), 0.5 ether, 20.454545454545454545 ether + 1);
    }

    function testModifySAFECollateralizationPaybackDebt() public {
        deployIndexWithCreatorPermissions(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
        safeEngine.approveSAFEModification(address(coinJoin));
        coinJoin.exit(address(this), 60 ether);
        assertEq(coin.balanceOf(address(this)), 60 ether);
        coin.approve(address(coinJoin), uint(-1));
        coinJoin.join(address(this), 60 ether);
        assertEq(coin.balanceOf(address(this)), 0);

        assertEq(safeEngine.coinBalance(address(this)), mul(ONE, 60 ether));
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 0 ether, -60 ether);
        assertEq(safeEngine.coinBalance(address(this)), 0);
    }

    function testModifySAFECollateralizationFromAnotherUser() public {
        deployIndex(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.approveSAFEModification(address(user1));
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
    }

    function testFailModifySAFECollateralizationDust() public {
        deployIndex(bytes32("ENGLISH"));
        weth.deposit{value: 100 ether}(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.modifyParameters(address(safeEngine), "ETH", "debtFloor", mul(ONE, 20 ether));
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 100 ether, 19 ether);
    }

    function testFailModifySAFECollateralizationFromAnotherUser() public {
        deployIndex(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(this), address(this), address(this), 0.5 ether, 60 ether);
    }

    function testFailLiquidateSAFE() public {
        deployIndex(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 0.5 ether, 100 ether); // Maximum COIN

        liquidationEngine.liquidateSAFE("ETH", address(this));
    }

    function testLiquidateSAFE() public {
        deployIndex(bytes32("ENGLISH"));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", uint256(-1) / ray(1 ether));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun COIN generated

        orclETH.updateResult(300 * 10 ** 18 - 1);        // Decrease price in 1 wei
        priceSourceETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        oracleRelayer.updateCollateralPrice("ETH");

        (uint collateralAmount, uint generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 1 ether);
        assertEq(generatedDebt, 200 ether);
        liquidationEngine.liquidateSAFE("ETH", address(this));
        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 0);
        assertEq(generatedDebt, 0);
    }

    function testLiquidateSAFEPartial() public {
        deployIndex(bytes32("ENGLISH"));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", rad(1 ether) * 200); // 1 unit of collateral per batch
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);
        weth.deposit{value: 10 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 10 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 10 ether, 2000 ether); // Maximun COIN generated

        orclETH.updateResult(300 * 10 ** 18 - 1);        // Decrease price in 1 wei
        priceSourceETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei

        oracleRelayer.updateCollateralPrice("ETH");

        (uint collateralAmount, uint generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 10 ether);
        assertEq(generatedDebt, 2000 ether);
        liquidationEngine.liquidateSAFE("ETH", address(this));
        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 9 ether);
        assertEq(generatedDebt, 1800 ether);
    }

    function testEnglishCollateralAuctionHouse() public {
        deployIndex(bytes32("ENGLISH"));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", rad(1 ether) * 200); // 1 unit of collateral per batch
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun COIN generated

        orclETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        priceSourceETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        oracleRelayer.updateCollateralPrice("ETH");

        assertEq(safeEngine.tokenCollateral("ETH", address(ethEnglishCollateralAuctionHouse)), 0);
        uint batchId = liquidationEngine.liquidateSAFE("ETH", address(this));
        assertEq(safeEngine.tokenCollateral("ETH", address(ethEnglishCollateralAuctionHouse)), 1 ether);
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(150 ether));
        user2.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(160 ether));
        user1.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(180 ether));
        user2.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(200 ether));

        user1.doDecreaseSoldAmount(address(ethEnglishCollateralAuctionHouse), batchId, 0.8 ether, rad(200 ether));
        user2.doDecreaseSoldAmount(address(ethEnglishCollateralAuctionHouse), batchId, 0.7 ether, rad(200 ether));
        hevm.warp(now + (ethEnglishCollateralAuctionHouse.bidDuration() - 1));
        user1.doDecreaseSoldAmount(address(ethEnglishCollateralAuctionHouse), batchId, 0.6 ether, rad(200 ether));
        hevm.warp(now + ethEnglishCollateralAuctionHouse.totalAuctionLength());
        user1.doSettleAuction(address(ethEnglishCollateralAuctionHouse), batchId);
    }

    function testIncreasingDiscountCollateralAuctionHouse() public {
        deployIndex(bytes32("INCREASING_DISCOUNT"));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", rad(1 ether) * 200);
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun COIN generated

        orclETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        priceSourceETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        oracleRelayer.updateCollateralPrice("ETH");

        assertEq(safeEngine.tokenCollateral("ETH", address(ethIncreasingDiscountCollateralAuctionHouse)), 0);
        uint batchId = liquidationEngine.liquidateSAFE("ETH", address(this));
        assertEq(liquidationEngine.currentOnAuctionSystemCoins(), 200E45);
        assertEq(safeEngine.tokenCollateral("ETH", address(ethIncreasingDiscountCollateralAuctionHouse)), 1 ether);
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(ethIncreasingDiscountCollateralAuctionHouse));
        user1.doBuyCollateral(address(ethIncreasingDiscountCollateralAuctionHouse), batchId, 200 ether);

        assertEq(liquidationEngine.currentOnAuctionSystemCoins(), 0);
    }

    function testDebtAuctionHouse() public {
        deployIndexWithCreatorPermissions(bytes32("ENGLISH"));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", uint(-1) / ray(1 ether)); // 1 unit of collateral per batch
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 200 ether); // Maximun COIN generated

        orclETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        priceSourceETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        oracleRelayer.updateCollateralPrice("ETH");
        uint48 eraLiquidateSAFE = uint48(now);

        uint batchId = liquidationEngine.liquidateSAFE("ETH", address(this));
        address(user1).transfer(10 ether);
        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        address(user2).transfer(10 ether);
        user2.doEthJoin(address(weth), address(ethJoin), address(user2), 10 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "ETH", address(user2), address(user2), address(user2), 10 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(150 ether));
        user2.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(160 ether));
        user1.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(180 ether));

        hevm.warp(now + ethEnglishCollateralAuctionHouse.totalAuctionLength() + 1);
        user1.doSettleAuction(address(ethEnglishCollateralAuctionHouse), batchId);

        accountingEngine.popDebtFromQueue(eraLiquidateSAFE);
        accountingEngine.settleDebt(rad(180 ether));
        this.modifyParameters(address(accountingEngine), "initialDebtAuctionMintedTokens", 0.65 ether);
        this.modifyParameters(address(accountingEngine), bytes32("debtAuctionBidSize"), rad(20 ether));
        batchId = accountingEngine.auctionDebt();

        (uint bid,,,,) = debtAuctionHouse.bids(batchId);
        assertEq(bid, rad(20 ether));
        user1.doSAFEApprove(address(safeEngine), address(debtAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(debtAuctionHouse));
        user1.doDecreaseSoldAmount(address(debtAuctionHouse), batchId, 0.6 ether, rad(20 ether));
        hevm.warp(now + debtAuctionHouse.bidDuration() - 1);
        user2.doDecreaseSoldAmount(address(debtAuctionHouse), batchId, 0.2 ether, rad(20 ether));
        user1.doDecreaseSoldAmount(address(debtAuctionHouse), batchId, 0.16 ether, rad(20 ether));
        hevm.warp(now + debtAuctionHouse.totalAuctionLength() + 1);
        uint prevGovSupply = prot.totalSupply();
        user1.doSettleAuction(address(debtAuctionHouse), batchId);
        assertEq(prot.totalSupply(), prevGovSupply + 0.16 ether);
        assertEq(safeEngine.coinBalance(address(accountingEngine)), 0);
        assertEq(safeEngine.debtBalance(address(accountingEngine)) - accountingEngine.totalQueuedDebt() - accountingEngine.totalOnAuctionDebt(), 0);
        assertEq(safeEngine.debtBalance(address(accountingEngine)), 0);
    }

    function testRecyclingSurplusAuctionHouse() public {
        deployIndex(bytes32("ENGLISH"));

        this.taxSingleAndModifyParameters(address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(1.05 * 10 ** 27));
        weth.deposit{value: 0.5 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 0.5 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 0.1 ether, 10 ether);
        hevm.warp(now + 1);
        assertEq(safeEngine.coinBalance(address(accountingEngine)), 0);
        taxCollector.taxSingle("ETH");
        assertEq(safeEngine.coinBalance(address(accountingEngine)), rad(10 * 0.05 ether));
        this.modifyParameters(address(accountingEngine), bytes32("surplusAuctionAmountToSell"), rad(0.05 ether));
        uint batchId = accountingEngine.auctionSurplus();

        (,uint amountSold,,,) = recyclingSurplusAuctionHouse.bids(batchId);
        assertEq(amountSold, rad(0.05 ether));
        user1.doApprove(address(prot), address(recyclingSurplusAuctionHouse));
        user2.doApprove(address(prot), address(recyclingSurplusAuctionHouse));
        prot.transfer(address(user1), 1 ether);
        prot.transfer(address(user2), 1 ether);

        assertEq(coin.balanceOf(address(user1)), 0);
        assertEq(prot.balanceOf(address(0)), 0);

        user1.doIncreaseBidSize(address(recyclingSurplusAuctionHouse), batchId, rad(0.05 ether), 0.001 ether);
        user2.doIncreaseBidSize(address(recyclingSurplusAuctionHouse), batchId, rad(0.05 ether), 0.0015 ether);
        user1.doIncreaseBidSize(address(recyclingSurplusAuctionHouse), batchId, rad(0.05 ether), 0.0016 ether);

        assertEq(prot.balanceOf(address(user1)), 1 ether - 0.0016 ether);
        assertEq(prot.balanceOf(address(user2)), 1 ether);
        hevm.warp(now + recyclingSurplusAuctionHouse.totalAuctionLength() + 1);
        assertEq(prot.balanceOf(address(recyclingSurplusAuctionHouse)), 0.0016 ether);
        user1.doSettleAuction(address(recyclingSurplusAuctionHouse), batchId);
        assertEq(prot.balanceOf(address(surplusProtTokenReceiver)), 0.0016 ether);
        assertEq(prot.balanceOf(address(recyclingSurplusAuctionHouse)), 0);
        user1.doSAFEApprove(address(safeEngine), address(coinJoin));
        user1.doCoinExit(address(coinJoin), address(user1), 0.05 ether);
        assertEq(coin.balanceOf(address(user1)), 0.05 ether);
    }

    function testSettlementPartialLiquidation() public {
        deployIndex(bytes32("ENGLISH"));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", rad(1 ether) * 200);
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);
        weth.deposit{value: 2 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 2 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 2 ether, 400 ether); // Maximum COIN generated

        orclETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        priceSourceETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        oracleRelayer.updateCollateralPrice("ETH");

        uint batchId = liquidationEngine.liquidateSAFE("ETH", address(this));
        address(user1).transfer(10 ether);

        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        col.mint(100 ether);
        col.approve(address(colJoin), 100 ether);
        colJoin.join(address(user2), 100 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "COL", address(user2), address(user2), address(user2), 100 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(150 ether));
        user2.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(160 ether));
        assertEq(safeEngine.coinBalance(address(user2)), rad(840 ether));

        this.shutdownSystem(address(globalSettlement));
        globalSettlement.freezeCollateralType("ETH");
        globalSettlement.freezeCollateralType("COL");

        (uint collateralAmount, uint generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 1 ether);
        assertEq(generatedDebt, 200 ether);

        globalSettlement.fastTrackAuction("ETH", batchId);
        assertEq(safeEngine.coinBalance(address(user2)), rad(1000 ether));
        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 2 ether);
        assertEq(generatedDebt, 400 ether);

        globalSettlement.processSAFE("ETH", address(this));
        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(this));
        uint collateralVal = 2 ether - 400 * globalSettlement.finalCoinPerCollateralPrice("ETH") / 10 ** 9; // 2 ETH (deposited) - 400 COIN debt * ETH cage price
        assertEq(collateralAmount, collateralVal);
        assertEq(generatedDebt, 0);

        globalSettlement.freeCollateral("ETH");
        (collateralAmount,) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 0);

        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(user1));
        assertEq(collateralAmount, 10 ether);
        assertEq(generatedDebt, 1000 ether);

        globalSettlement.processSAFE("ETH", address(user1));
        globalSettlement.processSAFE("COL", address(user2));

        accountingEngine.settleDebt(safeEngine.coinBalance(address(accountingEngine)));

        globalSettlement.setOutstandingCoinSupply();

        globalSettlement.calculateCashPrice("ETH");
        globalSettlement.calculateCashPrice("COL");

        safeEngine.approveSAFEModification(address(globalSettlement));
        globalSettlement.prepareCoinsForRedeeming(400 ether);

        assertEq(safeEngine.tokenCollateral("ETH", address(this)), collateralVal);
        assertEq(safeEngine.tokenCollateral("COL", address(this)), 0);
        globalSettlement.redeemCollateral("ETH", 400 ether);
        globalSettlement.redeemCollateral("COL", 400 ether);
        assertEq(safeEngine.tokenCollateral("ETH", address(this)), collateralVal + 400 * globalSettlement.collateralCashPrice("ETH") / 10 ** 9);
        assertEq(safeEngine.tokenCollateral("COL", address(this)), 400 * globalSettlement.collateralCashPrice("COL") / 10 ** 9);
    }

    function testSettlementFullLiquidation() public {
        deployIndex(bytes32("ENGLISH"));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationQuantity", rad(200 ether));
        this.modifyParameters(address(liquidationEngine), "ETH", "liquidationPenalty", WAD);
        weth.deposit{value: 2 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 2 ether);
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 2 ether, 400 ether); // Maximum COIN generated

        orclETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        priceSourceETH.updateResult(300 * 10 ** 18 - 1); // Decrease price in 1 wei
        oracleRelayer.updateCollateralPrice("ETH");

        uint batchId = liquidationEngine.liquidateSAFE("ETH", address(this));
        address(user1).transfer(10 ether);

        user1.doEthJoin(address(weth), address(ethJoin), address(user1), 10 ether);
        user1.doModifySAFECollateralization(address(safeEngine), "ETH", address(user1), address(user1), address(user1), 10 ether, 1000 ether);

        col.mint(100 ether);
        col.approve(address(colJoin), 100 ether);
        colJoin.join(address(user2), 100 ether);
        user2.doModifySAFECollateralization(address(safeEngine), "COL", address(user2), address(user2), address(user2), 100 ether, 1000 ether);

        user1.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));
        user2.doSAFEApprove(address(safeEngine), address(ethEnglishCollateralAuctionHouse));

        user1.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(150 ether));
        user2.doIncreaseBidSize(address(ethEnglishCollateralAuctionHouse), batchId, 1 ether, rad(160 ether));
        assertEq(safeEngine.coinBalance(address(user2)), rad(840 ether));

        this.shutdownSystem(address(globalSettlement));
        globalSettlement.freezeCollateralType("ETH");
        globalSettlement.freezeCollateralType("COL");

        (uint collateralAmount, uint generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 1 ether);
        assertEq(generatedDebt, 200 ether);

        globalSettlement.fastTrackAuction("ETH", batchId);
        assertEq(safeEngine.coinBalance(address(user2)), rad(1000 ether));
        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 2 ether);
        assertEq(generatedDebt, 400 ether);

        globalSettlement.processSAFE("ETH", address(this));
        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(this));
        uint collateralVal = 2 ether - 400 * globalSettlement.finalCoinPerCollateralPrice("ETH") / 10 ** 9; // 2 ETH (deposited) - 400 COIN debt * ETH cage price
        assertEq(collateralAmount, collateralVal);
        assertEq(generatedDebt, 0);

        globalSettlement.freeCollateral("ETH");
        (collateralAmount,) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 0);

        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(user1));
        assertEq(collateralAmount, 10 ether);
        assertEq(generatedDebt, 1000 ether);

        globalSettlement.processSAFE("ETH", address(user1));
        globalSettlement.processSAFE("COL", address(user2));

        accountingEngine.settleDebt(safeEngine.coinBalance(address(accountingEngine)));

        globalSettlement.setOutstandingCoinSupply();

        globalSettlement.calculateCashPrice("ETH");
        globalSettlement.calculateCashPrice("COL");

        safeEngine.approveSAFEModification(address(globalSettlement));
        globalSettlement.prepareCoinsForRedeeming(400 ether);

        assertEq(safeEngine.tokenCollateral("ETH", address(this)), collateralVal);
        assertEq(safeEngine.tokenCollateral("COL", address(this)), 0);
        globalSettlement.redeemCollateral("ETH", 400 ether);
        globalSettlement.redeemCollateral("COL", 400 ether);
        assertEq(safeEngine.tokenCollateral("ETH", address(this)), collateralVal + 400 * globalSettlement.collateralCashPrice("ETH") / 10 ** 9);
        assertEq(safeEngine.tokenCollateral("COL", address(this)), 400 * globalSettlement.collateralCashPrice("COL") / 10 ** 9);
    }

    function testFireESM() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        prot.mint(address(user1), 10);
        user1.doESMShutdown(address(prot), address(esm), 10);
    }

    function testTransferSAFECollateralAndDebt() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        (uint collateralAmount, uint generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 1 ether);
        assertEq(generatedDebt, 60 ether);

        user1.doSAFEApprove(address(safeEngine), address(this));
        safeEngine.transferSAFECollateralAndDebt("ETH", address(this), address(user1), 0.25 ether, 15 ether);

        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(this));
        assertEq(collateralAmount, 0.75 ether);
        assertEq(generatedDebt, 45 ether);

        (collateralAmount, generatedDebt) = safeEngine.safes("ETH", address(user1));
        assertEq(collateralAmount, 0.25 ether);
        assertEq(generatedDebt, 15 ether);
    }

    function testFailTransferSAFECollateralAndDebt() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        safeEngine.transferSAFECollateralAndDebt("ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testTransferSAFECollateralAndDebtFromOtherUsr() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        safeEngine.approveSAFEModification(address(user1));
        user1.doTransferSAFECollateralAndDebt(address(safeEngine), "ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testFailTransferSAFECollateralAndDebtFromOtherUsr() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 60 ether);

        user1.doTransferSAFECollateralAndDebt(address(safeEngine), "ETH", address(this), address(user1), 0.25 ether, 15 ether);
    }

    function testFailTransferSAFECollateralAndDebtUnsafeSrc() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        safeEngine.transferSAFECollateralAndDebt("ETH", address(this), address(user1), 0.9 ether, 1 ether);
    }

    function testFailTransferSAFECollateralAndDebtUnsafeDst() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 1 ether}();
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 1 ether);

        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 1 ether, 60 ether);
        safeEngine.transferSAFECollateralAndDebt("ETH", address(this), address(user1), 0.1 ether, 59 ether);
    }

    function testFailTransferSAFECollateralAndDebtDustSrc() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 100 ether}(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.modifyParameters(address(safeEngine), "ETH", "debtFloor", mul(ONE, 20 ether));
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 100 ether, 60 ether);

        user1.doSAFEApprove(address(safeEngine), address(this));
        safeEngine.transferSAFECollateralAndDebt("ETH", address(this), address(user1), 50 ether, 19 ether);
    }

    function testFailTransferSAFECollateralAndDebtDustDst() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        weth.deposit{value: 100 ether}(); // Big number just to make sure to avoid unsafe situation
        weth.approve(address(ethJoin), uint(-1));
        ethJoin.join(address(this), 100 ether);

        this.modifyParameters(address(safeEngine), "ETH", "debtFloor", mul(ONE, 20 ether));
        safeEngine.modifySAFECollateralization("ETH", address(this), address(this), address(this), 100 ether, 60 ether);

        user1.doSAFEApprove(address(safeEngine), address(this));
        safeEngine.transferSAFECollateralAndDebt("ETH", address(this), address(user1), 50 ether, 41 ether);
    }

    function testSetPauseAuthority() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        assertEq(address(pause.authority()), address(authority));
        this.setAuthority(address(123));
        assertEq(address(pause.authority()), address(123));
    }

    function testSetPauseDelay() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        assertEq(pause.delay(), 0);
        this.setDelay(5);
        assertEq(pause.delay(), 5);
    }

    function testSetPauseAuthorityAndDelay() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.delay(), 0);
        this.setAuthorityAndDelay(address(123), 5);
        assertEq(address(pause.authority()), address(123));
        assertEq(pause.delay(), 5);
    }

    function testIndexAuthEnglishAuctionHouse() public {
        deployIndexKeepAuth(bytes32("ENGLISH"));

        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(safeEngine.authorizedAccounts(address(ethJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(colJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(safeEngine.authorizedAccounts(address(taxCollector)), 1);
        assertEq(safeEngine.authorizedAccounts(address(oracleRelayer)), 1);
        assertEq(safeEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(safeEngine.authorizedAccounts(address(pause.proxy())), 1);

        // liquidationEngine
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(pause.proxy())), 1);

        // accountingEngine
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(pause.proxy())), 1);

        // taxCollector
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(taxCollector.authorizedAccounts(address(pause.proxy())), 1);

        // coin
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(coin.authorizedAccounts(address(pause.proxy())), 1);

        // oracleRelayer
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(oracleRelayer.authorizedAccounts(address(pause.proxy())), 1);

        // stabilityFeeTreasury
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(pause.proxy())), 1);

        // recyclingSurplusAuctionHouse
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // debtAuctionHouse
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // globalSettlement
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(esm)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(pause.proxy())), 1);

        // collateralAuctionHouses
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // pause
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.owner(), address(0));

        // root
        assertTrue(authority.isUserRoot(address(this)));

        gebDeploy.releaseAuth();
        gebDeploy.releaseAuthCollateralAuctionHouse("ETH", address(gebDeploy));
        gebDeploy.releaseAuthCollateralAuctionHouse("COL", address(gebDeploy));
        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 0);
    }

    function testIndexAuthIncreasingDiscountCollateralAuctionHouse() public {
        deployIndexKeepAuth(bytes32("INCREASING_DISCOUNT"));

        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(safeEngine.authorizedAccounts(address(ethJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(colJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(safeEngine.authorizedAccounts(address(taxCollector)), 1);
        assertEq(safeEngine.authorizedAccounts(address(oracleRelayer)), 1);
        assertEq(safeEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(safeEngine.authorizedAccounts(address(pause.proxy())), 1);

        // liquidationEngine
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(pause.proxy())), 1);

        // accountingEngine
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(pause.proxy())), 1);

        // taxCollector
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(taxCollector.authorizedAccounts(address(pause.proxy())), 1);

        // coin
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(coin.authorizedAccounts(address(pause.proxy())), 1);

        // oracleRelayer
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(oracleRelayer.authorizedAccounts(address(pause.proxy())), 1);

        // stabilityFeeTreasury
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(pause.proxy())), 1);

        // recyclingSurplusAuctionHouse
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // debtAuctionHouse
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // globalSettlement
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(esm)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(pause.proxy())), 1);

        // collateralAuctionHouses
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // pause
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.owner(), address(0));

        // root
        assertTrue(authority.isUserRoot(address(this)));

        gebDeploy.releaseAuth();
        gebDeploy.releaseAuthCollateralAuctionHouse("ETH", address(gebDeploy));
        gebDeploy.releaseAuthCollateralAuctionHouse("COL", address(gebDeploy));
        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 0);
    }

    function testStableAuthEnglishAuctionHouse() public {
        deployStableKeepAuth(bytes32("ENGLISH"));

        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(safeEngine.authorizedAccounts(address(ethJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(colJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(safeEngine.authorizedAccounts(address(taxCollector)), 1);
        assertEq(safeEngine.authorizedAccounts(address(oracleRelayer)), 1);
        assertEq(safeEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(safeEngine.authorizedAccounts(address(pause.proxy())), 1);

        // liquidationEngine
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(pause.proxy())), 1);

        // accountingEngine
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(pause.proxy())), 1);

        // taxCollector
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(taxCollector.authorizedAccounts(address(pause.proxy())), 1);

        // coinSavingsAccount
        assertEq(coinSavingsAccount.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(coinSavingsAccount.authorizedAccounts(address(pause.proxy())), 1);

        // stabilityFeeTreasury
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(pause.proxy())), 1);

        // coin
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(coin.authorizedAccounts(address(pause.proxy())), 1);

        // coin join
        assertEq(coinJoin.authorizedAccounts(address(gebDeploy)), 1);

        // oracleRelayer
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(oracleRelayer.authorizedAccounts(address(pause.proxy())), 1);

        // recyclingSurplusAuctionHouse
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // debtAuctionHouse
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // globalSettlement
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(esm)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(pause.proxy())), 1);

        // collateralAuctionHouses
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // pause
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.owner(), address(0));

        // esm
        assertEq(esm.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(esm.authorizedAccounts(address(pause.proxy())), 1);

        // root
        assertTrue(authority.isUserRoot(address(this)));

        gebDeploy.releaseAuth();
        gebDeploy.releaseAuthCollateralAuctionHouse("ETH", address(gebDeploy));
        gebDeploy.releaseAuthCollateralAuctionHouse("COL", address(gebDeploy));
        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coinSavingsAccount.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coinJoin.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(ethEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(colEnglishCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(esm.authorizedAccounts(address(gebDeploy)), 0);
    }

    function testStableAuthIncreasingDiscountCollateralAuctionHouse() public {
        deployStableKeepAuth(bytes32("INCREASING_DISCOUNT"));

        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(safeEngine.authorizedAccounts(address(ethJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(colJoin)), 1);
        assertEq(safeEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(safeEngine.authorizedAccounts(address(taxCollector)), 1);
        assertEq(safeEngine.authorizedAccounts(address(oracleRelayer)), 1);
        assertEq(safeEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(safeEngine.authorizedAccounts(address(pause.proxy())), 1);

        // liquidationEngine
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(liquidationEngine.authorizedAccounts(address(pause.proxy())), 1);

        // accountingEngine
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(liquidationEngine)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(accountingEngine.authorizedAccounts(address(pause.proxy())), 1);

        // taxCollector
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(taxCollector.authorizedAccounts(address(pause.proxy())), 1);

        // coinSavingsAccount
        assertEq(coinSavingsAccount.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(coinSavingsAccount.authorizedAccounts(address(pause.proxy())), 1);

        // stabilityFeeTreasury
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(pause.proxy())), 1);

        // coin
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(coin.authorizedAccounts(address(pause.proxy())), 1);

        // coin join
        assertEq(coinJoin.authorizedAccounts(address(gebDeploy)), 1);

        // oracleRelayer
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(oracleRelayer.authorizedAccounts(address(pause.proxy())), 1);

        // recyclingSurplusAuctionHouse
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // debtAuctionHouse
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(accountingEngine)), 1);
        assertEq(debtAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // globalSettlement
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(esm)), 1);
        assertEq(globalSettlement.authorizedAccounts(address(pause.proxy())), 1);

        // collateralAuctionHouses
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(globalSettlement)), 1);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(pause.proxy())), 1);

        // pause
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.owner(), address(0));

        // esm
        assertEq(esm.authorizedAccounts(address(gebDeploy)), 1);
        assertEq(esm.authorizedAccounts(address(pause.proxy())), 1);

        // root
        assertTrue(authority.isUserRoot(address(this)));

        gebDeploy.releaseAuth();
        gebDeploy.releaseAuthCollateralAuctionHouse("ETH", address(gebDeploy));
        gebDeploy.releaseAuthCollateralAuctionHouse("COL", address(gebDeploy));
        assertEq(safeEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(liquidationEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(accountingEngine.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(taxCollector.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coinSavingsAccount.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coin.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(coinJoin.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(oracleRelayer.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(recyclingSurplusAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(debtAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(globalSettlement.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(ethIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(colIncreasingDiscountCollateralAuctionHouse.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(stabilityFeeTreasury.authorizedAccounts(address(gebDeploy)), 0);
        assertEq(esm.authorizedAccounts(address(gebDeploy)), 0);
    }
}
