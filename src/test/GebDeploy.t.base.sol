pragma solidity 0.6.7;

import {DSTest} from "ds-test/test.sol";
import {DSToken} from "ds-token/token.sol";
import {DSValue} from "ds-value/value.sol";
import {DSRoles} from "ds-roles/roles.sol";
import {DSGuard} from "ds-guard/guard.sol";
import {WETH9_} from "ds-weth/weth9.sol";

import "../GebDeploy.sol";
import {CollateralJoin1, CollateralJoin6} from "../AdvancedTokenAdapters.sol";
import {GovActions} from "../GovActions.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

abstract contract AuctionLike {
    function increaseBidSize(uint, uint, uint) virtual public;
    function buyCollateral(uint, uint) virtual public;
    function decreaseSoldAmount(uint, uint, uint) virtual public;
    function settleAuction(uint) virtual public;
}

abstract contract SAFEApprovalLike {
    function approveSAFEModification(address guy) virtual public;
}

contract ProtocolTokenAuthority {
    mapping (address => uint) public authorizedAccounts;

    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external {
        authorizedAccounts[account] = 1;
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external {
        authorizedAccounts[account] = 0;
    }
}

contract FakeUser {
    function doApprove(address token, address guy) public {
        DSToken(token).approve(guy);
    }

    function doCoinJoin(address obj, address safe, uint wad) public {
        CoinJoin(obj).join(safe, wad);
    }

    function doCoinExit(address obj, address guy, uint wad) public {
        CoinJoin(obj).exit(guy, wad);
    }

    function doEthJoin(address payable obj, address collateralSource, address safe, uint wad) public {
        WETH9_(obj).deposit{value: wad}();
        WETH9_(obj).approve(address(collateralSource), uint(-1));
        CollateralJoin1(collateralSource).join(safe, wad);
    }

    function doModifySAFECollateralization(
      address obj, bytes32 collateralType, address safe, address collateralSource, address coin, int deltaCollateral, int deltaDebt
    ) public {
        SAFEEngine(obj).modifySAFECollateralization(collateralType, safe, collateralSource, coin, deltaCollateral, deltaDebt);
    }

    function doTransferSAFECollateralAndDebt(
      address obj, bytes32 collateralType, address src, address dst, int deltaCollateral, int deltaDebt
    ) public {
        SAFEEngine(obj).transferSAFECollateralAndDebt(collateralType, src, dst, deltaCollateral, deltaDebt);
    }

    function doSAFEApprove(address approval, address guy) public {
        SAFEApprovalLike(approval).approveSAFEModification(guy);
    }

    function doIncreaseBidSize(address auction, uint id, uint amountToBuy, uint bid) public {
        AuctionLike(auction).increaseBidSize(id, amountToBuy, bid);
    }

    function doBuyCollateral(address auction, uint id, uint bid) public {
        AuctionLike(auction).buyCollateral(id, bid);
    }

    function doDecreaseSoldAmount(address obj, uint id, uint amountToBuy, uint bid) public {
        AuctionLike(obj).decreaseSoldAmount(id, amountToBuy, bid);
    }

    function doSettleAuction(address obj, uint id) public {
        AuctionLike(obj).settleAuction(id);
    }

    function doGlobalSettlementFreeCollateral(address globalSettlement, bytes32 collateralType) public {
        GlobalSettlement(globalSettlement).freeCollateral(collateralType);
    }

    function doESMShutdown(address collateralSource, address esm, uint256 wad) public {
        DSToken(collateralSource).approve(esm, uint256(-1));
        ESM(esm).shutdown();
    }

    receive() external payable {}
}

abstract contract DSPauseLike {
    function owner() virtual public view returns (address);
    function authority() virtual public view returns (address);
    function delay() virtual public view returns (uint256);
    function delayMultiplier() virtual public view returns (uint256);
    function proxy() virtual public view returns (address);
    function protester() virtual public view returns (address);
    function getTransactionDataHash(address, bytes32, bytes memory, uint)
        virtual public pure
        returns (bytes32);
    function protestAgainstTransaction(address usr, bytes32 codeHash, bytes memory parameters) virtual public;
    function scheduleTransaction(address, bytes32, bytes memory, uint) virtual public;
    function scheduleTransaction(address, bytes32, bytes memory, uint, string memory) virtual public;
    function attachTransactionDescription(address, bytes32, bytes memory, uint, string memory) virtual public;
    function abandonTransaction(address, bytes32, bytes memory, uint) virtual public;
    function executeTransaction(address usr, bytes32 codeHash, bytes memory parameters, uint earliestExecutionTime)
        virtual public
        returns (bytes memory);
}

contract Feed is DSValue {
    function set_price_source(address priceSource_) external {
        priceSource = priceSource_;
    }
}

contract ProxyActions {
    DSPauseLike pause;
    GovActions govActions;

    function modifyParameters(address who, bytes32 parameter, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("modifyParameters(address,bytes32,uint256)", who, parameter, data);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function modifyParameters(address who, bytes32 collateralType, bytes32 parameter, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("modifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function updateRateAndModifyParameters(address who, bytes32 parameter, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("updateRateAndModifyParameters(address,bytes32,uint256)", who, parameter, data);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function taxManyAndModifyParameters(address who, bytes32 parameter, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("taxManyAndModifyParameters(address,bytes32,uint256)", who, parameter, data);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function taxSingleAndModifyParameters(address who, bytes32 collateralType, bytes32 parameter, uint256 data) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("taxSingleAndModifyParameters(address,bytes32,bytes32,uint256)", who, collateralType, parameter, data);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function shutdownSystem(address globalSettlement) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("shutdownSystem(address)", globalSettlement);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function setAuthority(address newAuthority) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("setAuthority(address,address)", pause, newAuthority);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function setDelay(uint newDelay) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("setDelay(address,uint256)", pause, newDelay);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function setAuthorityAndDelay(address newAuthority, uint newDelay) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function setAllowance(address join, address account, uint allowance) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("setAllowance(address,address,uint256)", join, account, allowance);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }

    function multiSetAllowance(address join, address[] calldata accounts, uint[] calldata allowances) external {
        address      usr = address(govActions);
        bytes32      tag;  assembly { tag := extcodehash(usr) }
        bytes memory fax = abi.encodeWithSignature("multiSetAllowance(address,address[],uint256[])", join, accounts, allowances);
        uint         eta = now;

        pause.scheduleTransaction(usr, tag, fax, eta);
        pause.executeTransaction(usr, tag, fax, eta);
    }
}

contract GebDeployTestBase is DSTest, ProxyActions {
    Hevm hevm;

    SAFEEngineFactory                               safeEngineFactory;
    TaxCollectorFactory                             taxCollectorFactory;
    AccountingEngineFactory                         accountingEngineFactory;
    LiquidationEngineFactory                        liquidationEngineFactory;
    StabilityFeeTreasuryFactory                     stabilityFeeTreasuryFactory;
    CoinFactory                                     coinFactory;
    CoinJoinFactory                                 coinJoinFactory;
    RecyclingSurplusAuctionHouseFactory             recyclingSurplusAuctionHouseFactory;
    BurningSurplusAuctionHouseFactory               burningSurplusAuctionHouseFactory;
    DebtAuctionHouseFactory                         debtAuctionHouseFactory;
    EnglishCollateralAuctionHouseFactory            englishCollateralAuctionHouseFactory;
    IncreasingDiscountCollateralAuctionHouseFactory increasingDiscountCollateralAuctionHouseFactory;
    OracleRelayerFactory                            oracleRelayerFactory;
    GlobalSettlementFactory                         globalSettlementFactory;
    ESMFactory                                      esmFactory;
    CoinSavingsAccountFactory                       coinSavingsAccountFactory;
    PauseFactory                                    pauseFactory;
    ProtestPauseFactory                             protestPauseFactory;

    GebDeploy gebDeploy;

    DSToken prot;

    Feed orclETH;
    Feed orclCOL;
    Feed orclCOIN;

    Feed priceSourceETH;
    Feed priceSourceCOL;
    Feed priceSourceCOIN;

    DSRoles authority;

    WETH9_ weth;
    CollateralJoin1 ethJoin;
    CollateralJoin1 colJoin;
    CollateralJoin6 col6Join;

    SAFEEngine                        safeEngine;
    TaxCollector                      taxCollector;
    AccountingEngine                  accountingEngine;
    LiquidationEngine                 liquidationEngine;
    StabilityFeeTreasury              stabilityFeeTreasury;
    Coin                              coin;
    CoinJoin                          coinJoin;
    BurningSurplusAuctionHouse        burningSurplusAuctionHouse;
    RecyclingSurplusAuctionHouse      recyclingSurplusAuctionHouse;
    DebtAuctionHouse                  debtAuctionHouse;
    OracleRelayer                     oracleRelayer;
    CoinSavingsAccount                coinSavingsAccount;
    GlobalSettlement                  globalSettlement;
    ESM                               esm;

    EnglishCollateralAuctionHouse            ethEnglishCollateralAuctionHouse;
    IncreasingDiscountCollateralAuctionHouse ethIncreasingDiscountCollateralAuctionHouse;

    DSToken                                  col;
    EnglishCollateralAuctionHouse            colEnglishCollateralAuctionHouse;
    IncreasingDiscountCollateralAuctionHouse colIncreasingDiscountCollateralAuctionHouse;

    DSToken                                  col6;

    ProtocolTokenAuthority tokenAuthority;

    FakeUser user1;
    FakeUser user2;
    FakeUser surplusProtTokenReceiver;

    bytes32[] collateralTypes;

    uint protesterLifetime;

    bytes32 PAUSE_TYPE = keccak256(abi.encodePacked("BASIC"));

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function ray(uint x) internal pure returns (uint z) {
        z = x * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function setUp() virtual public {
        safeEngineFactory = new SAFEEngineFactory();
        taxCollectorFactory = new TaxCollectorFactory();
        accountingEngineFactory = new AccountingEngineFactory();
        liquidationEngineFactory = new LiquidationEngineFactory();
        coinFactory = new CoinFactory();
        coinJoinFactory = new CoinJoinFactory();
        burningSurplusAuctionHouseFactory = new BurningSurplusAuctionHouseFactory();
        recyclingSurplusAuctionHouseFactory = new RecyclingSurplusAuctionHouseFactory();
        debtAuctionHouseFactory = new DebtAuctionHouseFactory();
        englishCollateralAuctionHouseFactory = new EnglishCollateralAuctionHouseFactory();
        increasingDiscountCollateralAuctionHouseFactory = new IncreasingDiscountCollateralAuctionHouseFactory();
        oracleRelayerFactory = new OracleRelayerFactory();
        stabilityFeeTreasuryFactory = new StabilityFeeTreasuryFactory();
        globalSettlementFactory = new GlobalSettlementFactory();
        pauseFactory = new PauseFactory();
        protestPauseFactory = new ProtestPauseFactory();
        govActions = new GovActions();
        esmFactory = new ESMFactory();
        coinSavingsAccountFactory = new CoinSavingsAccountFactory();

        gebDeploy = new GebDeploy();

        gebDeploy.setFirstFactoryBatch(
          safeEngineFactory,
          taxCollectorFactory,
          accountingEngineFactory,
          liquidationEngineFactory,
          coinFactory,
          coinJoinFactory,
          coinSavingsAccountFactory
        );

        gebDeploy.setSecondFactoryBatch(
          recyclingSurplusAuctionHouseFactory,
          burningSurplusAuctionHouseFactory,
          debtAuctionHouseFactory,
          englishCollateralAuctionHouseFactory,
          increasingDiscountCollateralAuctionHouseFactory,
          oracleRelayerFactory,
          globalSettlementFactory,
          esmFactory
        );

        gebDeploy.setThirdFactoryBatch(
          pauseFactory,
          protestPauseFactory,
          stabilityFeeTreasuryFactory
        );

        tokenAuthority = new ProtocolTokenAuthority();
        prot = new DSToken("PROT", "PROT");
        prot.setAuthority(new DSGuard());

        orclETH = new Feed();
        orclCOL = new Feed();
        orclCOIN = new Feed();

        priceSourceETH = new Feed();
        priceSourceCOL = new Feed();
        priceSourceCOIN = new Feed();

        orclETH.set_price_source(address(priceSourceETH));
        orclCOL.set_price_source(address(priceSourceCOL));
        orclCOIN.set_price_source(address(priceSourceCOIN));

        authority = new DSRoles();
        authority.setRootUser(address(this), true);

        user1 = new FakeUser();
        user2 = new FakeUser();
        surplusProtTokenReceiver = new FakeUser();
        address(user1).transfer(100 ether);
        address(user2).transfer(100 ether);

        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);
    }

    function togglePauseType() external {
        if (PAUSE_TYPE == keccak256(abi.encodePacked("BASIC"))) {
          PAUSE_TYPE = keccak256(abi.encodePacked("PROTEST"));
        } else {
          PAUSE_TYPE = keccak256(abi.encodePacked("BASIC"));
        }
    }

    function setProtesterLifetime(uint lifetime) public {
        protesterLifetime = lifetime;
    }

    function deployIndexKeepAuth(bytes32 auctionType) virtual public {
        prot.mint(100 ether);

        gebDeploy.deploySAFEEngine();
        gebDeploy.deployCoin("Rai Reflex Index", "RAI", 99);
        gebDeploy.deployTaxation();
        gebDeploy.deployAuctions(address(prot), address(surplusProtTokenReceiver), "recycling");
        gebDeploy.deployAccountingEngine();
        gebDeploy.deployStabilityFeeTreasury();
        gebDeploy.deployLiquidator();
        gebDeploy.deployShutdown(address(prot), address(0x0), address(0x0), 10);

        if (PAUSE_TYPE == keccak256(abi.encodePacked("BASIC"))) {
          gebDeploy.deployPause(0, authority);
        } else {
          gebDeploy.deployProtestPause(protesterLifetime, 0, authority);
        }

        address pauseProxy;

        safeEngine = gebDeploy.safeEngine();
        taxCollector = gebDeploy.taxCollector();
        accountingEngine = gebDeploy.accountingEngine();
        liquidationEngine = gebDeploy.liquidationEngine();
        recyclingSurplusAuctionHouse = gebDeploy.recyclingSurplusAuctionHouse();
        debtAuctionHouse = gebDeploy.debtAuctionHouse();
        coin = gebDeploy.coin();
        coinJoin = gebDeploy.coinJoin();
        oracleRelayer = gebDeploy.oracleRelayer();
        globalSettlement = gebDeploy.globalSettlement();
        esm = gebDeploy.esm();
        stabilityFeeTreasury = gebDeploy.stabilityFeeTreasury();

        if (PAUSE_TYPE == keccak256(abi.encodePacked("BASIC"))) {
          pause = DSPauseLike(address(gebDeploy.pause()));
          pauseProxy = address(gebDeploy.pause().proxy());
        } else {
          pause = DSPauseLike(address(gebDeploy.protestPause()));
          pauseProxy = address(gebDeploy.protestPause().proxy());
        }

        authority.setRootUser(pauseProxy, true);
        gebDeploy.giveControl(pauseProxy);

        weth = new WETH9_();
        ethJoin = new CollateralJoin1(address(safeEngine), "ETH", address(weth));
        gebDeploy.deployCollateral(auctionType, "ETH", address(ethJoin), address(orclETH), address(0));
        gebDeploy.addAuthToCollateralAuctionHouse("ETH", pauseProxy);

        col = new DSToken("COL", "COL");
        colJoin = new CollateralJoin1(address(safeEngine), "COL", address(col));
        gebDeploy.deployCollateral(auctionType, "COL", address(colJoin), address(orclCOL), address(0));
        gebDeploy.addAuthToCollateralAuctionHouse("COL", pauseProxy);

        col6 = new DSToken("COL6", "COL6");
        col6Join = new CollateralJoin6(address(safeEngine), "COL6", address(col6));
        col6Join.addAuthorization(pauseProxy);
        col6Join.removeAuthorization(address(this));

        // Set SAFEEngine Params
        this.modifyParameters(address(safeEngine), bytes32("globalDebtCeiling"), uint(10000 * 10 ** 45));
        this.modifyParameters(address(safeEngine), bytes32("ETH"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));
        this.modifyParameters(address(safeEngine), bytes32("COL"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));

        orclETH.updateResult(300 * 10 ** 18); // Price 300 COIN = 1 ETH (precision 18)
        orclCOL.updateResult(45 * 10 ** 18);  // Price 45 COIN = 1 COL (precision 18)
        orclCOIN.updateResult(1 * 10 ** 18);  // Price 1 COIN = 1 USD

        priceSourceETH.updateResult(300 * 10 ** 18); // Price 300 COIN = 1 ETH (precision 18)
        priceSourceCOL.updateResult(45 * 10 ** 18);  // Price 45 COIN = 1 COL (precision 18)
        priceSourceCOIN.updateResult(1 * 10 ** 18);  // Price 1 COIN = 1 USD

        (ethEnglishCollateralAuctionHouse, ethIncreasingDiscountCollateralAuctionHouse,) = gebDeploy.collateralTypes("ETH");
        (colEnglishCollateralAuctionHouse, colIncreasingDiscountCollateralAuctionHouse,) = gebDeploy.collateralTypes("COL");
        this.modifyParameters(address(oracleRelayer), "ETH", "safetyCRatio", uint(1500000000 ether));
        this.modifyParameters(address(oracleRelayer), "ETH", "liquidationCRatio", uint(1500000000 ether));

        this.modifyParameters(address(oracleRelayer), "COL", "safetyCRatio", uint(1100000000 ether));
        this.modifyParameters(address(oracleRelayer), "COL", "liquidationCRatio", uint(1100000000 ether));

        oracleRelayer.updateCollateralPrice("ETH");
        oracleRelayer.updateCollateralPrice("COL");
        (,,uint safetyPrice,,,uint liquidationPrice) = safeEngine.collateralTypes("ETH");
        assertEq(safetyPrice, 300 * ONE * ONE / 1500000000 ether);
        assertEq(safetyPrice, liquidationPrice);
        (,, safetyPrice,,,liquidationPrice) = safeEngine.collateralTypes("COL");
        assertEq(safetyPrice, 45 * ONE * ONE / 1100000000 ether);
        assertEq(safetyPrice, liquidationPrice);

        DSGuard(address(prot.authority())).permit(address(debtAuctionHouse), address(prot), bytes4(keccak256("mint(address,uint256)")));
        DSGuard(address(prot.authority())).permit(address(recyclingSurplusAuctionHouse), address(prot), bytes4(keccak256("burn(address,uint256)")));
    }

    function deployStableKeepAuth(bytes32 auctionType) virtual public {
        prot.mint(100 ether);

        gebDeploy.deploySAFEEngine();
        gebDeploy.deployCoin("Stable Coin", "STABL", 99);
        gebDeploy.deployTaxation();
        gebDeploy.deploySavingsAccount();
        gebDeploy.deployAuctions(address(prot), address(surplusProtTokenReceiver), "recycling");
        gebDeploy.deployAccountingEngine();
        gebDeploy.deployStabilityFeeTreasury();
        gebDeploy.deployLiquidator();
        gebDeploy.deployShutdown(address(prot), address(0x0), address(0x0), 10);

        if (PAUSE_TYPE == keccak256(abi.encodePacked("BASIC"))) {
          gebDeploy.deployPause(0, authority);
        } else {
          gebDeploy.deployProtestPause(protesterLifetime, 0, authority);
        }

        address pauseProxy;

        safeEngine = gebDeploy.safeEngine();
        taxCollector = gebDeploy.taxCollector();
        accountingEngine = gebDeploy.accountingEngine();
        liquidationEngine = gebDeploy.liquidationEngine();
        recyclingSurplusAuctionHouse = gebDeploy.recyclingSurplusAuctionHouse();
        debtAuctionHouse = gebDeploy.debtAuctionHouse();
        coinSavingsAccount = gebDeploy.coinSavingsAccount();
        coin = gebDeploy.coin();
        coinJoin = gebDeploy.coinJoin();
        oracleRelayer = gebDeploy.oracleRelayer();
        globalSettlement = gebDeploy.globalSettlement();
        esm = gebDeploy.esm();
        stabilityFeeTreasury = gebDeploy.stabilityFeeTreasury();

        if (PAUSE_TYPE == keccak256(abi.encodePacked("BASIC"))) {
          pause = DSPauseLike(address(gebDeploy.pause()));
          pauseProxy = address(gebDeploy.pause().proxy());
        } else {
          pause = DSPauseLike(address(gebDeploy.protestPause()));
          pauseProxy = address(gebDeploy.protestPause().proxy());
        }

        authority.setRootUser(pauseProxy, true);
        gebDeploy.giveControl(pauseProxy);

        weth = new WETH9_();
        ethJoin = new CollateralJoin1(address(safeEngine), "ETH", address(weth));
        gebDeploy.deployCollateral(auctionType, "ETH", address(ethJoin), address(orclETH), address(0));
        gebDeploy.addAuthToCollateralAuctionHouse("ETH", pauseProxy);

        col = new DSToken("COL", "COL");
        colJoin = new CollateralJoin1(address(safeEngine), "COL", address(col));
        gebDeploy.deployCollateral(auctionType, "COL", address(colJoin), address(orclCOL), address(0));
        gebDeploy.addAuthToCollateralAuctionHouse("COL", pauseProxy);

        col6 = new DSToken("COL6", "COL6");
        col6Join = new CollateralJoin6(address(safeEngine), "COL6", address(col6));
        col6Join.addAuthorization(pauseProxy);
        col6Join.removeAuthorization(address(this));

        // Set SAFEEngine Params
        this.modifyParameters(address(safeEngine), bytes32("globalDebtCeiling"), uint(10000 * 10 ** 45));
        this.modifyParameters(address(safeEngine), bytes32("ETH"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));
        this.modifyParameters(address(safeEngine), bytes32("COL"), bytes32("debtCeiling"), uint(10000 * 10 ** 45));

        orclETH.updateResult(300 * 10 ** 18); // Price 300 COIN = 1 ETH (precision 18)
        orclCOL.updateResult(45 * 10 ** 18);  // Price 45 COIN = 1 COL (precision 18)
        orclCOIN.updateResult(1 * 10 ** 18);  // Price 1 COIN = 1 USD

        priceSourceETH.updateResult(300 * 10 ** 18); // Price 300 COIN = 1 ETH (precision 18)
        priceSourceCOL.updateResult(45 * 10 ** 18);  // Price 45 COIN = 1 COL (precision 18)
        priceSourceCOIN.updateResult(1 * 10 ** 18);  // Price 1 COIN = 1 USD

        (ethEnglishCollateralAuctionHouse, ethIncreasingDiscountCollateralAuctionHouse,) = gebDeploy.collateralTypes("ETH");
        (colEnglishCollateralAuctionHouse, colIncreasingDiscountCollateralAuctionHouse,) = gebDeploy.collateralTypes("COL");
        this.modifyParameters(address(oracleRelayer), "ETH", "safetyCRatio", uint(1500000000 ether));
        this.modifyParameters(address(oracleRelayer), "ETH", "liquidationCRatio", uint(1500000000 ether));

        this.modifyParameters(address(oracleRelayer), "COL", "safetyCRatio", uint(1100000000 ether));
        this.modifyParameters(address(oracleRelayer), "COL", "liquidationCRatio", uint(1100000000 ether));

        oracleRelayer.updateCollateralPrice("ETH");
        oracleRelayer.updateCollateralPrice("COL");
        (,,uint safetyPrice,,,uint liquidationPrice) = safeEngine.collateralTypes("ETH");
        assertEq(safetyPrice, 300 * ONE * ONE / 1500000000 ether);
        assertEq(safetyPrice, liquidationPrice);
        (,, safetyPrice,,,liquidationPrice) = safeEngine.collateralTypes("COL");
        assertEq(safetyPrice, 45 * ONE * ONE / 1100000000 ether);
        assertEq(safetyPrice, liquidationPrice);

        DSGuard(address(prot.authority())).permit(address(debtAuctionHouse), address(prot), bytes4(keccak256("mint(address,uint256)")));
        DSGuard(address(prot.authority())).permit(address(recyclingSurplusAuctionHouse), address(prot), bytes4(keccak256("burn(address,uint256)")));
    }

    // Index
    function deployIndex(bytes32 auctionType) virtual public {
        deployIndexKeepAuth(auctionType);
        gebDeploy.releaseAuth();
    }
    function deployIndexWithCreatorPermissions(bytes32 auctionType) virtual public {
        deployIndexKeepAuth(auctionType);
        gebDeploy.addCreatorAuth();
        gebDeploy.releaseAuth();
        accountingEngine.modifyParameters("protocolTokenAuthority", address(tokenAuthority));
        tokenAuthority.addAuthorization(address(debtAuctionHouse));
    }

    // Stablecoin
    function deployStable(bytes32 auctionType) virtual public {
        deployStableKeepAuth(auctionType);
        gebDeploy.releaseAuth();
    }
    function deployStableWithCreatorPermissions(bytes32 auctionType) virtual public {
        deployStableKeepAuth(auctionType);
        gebDeploy.addCreatorAuth();
        gebDeploy.releaseAuth();
        accountingEngine.modifyParameters("protocolTokenAuthority", address(tokenAuthority));
        tokenAuthority.addAuthorization(address(debtAuctionHouse));
    }

    // Utils
    function release() virtual public {
        gebDeploy.releaseAuth();
    }

    receive() external payable {}
}
