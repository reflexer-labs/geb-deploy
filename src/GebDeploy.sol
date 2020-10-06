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

pragma solidity ^0.6.7;

import {DSAuth, DSAuthority} from "ds-auth/auth.sol";
import {DSPause, DSPauseProxy} from "ds-pause/pause.sol";
import {DSProtestPause} from "ds-pause/protest-pause.sol";

import {SAFEEngine} from "geb/SAFEEngine.sol";
import {TaxCollector} from "geb/TaxCollector.sol";
import {AccountingEngine} from "geb/AccountingEngine.sol";
import {LiquidationEngine} from "geb/LiquidationEngine.sol";
import {CoinJoin} from "geb/BasicTokenAdapters.sol";
import {PreSettlementSurplusAuctionHouse, PostSettlementSurplusAuctionHouse} from "geb/SurplusAuctionHouse.sol";
import {DebtAuctionHouse} from "geb/DebtAuctionHouse.sol";
import {EnglishCollateralAuctionHouse, FixedDiscountCollateralAuctionHouse} from "geb/CollateralAuctionHouse.sol";
import {Coin} from "geb/Coin.sol";
import {SettlementSurplusAuctioneer} from "geb/SettlementSurplusAuctioneer.sol";
import {GlobalSettlement} from "geb/GlobalSettlement.sol";
import {ESM} from "esm/ESM.sol";
import {StabilityFeeTreasury} from "geb/StabilityFeeTreasury.sol";
import {CoinSavingsAccount} from "geb/CoinSavingsAccount.sol";
import {OracleRelayer} from "geb/OracleRelayer.sol";

abstract contract CollateralAuctionHouse {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
}

abstract contract AuthorizableContract {
    function addAuthorization(address) virtual external;
    function removeAuthorization(address) virtual external;
}

contract SAFEEngineFactory {
    function newSAFEEngine() public returns (SAFEEngine safeEngine) {
        safeEngine = new SAFEEngine();
        safeEngine.addAuthorization(msg.sender);
        safeEngine.removeAuthorization(address(this));
    }
}

contract TaxCollectorFactory {
    function newTaxCollector(address safeEngine) public returns (TaxCollector taxCollector) {
        taxCollector = new TaxCollector(safeEngine);
        taxCollector.addAuthorization(msg.sender);
        taxCollector.removeAuthorization(address(this));
    }
}

contract AccountingEngineFactory {
    function newAccountingEngine(address safeEngine, address surplusAuctionHouse, address debtAuctionHouse) public returns (AccountingEngine accountingEngine) {
        accountingEngine = new AccountingEngine(safeEngine, surplusAuctionHouse, debtAuctionHouse);
        accountingEngine.addAuthorization(msg.sender);
        accountingEngine.removeAuthorization(address(this));
    }
}

contract LiquidationEngineFactory {
    function newLiquidationEngine(address safeEngine) public returns (LiquidationEngine liquidationEngine) {
        liquidationEngine = new LiquidationEngine(safeEngine);
        liquidationEngine.addAuthorization(msg.sender);
        liquidationEngine.removeAuthorization(address(this));
    }
}

contract CoinFactory {
    function newCoin(string memory name, string memory symbol, uint chainId)
      public returns (Coin coin) {
        coin = new Coin(name, symbol, chainId);
        coin.addAuthorization(msg.sender);
        coin.removeAuthorization(address(this));
    }
}

contract CoinJoinFactory {
    function newCoinJoin(address safeEngine, address coin) public returns (CoinJoin coinJoin) {
        coinJoin = new CoinJoin(safeEngine, coin);
        coinJoin.addAuthorization(msg.sender);
        coinJoin.removeAuthorization(address(this));
    }
}

contract PreSettlementSurplusAuctionHouseFactory {
    function newSurplusAuctionHouse(address safeEngine, address prot) public returns (PreSettlementSurplusAuctionHouse surplusAuctionHouse) {
        surplusAuctionHouse = new PreSettlementSurplusAuctionHouse(safeEngine, prot);
        surplusAuctionHouse.addAuthorization(msg.sender);
        surplusAuctionHouse.removeAuthorization(address(this));
    }
}

contract PostSettlementSurplusAuctionHouseFactory {
    function newSurplusAuctionHouse(address safeEngine, address prot) public returns (PostSettlementSurplusAuctionHouse surplusAuctionHouse) {
        surplusAuctionHouse = new PostSettlementSurplusAuctionHouse(safeEngine, prot);
        surplusAuctionHouse.addAuthorization(msg.sender);
        surplusAuctionHouse.removeAuthorization(address(this));
    }
}

contract SettlementSurplusAuctioneerFactory {
    function newSettlementSurplusAuctioneer(
      address accountingEngine,
      address surplusAuctionHouse
    ) public returns (SettlementSurplusAuctioneer settlementSurplusAuctioneer) {
        settlementSurplusAuctioneer = new SettlementSurplusAuctioneer(accountingEngine, surplusAuctionHouse);
        settlementSurplusAuctioneer.addAuthorization(msg.sender);
        settlementSurplusAuctioneer.removeAuthorization(address(this));
    }
}

contract DebtAuctionHouseFactory {
    function newDebtAuctionHouse(address safeEngine, address prot) public returns (DebtAuctionHouse debtAuctionHouse) {
        debtAuctionHouse = new DebtAuctionHouse(safeEngine, prot);
        debtAuctionHouse.addAuthorization(msg.sender);
        debtAuctionHouse.removeAuthorization(address(this));
    }
}

contract EnglishCollateralAuctionHouseFactory {
    function newCollateralAuctionHouse(address safeEngine, address liquidationEngine, bytes32 collateralType) public returns (EnglishCollateralAuctionHouse englishCollateralAuctionHouse) {
        englishCollateralAuctionHouse = new EnglishCollateralAuctionHouse(safeEngine, liquidationEngine, collateralType);
        englishCollateralAuctionHouse.addAuthorization(msg.sender);
        englishCollateralAuctionHouse.removeAuthorization(address(this));
    }
}

contract FixedDiscountCollateralAuctionHouseFactory {
    function newCollateralAuctionHouse(address safeEngine, address liquidationEngine, bytes32 collateralType) public returns (FixedDiscountCollateralAuctionHouse fixedDiscountCollateralAuctionHouse) {
        fixedDiscountCollateralAuctionHouse = new FixedDiscountCollateralAuctionHouse(safeEngine, liquidationEngine, collateralType);
        fixedDiscountCollateralAuctionHouse.addAuthorization(msg.sender);
        fixedDiscountCollateralAuctionHouse.removeAuthorization(address(this));
    }
}

contract OracleRelayerFactory {
    function newOracleRelayer(address safeEngine) public returns (OracleRelayer oracleRelayer) {
        oracleRelayer = new OracleRelayer(safeEngine);
        oracleRelayer.addAuthorization(msg.sender);
        oracleRelayer.removeAuthorization(address(this));
    }
}

contract CoinSavingsAccountFactory {
    function newCoinSavingsAccount(address safeEngine) public returns (CoinSavingsAccount coinSavingsAccount) {
        coinSavingsAccount = new CoinSavingsAccount(safeEngine);
        coinSavingsAccount.addAuthorization(msg.sender);
        coinSavingsAccount.removeAuthorization(address(this));
    }
}

contract StabilityFeeTreasuryFactory {
    function newStabilityFeeTreasury(
      address safeEngine,
      address accountingEngine,
      address coinJoin
    ) public returns (StabilityFeeTreasury stabilityFeeTreasury) {
        stabilityFeeTreasury = new StabilityFeeTreasury(safeEngine, accountingEngine, coinJoin);
        stabilityFeeTreasury.addAuthorization(msg.sender);
        stabilityFeeTreasury.removeAuthorization(address(this));
    }
}

contract ESMFactory {
    function newESM(
        address prot, address globalSettlement, address tokenBurner, address thresholdSetter, uint threshold
    ) public returns (ESM esm) {
        esm = new ESM(prot, globalSettlement, tokenBurner, thresholdSetter, threshold);
        esm.addAuthorization(msg.sender);
        esm.removeAuthorization(address(this));
    }
}

contract GlobalSettlementFactory {
    function newGlobalSettlement() public returns (GlobalSettlement globalSettlement) {
        globalSettlement = new GlobalSettlement();
        globalSettlement.addAuthorization(msg.sender);
        globalSettlement.removeAuthorization(address(this));
    }
}

contract PauseFactory {
    function newPause(uint delay, address owner, DSAuthority authority) public returns (DSPause pause) {
        pause = new DSPause(delay, owner, authority);
    }
}

contract ProtestPauseFactory {
    function newPause(uint protesterLifetime, uint delay, address owner, DSAuthority authority) public returns (DSProtestPause pause) {
        pause = new DSProtestPause(protesterLifetime, delay, owner, authority);
    }
}

contract GebDeploy is DSAuth {
    SAFEEngineFactory                          public safeEngineFactory;
    TaxCollectorFactory                        public taxCollectorFactory;
    AccountingEngineFactory                    public accountingEngineFactory;
    LiquidationEngineFactory                   public liquidationEngineFactory;
    CoinFactory                                public coinFactory;
    CoinJoinFactory                            public coinJoinFactory;
    StabilityFeeTreasuryFactory                public stabilityFeeTreasuryFactory;
    PreSettlementSurplusAuctionHouseFactory    public preSettlementSurplusAuctionHouseFactory;
    PostSettlementSurplusAuctionHouseFactory   public postSettlementSurplusAuctionHouseFactory;
    DebtAuctionHouseFactory                    public debtAuctionHouseFactory;
    EnglishCollateralAuctionHouseFactory       public englishCollateralAuctionHouseFactory;
    FixedDiscountCollateralAuctionHouseFactory public fixedDiscountCollateralAuctionHouseFactory;
    OracleRelayerFactory                       public oracleRelayerFactory;
    GlobalSettlementFactory                    public globalSettlementFactory;
    ESMFactory                                 public esmFactory;
    PauseFactory                               public pauseFactory;
    ProtestPauseFactory                        public protestPauseFactory;
    CoinSavingsAccountFactory                  public coinSavingsAccountFactory;
    SettlementSurplusAuctioneerFactory         public settlementSurplusAuctioneerFactory;

    SAFEEngine                        public safeEngine;
    TaxCollector                      public taxCollector;
    AccountingEngine                  public accountingEngine;
    LiquidationEngine                 public liquidationEngine;
    StabilityFeeTreasury              public stabilityFeeTreasury;
    Coin                              public coin;
    CoinJoin                          public coinJoin;
    PreSettlementSurplusAuctionHouse  public preSettlementSurplusAuctionHouse;
    PostSettlementSurplusAuctionHouse public postSettlementSurplusAuctionHouse;
    DebtAuctionHouse                  public debtAuctionHouse;
    OracleRelayer                     public oracleRelayer;
    CoinSavingsAccount                public coinSavingsAccount;
    GlobalSettlement                  public globalSettlement;
    SettlementSurplusAuctioneer       public settlementSurplusAuctioneer;
    ESM                               public esm;
    DSPause                           public pause;
    DSProtestPause                    public protestPause;

    mapping(bytes32 => CollateralType) public collateralTypes;

    struct CollateralType {
        EnglishCollateralAuctionHouse englishCollateralAuctionHouse;
        FixedDiscountCollateralAuctionHouse fixedDiscountCollateralAuctionHouse;
        address adapter;
    }

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function setFirstFactoryBatch(
        SAFEEngineFactory safeEngineFactory_,
        TaxCollectorFactory taxCollectorFactory_,
        AccountingEngineFactory accountingEngineFactory_,
        LiquidationEngineFactory liquidationEngineFactory_,
        CoinFactory coinFactory_,
        CoinJoinFactory coinJoinFactory_,
        CoinSavingsAccountFactory coinSavingsAccountFactory_,
        SettlementSurplusAuctioneerFactory settlementSurplusAuctioneerFactory_
    ) public auth {
        require(address(safeEngineFactory) == address(0), "SAFEEngine Factory already set");
        safeEngineFactory = safeEngineFactory_;
        taxCollectorFactory = taxCollectorFactory_;
        accountingEngineFactory = accountingEngineFactory_;
        liquidationEngineFactory = liquidationEngineFactory_;
        coinFactory = coinFactory_;
        coinJoinFactory = coinJoinFactory_;
        coinSavingsAccountFactory = coinSavingsAccountFactory_;
        settlementSurplusAuctioneerFactory = settlementSurplusAuctioneerFactory_;
    }
    function setSecondFactoryBatch(
        PreSettlementSurplusAuctionHouseFactory preSettlementSurplusAuctionHouseFactory_,
        PostSettlementSurplusAuctionHouseFactory postSettlementSurplusAuctionHouseFactory_,
        DebtAuctionHouseFactory debtAuctionHouseFactory_,
        EnglishCollateralAuctionHouseFactory englishCollateralAuctionHouseFactory_,
        FixedDiscountCollateralAuctionHouseFactory fixedDiscountCollateralAuctionHouseFactory_,
        OracleRelayerFactory oracleRelayerFactory_,
        GlobalSettlementFactory globalSettlementFactory_,
        ESMFactory esmFactory_
    ) public auth {
        require(address(safeEngineFactory) != address(0), "SAFEEngine Factory not set");
        require(address(preSettlementSurplusAuctionHouseFactory) == address(0), "PreSettlementSurplusAuctionHouse Factory already set");
        require(address(postSettlementSurplusAuctionHouseFactory) == address(0), "PostSettlementSurplusAuctionHouse Factory already set");
        preSettlementSurplusAuctionHouseFactory = preSettlementSurplusAuctionHouseFactory_;
        postSettlementSurplusAuctionHouseFactory = postSettlementSurplusAuctionHouseFactory_;
        debtAuctionHouseFactory = debtAuctionHouseFactory_;
        englishCollateralAuctionHouseFactory = englishCollateralAuctionHouseFactory_;
        fixedDiscountCollateralAuctionHouseFactory = fixedDiscountCollateralAuctionHouseFactory_;
        oracleRelayerFactory = oracleRelayerFactory_;
        globalSettlementFactory = globalSettlementFactory_;
        esmFactory = esmFactory_;
    }
    function setThirdFactoryBatch(
        PauseFactory pauseFactory_,
        ProtestPauseFactory protestPauseFactory_,
        StabilityFeeTreasuryFactory stabilityFeeTreasuryFactory_
    ) public auth {
        require(address(safeEngineFactory) != address(0), "SAFEEngine Factory not set");
        pauseFactory = pauseFactory_;
        protestPauseFactory = protestPauseFactory_;
        stabilityFeeTreasuryFactory = stabilityFeeTreasuryFactory_;
    }

    function deploySAFEEngine() public auth {
        require(address(safeEngine) == address(0), "SAFEEngine already deployed");
        safeEngine = safeEngineFactory.newSAFEEngine();
        oracleRelayer = oracleRelayerFactory.newOracleRelayer(address(safeEngine));

        // Internal auth
        safeEngine.addAuthorization(address(oracleRelayer));
    }

    function deployCoin(string memory name, string memory symbol, uint256 chainId)
      public auth {
        require(address(safeEngine) != address(0), "Missing previous step");

        // Deploy
        coin      = coinFactory.newCoin(name, symbol, chainId);
        coinJoin  = coinJoinFactory.newCoinJoin(address(safeEngine), address(coin));
        coin.addAuthorization(address(coinJoin));
    }

    function deployTaxation() public auth {
        require(address(safeEngine) != address(0), "Missing previous step");

        // Deploy
        taxCollector = taxCollectorFactory.newTaxCollector(address(safeEngine));

        // Internal auth
        safeEngine.addAuthorization(address(taxCollector));
    }

    function deploySavingsAccount() public auth {
        require(address(safeEngine) != address(0), "Missing previous step");

        // Deploy
        coinSavingsAccount = coinSavingsAccountFactory.newCoinSavingsAccount(address(safeEngine));

        // Internal auth
        safeEngine.addAuthorization(address(coinSavingsAccount));
    }

    function deployAuctions(address prot) public auth {
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(coin) != address(0), "Missing COIN address");

        // Deploy
        if (prot != address(0)) {
          postSettlementSurplusAuctionHouse = postSettlementSurplusAuctionHouseFactory.newSurplusAuctionHouse(address(safeEngine), prot);
        }
        preSettlementSurplusAuctionHouse = preSettlementSurplusAuctionHouseFactory.newSurplusAuctionHouse(address(safeEngine), prot);
        debtAuctionHouse = debtAuctionHouseFactory.newDebtAuctionHouse(address(safeEngine), prot);

        // Internal auth
        safeEngine.addAuthorization(address(debtAuctionHouse));
    }

    function deployAccountingEngine() public auth {
        accountingEngine = accountingEngineFactory.newAccountingEngine(address(safeEngine), address(preSettlementSurplusAuctionHouse), address(debtAuctionHouse));

        // Setup
        debtAuctionHouse.modifyParameters("accountingEngine", address(accountingEngine));
        taxCollector.modifyParameters("primaryTaxReceiver", address(accountingEngine));

        // Internal auth
        preSettlementSurplusAuctionHouse.addAuthorization(address(accountingEngine));
        debtAuctionHouse.addAuthorization(address(accountingEngine));
    }

    function deployStabilityFeeTreasury() public auth {
        require(address(safeEngine) != address(0), "Missing previous step");
        require(address(accountingEngine) != address(0), "Missing previous step");
        require(address(coinJoin) != address(0), "Missing previous step");

        // Deploy
        stabilityFeeTreasury = stabilityFeeTreasuryFactory.newStabilityFeeTreasury(
          address(safeEngine),
          address(accountingEngine),
          address(coinJoin)
        );
    }

    function deploySettlementSurplusAuctioneer() public auth {
        require(address(accountingEngine) != address(0), "Missing previous step");
        require(address(postSettlementSurplusAuctionHouse) != address(0), "Missing previous step");

        // Deploy
        settlementSurplusAuctioneer = settlementSurplusAuctioneerFactory.newSettlementSurplusAuctioneer(
          address(accountingEngine),
          address(postSettlementSurplusAuctionHouse)
        );

        // Set
        accountingEngine.modifyParameters("postSettlementSurplusDrain", address(settlementSurplusAuctioneer));

        // Internal auth
        postSettlementSurplusAuctionHouse.addAuthorization(address(settlementSurplusAuctioneer));
    }

    function deployLiquidator() public auth {
        require(address(accountingEngine) != address(0), "Missing previous step");

        // Deploy
        liquidationEngine = liquidationEngineFactory.newLiquidationEngine(address(safeEngine));

        // Internal references set up
        liquidationEngine.modifyParameters("accountingEngine", address(accountingEngine));

        // Internal auth
        safeEngine.addAuthorization(address(liquidationEngine));
        accountingEngine.addAuthorization(address(liquidationEngine));
    }

    function deployShutdown(address prot, address tokenBurner, address thresholdSetter, uint256 threshold) public auth {
        require(address(liquidationEngine) != address(0), "Missing previous step");

        // Deploy
        globalSettlement = globalSettlementFactory.newGlobalSettlement();

        globalSettlement.modifyParameters("safeEngine", address(safeEngine));
        globalSettlement.modifyParameters("liquidationEngine", address(liquidationEngine));
        globalSettlement.modifyParameters("accountingEngine", address(accountingEngine));
        globalSettlement.modifyParameters("oracleRelayer", address(oracleRelayer));
        if (address(coinSavingsAccount) != address(0)) {
          globalSettlement.modifyParameters("coinSavingsAccount", address(coinSavingsAccount));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          globalSettlement.modifyParameters("stabilityFeeTreasury", address(stabilityFeeTreasury));
        }

        // Internal auth
        safeEngine.addAuthorization(address(globalSettlement));
        liquidationEngine.addAuthorization(address(globalSettlement));
        accountingEngine.addAuthorization(address(globalSettlement));
        oracleRelayer.addAuthorization(address(globalSettlement));
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.addAuthorization(address(globalSettlement));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.addAuthorization(address(globalSettlement));
        }

        // Deploy ESM
        if (prot != address(0)) {
          esm = esmFactory.newESM(prot, address(globalSettlement), address(tokenBurner), address(thresholdSetter), threshold);
          globalSettlement.addAuthorization(address(esm));
        }
    }

    function deployPause(uint delay, DSAuthority authority) public auth {
        require(address(coin) != address(0), "Missing previous step");
        require(address(globalSettlement) != address(0), "Missing previous step");
        require(address(protestPause) == address(0), "Protest Pause already deployed");

        pause = pauseFactory.newPause(delay, address(0), authority);
    }

    function deployProtestPause(uint protesterLifetime, uint delay, DSAuthority authority) public auth {
        require(address(coin) != address(0), "Missing previous step");
        require(address(globalSettlement) != address(0), "Missing previous step");
        require(address(pause) == address(0), "Pause already deployed");

        protestPause = protestPauseFactory.newPause(protesterLifetime, delay, address(0), authority);
    }

    function giveControl(address usr) public auth {
        safeEngine.addAuthorization(address(usr));
        liquidationEngine.addAuthorization(address(usr));
        accountingEngine.addAuthorization(address(usr));
        taxCollector.addAuthorization(address(usr));
        oracleRelayer.addAuthorization(address(usr));
        preSettlementSurplusAuctionHouse.addAuthorization(address(usr));
        debtAuctionHouse.addAuthorization(address(usr));
        globalSettlement.addAuthorization(address(usr));
        coinJoin.addAuthorization(address(usr));
        if (address(esm) != address(0)) {
          esm.addAuthorization(address(usr));
        }
        if (address(postSettlementSurplusAuctionHouse) != address(0)) {
          postSettlementSurplusAuctionHouse.addAuthorization(address(usr));
        }
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.addAuthorization(address(usr));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.addAuthorization(address(usr));
        }
        if (address(settlementSurplusAuctioneer) != address(0)) {
          settlementSurplusAuctioneer.addAuthorization(address(usr));
        }
    }

    function giveControl(address usr, address target) public auth {
        AuthorizableContract(target).addAuthorization(usr);
    }

    function takeControl(address usr) public auth {
        safeEngine.removeAuthorization(address(usr));
        liquidationEngine.removeAuthorization(address(usr));
        accountingEngine.removeAuthorization(address(usr));
        taxCollector.removeAuthorization(address(usr));
        oracleRelayer.removeAuthorization(address(usr));
        preSettlementSurplusAuctionHouse.removeAuthorization(address(usr));
        debtAuctionHouse.removeAuthorization(address(usr));
        globalSettlement.removeAuthorization(address(usr));
        coinJoin.removeAuthorization(address(usr));
        if (address(esm) != address(0)) {
          esm.removeAuthorization(address(usr));
        }
        if (address(postSettlementSurplusAuctionHouse) != address(0)) {
          postSettlementSurplusAuctionHouse.removeAuthorization(address(usr));
        }
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.removeAuthorization(address(usr));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.removeAuthorization(address(usr));
        }
        if (address(settlementSurplusAuctioneer) != address(0)) {
          settlementSurplusAuctioneer.removeAuthorization(address(usr));
        }
    }

    function takeControl(address usr, address target) public auth {
        AuthorizableContract(target).removeAuthorization(usr);
    }

    function addAuthToCollateralAuctionHouse(bytes32 collateralType, address usr) public auth {
        require(
          address(collateralTypes[collateralType].englishCollateralAuctionHouse) != address(0) ||
          address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse) != address(0),
          "Collateral auction houses not initialized"
        );
        if (address(collateralTypes[collateralType].englishCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].englishCollateralAuctionHouse.addAuthorization(usr);
        } else if (address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.addAuthorization(usr);
        }
    }

    function releaseAuthCollateralAuctionHouse(bytes32 collateralType, address usr) public auth {
        if (address(collateralTypes[collateralType].englishCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].englishCollateralAuctionHouse.removeAuthorization(usr);
        } else if (address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse) != address(0)) {
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.removeAuthorization(usr);
        }
    }

    function deployCollateral(
        bytes32 auctionHouseType,
        bytes32 collateralType,
        address adapter,
        address collateralFSM,
        address collateralMedian,
        address systemCoinOracle
    ) public auth {
        require(collateralType != bytes32(""), "Missing collateralType name");
        require(adapter != address(0), "Missing adapter address");
        require(collateralFSM != address(0), "Missing OSM address");

        // Deploy
        address auctionHouse;

        safeEngine.addAuthorization(adapter);

        if (auctionHouseType == "ENGLISH") {
          collateralTypes[collateralType].englishCollateralAuctionHouse =
            englishCollateralAuctionHouseFactory.newCollateralAuctionHouse(address(safeEngine), address(liquidationEngine), collateralType);
          liquidationEngine.modifyParameters(collateralType, "collateralAuctionHouse", address(collateralTypes[collateralType].englishCollateralAuctionHouse));
          // Approve the auction house in order to reduce the currentOnAuctionSystemCoins
          liquidationEngine.addAuthorization(address(collateralTypes[collateralType].englishCollateralAuctionHouse));
          // Internal auth
          collateralTypes[collateralType].englishCollateralAuctionHouse.addAuthorization(address(liquidationEngine));
          collateralTypes[collateralType].englishCollateralAuctionHouse.addAuthorization(address(globalSettlement));
          auctionHouse = address(collateralTypes[collateralType].englishCollateralAuctionHouse);
        } else {
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse =
            fixedDiscountCollateralAuctionHouseFactory.newCollateralAuctionHouse(address(safeEngine), address(liquidationEngine), collateralType);
          liquidationEngine.modifyParameters(collateralType, "collateralAuctionHouse", address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse));
          // Approve the auction house in order to reduce the currentOnAuctionSystemCoins
          liquidationEngine.addAuthorization(address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse));
          // Internal auth
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.addAuthorization(address(liquidationEngine));
          collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse.addAuthorization(address(globalSettlement));
          auctionHouse = address(collateralTypes[collateralType].fixedDiscountCollateralAuctionHouse);
        }

        collateralTypes[collateralType].adapter = adapter;
        OracleRelayer(oracleRelayer).modifyParameters(collateralType, "orcl", address(collateralFSM));

        // Internal references set up
        safeEngine.initializeCollateralType(collateralType);
        taxCollector.initializeCollateralType(collateralType);

        // Set bid restrictions
        if (auctionHouseType != "ENGLISH") {
          CollateralAuctionHouse(auctionHouse).modifyParameters("oracleRelayer", address(oracleRelayer));
          CollateralAuctionHouse(auctionHouse).modifyParameters("collateralFSM", address(collateralFSM));
          CollateralAuctionHouse(auctionHouse).modifyParameters("collateralMedian", address(collateralMedian));
          CollateralAuctionHouse(auctionHouse).modifyParameters("systemCoinOracle", address(systemCoinOracle));
        }
    }

    function releaseAuth() public auth {
        safeEngine.removeAuthorization(address(this));
        liquidationEngine.removeAuthorization(address(this));
        accountingEngine.removeAuthorization(address(this));
        taxCollector.removeAuthorization(address(this));
        coin.removeAuthorization(address(this));
        oracleRelayer.removeAuthorization(address(this));
        preSettlementSurplusAuctionHouse.removeAuthorization(address(this));
        debtAuctionHouse.removeAuthorization(address(this));
        globalSettlement.removeAuthorization(address(this));
        coinJoin.removeAuthorization(address(this));
        if (address(esm) != address(0)) {
          esm.removeAuthorization(address(this));
        }
        if (address(postSettlementSurplusAuctionHouse) != address(0)) {
          postSettlementSurplusAuctionHouse.removeAuthorization(address(this));
        }
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.removeAuthorization(address(this));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.removeAuthorization(address(address(this)));
        }
        if (address(settlementSurplusAuctioneer) != address(0)) {
          settlementSurplusAuctioneer.removeAuthorization(address(address(this)));
        }
    }

    function addCreatorAuth() public auth {
        safeEngine.addAuthorization(msg.sender);
        accountingEngine.addAuthorization(msg.sender);
    }
}
