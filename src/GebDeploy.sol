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

import {RedemptionRateSetter} from "geb-redemption-feedback-mechanism/RedemptionRateSetter.sol";
import {EmergencyRateSetter} from "geb-redemption-feedback-mechanism/EmergencyRateSetter.sol";
import {MoneyMarketSetter} from "geb-money-market-setter/MoneyMarketSetter.sol";

import {Logging} from "geb/Logging.sol";
import {CDPEngine} from "geb/CDPEngine.sol";
import {TaxCollector} from "geb/TaxCollector.sol";
import {AccountingEngine} from "geb/AccountingEngine.sol";
import {LiquidationEngine} from "geb/LiquidationEngine.sol";
import {CoinJoin} from "geb/BasicTokenAdapters.sol";
import {PreSettlementSurplusAuctionHouse, PostSettlementSurplusAuctionHouse} from "geb/SurplusAuctionHouse.sol";
import {DebtAuctionHouse} from "geb/DebtAuctionHouse.sol";
import {CollateralAuctionHouse} from "geb/CollateralAuctionHouse.sol";
import {Coin} from "geb/Coin.sol";
import {SettlementSurplusAuctioneer} from "geb/SettlementSurplusAuctioneer.sol";
import {GlobalSettlement} from "geb/GlobalSettlement.sol";
import {ESM} from "esm/ESM.sol";
import {StabilityFeeTreasury} from "geb/StabilityFeeTreasury.sol";
import {CoinSavingsAccount} from "geb/CoinSavingsAccount.sol";
import {OracleRelayer} from "geb/OracleRelayer.sol";

contract CDPEngineFactory {
    function newCDPEngine() public returns (CDPEngine cdpEngine) {
        cdpEngine = new CDPEngine();
        cdpEngine.addAuthorization(msg.sender);
        cdpEngine.removeAuthorization(address(this));
    }
}

contract TaxCollectorFactory {
    function newTaxCollector(address cdpEngine) public returns (TaxCollector taxCollector) {
        taxCollector = new TaxCollector(cdpEngine);
        taxCollector.addAuthorization(msg.sender);
        taxCollector.removeAuthorization(address(this));
    }
}

contract AccountingEngineFactory {
    function newAccountingEngine(address cdpEngine, address surplusAuctionHouse, address debtAuctionHouse) public returns (AccountingEngine accountingEngine) {
        accountingEngine = new AccountingEngine(cdpEngine, surplusAuctionHouse, debtAuctionHouse);
        accountingEngine.addAuthorization(msg.sender);
        accountingEngine.removeAuthorization(address(this));
    }
}

contract LiquidationEngineFactory {
    function newLiquidationEngine(address cdpEngine) public returns (LiquidationEngine liquidationEngine) {
        liquidationEngine = new LiquidationEngine(cdpEngine);
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
    function newCoinJoin(address cdpEngine, address coin) public returns (CoinJoin coinJoin) {
        coinJoin = new CoinJoin(cdpEngine, coin);
    }
}

contract PreSettlementSurplusAuctionHouseFactory {
    function newSurplusAuctionHouse(address cdpEngine, address prot) public returns (PreSettlementSurplusAuctionHouse surplusAuctionHouse) {
        surplusAuctionHouse = new PreSettlementSurplusAuctionHouse(cdpEngine, prot);
        surplusAuctionHouse.addAuthorization(msg.sender);
        surplusAuctionHouse.removeAuthorization(address(this));
    }
}

contract PostSettlementSurplusAuctionHouseFactory {
    function newSurplusAuctionHouse(address cdpEngine, address prot) public returns (PostSettlementSurplusAuctionHouse surplusAuctionHouse) {
        surplusAuctionHouse = new PostSettlementSurplusAuctionHouse(cdpEngine, prot);
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
    function newDebtAuctionHouse(address cdpEngine, address prot) public returns (DebtAuctionHouse debtAuctionHouse) {
        debtAuctionHouse = new DebtAuctionHouse(cdpEngine, prot);
        debtAuctionHouse.addAuthorization(msg.sender);
        debtAuctionHouse.removeAuthorization(address(this));
    }
}

contract CollateralAuctionHouseFactory {
    function newCollateralAuctionHouse(address cdpEngine, bytes32 collateralType) public returns (CollateralAuctionHouse collateralAuctionHouse) {
        collateralAuctionHouse = new CollateralAuctionHouse(cdpEngine, collateralType);
        collateralAuctionHouse.addAuthorization(msg.sender);
        collateralAuctionHouse.removeAuthorization(address(this));
    }
}

contract OracleRelayerFactory {
    function newOracleRelayer(address cdpEngine) public returns (OracleRelayer oracleRelayer) {
        oracleRelayer = new OracleRelayer(cdpEngine);
        oracleRelayer.addAuthorization(msg.sender);
        oracleRelayer.removeAuthorization(address(this));
    }
}

contract CoinSavingsAccountFactory {
    function newCoinSavingsAccount(address cdpEngine) public returns (CoinSavingsAccount coinSavingsAccount) {
        coinSavingsAccount = new CoinSavingsAccount(cdpEngine);
        coinSavingsAccount.addAuthorization(msg.sender);
        coinSavingsAccount.removeAuthorization(address(this));
    }
}

contract RedemptionRateSetterFactory {
    function newRedemptionRateSetter(address oracleRelayer) public returns (RedemptionRateSetter redemptionRateSetter) {
        redemptionRateSetter = new RedemptionRateSetter(oracleRelayer);
        redemptionRateSetter.addAuthorization(msg.sender);
        redemptionRateSetter.removeAuthorization(address(this));
    }
}

contract EmergencyRateSetterFactory {
    function newEmergencyRateSetter(address oracleRelayer) public returns (EmergencyRateSetter emergencyRateSetter) {
        emergencyRateSetter = new EmergencyRateSetter(oracleRelayer);
        emergencyRateSetter.addAuthorization(msg.sender);
        emergencyRateSetter.removeAuthorization(address(this));
    }
}

contract MoneyMarketSetterFactory {
    function newMoneyMarketSetter(
      address oracleRelayer, address coinSavingsAccount, address taxCollector
    ) public returns (MoneyMarketSetter moneyMarketSetter) {
        moneyMarketSetter = new MoneyMarketSetter(oracleRelayer, coinSavingsAccount, taxCollector);
        moneyMarketSetter.addAuthorization(msg.sender);
        moneyMarketSetter.removeAuthorization(address(this));
    }
}

contract StabilityFeeTreasuryFactory {
    function newStabilityFeeTreasury(
      address cdpEngine,
      address accountingEngine,
      address coinJoin
    ) public returns (StabilityFeeTreasury stabilityFeeTreasury) {
        stabilityFeeTreasury = new StabilityFeeTreasury(cdpEngine, accountingEngine, coinJoin);
        stabilityFeeTreasury.addAuthorization(msg.sender);
        stabilityFeeTreasury.removeAuthorization(address(this));
    }
}

contract ESMFactory {
    function newESM(
        address prot, address globalSettlement, address tokenBurner, uint threshold
    ) public returns (ESM esm) {
        esm = new ESM(prot, globalSettlement, tokenBurner, threshold);
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
    function newPause(uint delay, address owner, DSAuthority authority) public returns(DSPause pause) {
        pause = new DSPause(delay, owner, authority);
    }
}

contract GebDeploy is DSAuth, Logging {
    CDPEngineFactory                         public cdpEngineFactory;
    TaxCollectorFactory                      public taxCollectorFactory;
    AccountingEngineFactory                  public accountingEngineFactory;
    LiquidationEngineFactory                 public liquidationEngineFactory;
    CoinFactory                              public coinFactory;
    CoinJoinFactory                          public coinJoinFactory;
    StabilityFeeTreasuryFactory              public stabilityFeeTreasuryFactory;
    PreSettlementSurplusAuctionHouseFactory  public preSettlementSurplusAuctionHouseFactory;
    PostSettlementSurplusAuctionHouseFactory public postSettlementSurplusAuctionHouseFactory;
    DebtAuctionHouseFactory                  public debtAuctionHouseFactory;
    CollateralAuctionHouseFactory            public collateralAuctionHouseFactory;
    OracleRelayerFactory                     public oracleRelayerFactory;
    RedemptionRateSetterFactory              public redemptionRateSetterFactory;
    EmergencyRateSetterFactory               public emergencyRateSetterFactory;
    MoneyMarketSetterFactory                 public moneyMarketSetterFactory;
    GlobalSettlementFactory                  public globalSettlementFactory;
    ESMFactory                               public esmFactory;
    PauseFactory                             public pauseFactory;
    CoinSavingsAccountFactory                public coinSavingsAccountFactory;
    SettlementSurplusAuctioneerFactory       public settlementSurplusAuctioneerFactory;

    CDPEngine                         public cdpEngine;
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
    RedemptionRateSetter              public redemptionRateSetter;
    EmergencyRateSetter               public emergencyRateSetter;
    MoneyMarketSetter                 public moneyMarketSetter;
    CoinSavingsAccount                public coinSavingsAccount;
    GlobalSettlement                  public globalSettlement;
    SettlementSurplusAuctioneer       public settlementSurplusAuctioneer;
    ESM                               public esm;
    DSPause                           public pause;

    mapping(bytes32 => CollateralType) public collateralTypes;

    uint8 public step = 0;

    struct CollateralType {
        CollateralAuctionHouse collateralAuctionHouse;
        address adapter;
    }

    constructor() public {}

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function setFirstFactoryBatch(
        CDPEngineFactory cdpEngineFactory_,
        TaxCollectorFactory taxCollectorFactory_,
        AccountingEngineFactory accountingEngineFactory_,
        LiquidationEngineFactory liquidationEngineFactory_,
        CoinFactory coinFactory_,
        CoinJoinFactory coinJoinFactory_,
        CoinSavingsAccountFactory coinSavingsAccountFactory_,
        SettlementSurplusAuctioneerFactory settlementSurplusAuctioneerFactory_
    ) public auth {
        require(address(cdpEngineFactory) == address(0), "CDPEngine Factory already set");
        cdpEngineFactory = cdpEngineFactory_;
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
        CollateralAuctionHouseFactory collateralAuctionHouseFactory_,
        OracleRelayerFactory oracleRelayerFactory_,
        RedemptionRateSetterFactory redemptionRateSetterFactory_,
        GlobalSettlementFactory globalSettlementFactory_,
        ESMFactory esmFactory_
    ) public auth {
        require(address(cdpEngineFactory) != address(0), "CDPEngine Factory not set");
        require(address(preSettlementSurplusAuctionHouseFactory) == address(0), "PreSettlementSurplusAuctionHouse Factory already set");
        require(address(postSettlementSurplusAuctionHouseFactory) == address(0), "PostSettlementSurplusAuctionHouse Factory already set");
        preSettlementSurplusAuctionHouseFactory = preSettlementSurplusAuctionHouseFactory_;
        postSettlementSurplusAuctionHouseFactory = postSettlementSurplusAuctionHouseFactory_;
        debtAuctionHouseFactory = debtAuctionHouseFactory_;
        collateralAuctionHouseFactory = collateralAuctionHouseFactory_;
        oracleRelayerFactory = oracleRelayerFactory_;
        redemptionRateSetterFactory = redemptionRateSetterFactory_;
        globalSettlementFactory = globalSettlementFactory_;
        esmFactory = esmFactory_;
    }
    function setThirdFactoryBatch(
        PauseFactory pauseFactory_,
        EmergencyRateSetterFactory emergencyRateSetterFactory_,
        MoneyMarketSetterFactory moneyMarketSetterFactory_,
        StabilityFeeTreasuryFactory stabilityFeeTreasuryFactory_
    ) public auth {
        require(address(cdpEngineFactory) != address(0), "CDPEngine Factory not set");
        pauseFactory = pauseFactory_;
        emergencyRateSetterFactory = emergencyRateSetterFactory_;
        moneyMarketSetterFactory = moneyMarketSetterFactory_;
        stabilityFeeTreasuryFactory = stabilityFeeTreasuryFactory_;
    }

    function deployCDPEngine() public auth {
        require(address(cdpEngine) == address(0), "CDPEngine already deployed");
        cdpEngine = cdpEngineFactory.newCDPEngine();
        oracleRelayer = oracleRelayerFactory.newOracleRelayer(address(cdpEngine));

        // Internal auth
        cdpEngine.addAuthorization(address(oracleRelayer));
    }

    function deployCoin(string memory name, string memory symbol, uint256 chainId)
      public auth {
        require(address(cdpEngine) != address(0), "Missing previous step");

        // Deploy
        coin      = coinFactory.newCoin(name, symbol, chainId);
        coinJoin  = coinJoinFactory.newCoinJoin(address(cdpEngine), address(coin));
        coin.addAuthorization(address(coinJoin));
    }

    function deployTaxation() public auth {
        require(address(cdpEngine) != address(0), "Missing previous step");

        // Deploy
        taxCollector = taxCollectorFactory.newTaxCollector(address(cdpEngine));

        // Internal auth
        cdpEngine.addAuthorization(address(taxCollector));
    }

    function deploySavingsAccount() public auth {
        require(address(cdpEngine) != address(0), "Missing previous step");

        // Deploy
        coinSavingsAccount = coinSavingsAccountFactory.newCoinSavingsAccount(address(cdpEngine));

        // Internal auth
        cdpEngine.addAuthorization(address(coinSavingsAccount));
    }

    function deployRateSetter(
        address orcl
    ) public auth {
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(oracleRelayer) != address(0), "Missing previous step");
        require(address(emergencyRateSetter) == address(0), "Rate setter already set");

        // Deploy
        redemptionRateSetter = redemptionRateSetterFactory.newRedemptionRateSetter(address(oracleRelayer));

        // Setup
        redemptionRateSetter.modifyParameters("orcl", orcl);

        // Internal auth
        oracleRelayer.addAuthorization(address(redemptionRateSetter));
    }

    function deployEmergencyRateSetter(
        address orcl
    ) public auth {
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(oracleRelayer) != address(0), "Missing previous step");
        require(address(redemptionRateSetter) == address(0), "Rate setter already set");

        // Deploy
        emergencyRateSetter = emergencyRateSetterFactory.newEmergencyRateSetter(address(oracleRelayer));

        // Setup
        emergencyRateSetter.modifyParameters("orcl", orcl);

        // Internal auth
        oracleRelayer.addAuthorization(address(emergencyRateSetter));
    }

    function deployMoneyMarketSetter(
        address orcl
    ) public auth {
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(coinSavingsAccount) != address(0), "Missing previous step");

        // Setup
        moneyMarketSetter = moneyMarketSetterFactory.newMoneyMarketSetter(
          address(oracleRelayer), address(coinSavingsAccount), address(taxCollector)
        );

        // Setup
        moneyMarketSetter.modifyParameters("orcl", orcl);

        // Internal auth
        taxCollector.addAuthorization(address(moneyMarketSetter));
        coinSavingsAccount.addAuthorization(address(moneyMarketSetter));
    }

    function deployAuctions(address prot) public auth {
        require(prot != address(0), "Missing PROT address");
        require(address(taxCollector) != address(0), "Missing previous step");
        require(address(coin) != address(0), "Missing COIN address");

        // Deploy
        preSettlementSurplusAuctionHouse = preSettlementSurplusAuctionHouseFactory.newSurplusAuctionHouse(address(cdpEngine), prot);
        postSettlementSurplusAuctionHouse = postSettlementSurplusAuctionHouseFactory.newSurplusAuctionHouse(address(cdpEngine), prot);
        debtAuctionHouse = debtAuctionHouseFactory.newDebtAuctionHouse(address(cdpEngine), prot);

        // Internal auth
        cdpEngine.addAuthorization(address(debtAuctionHouse));
    }

    function deployAccountingEngine() public auth {
        accountingEngine = accountingEngineFactory.newAccountingEngine(address(cdpEngine), address(preSettlementSurplusAuctionHouse), address(debtAuctionHouse));

        // Setup
        debtAuctionHouse.modifyParameters("accountingEngine", address(accountingEngine));
        taxCollector.modifyParameters("accountingEngine", address(accountingEngine));

        // Internal auth
        preSettlementSurplusAuctionHouse.addAuthorization(address(accountingEngine));
        debtAuctionHouse.addAuthorization(address(accountingEngine));
    }

    function deployStabilityFeeTreasury() public auth {
        require(address(cdpEngine) != address(0), "Missing previous step");
        require(address(accountingEngine) != address(0), "Missing previous step");
        require(address(coinJoin) != address(0), "Missing previous step");

        // Deploy
        stabilityFeeTreasury = stabilityFeeTreasuryFactory.newStabilityFeeTreasury(
          address(cdpEngine),
          address(accountingEngine),
          address(coinJoin)
        );
    }

    function deploySettlementSurplusAuctioneer() public auth {
        require(address(accountingEngine) != address(0), "Missing previous step");

        // Deploy
        settlementSurplusAuctioneer = settlementSurplusAuctioneerFactory.newSettlementSurplusAuctioneer(
          address(accountingEngine),
          address(postSettlementSurplusAuctionHouse)
        );

        // Set
        accountingEngine.modifyParameters("settlementSurplusAuctioneer", address(settlementSurplusAuctioneer));

        // Internal auth
        postSettlementSurplusAuctionHouse.addAuthorization(address(settlementSurplusAuctioneer));
    }

    function deployLiquidator() public auth {
        require(address(accountingEngine) != address(0), "Missing previous step");

        // Deploy
        liquidationEngine = liquidationEngineFactory.newLiquidationEngine(address(cdpEngine));

        // Internal references set up
        liquidationEngine.modifyParameters("accountingEngine", address(accountingEngine));

        // Internal auth
        cdpEngine.addAuthorization(address(liquidationEngine));
        accountingEngine.addAuthorization(address(liquidationEngine));
    }

    function deployShutdown(address prot, address tokenBurner, uint256 threshold) public auth {
        require(address(liquidationEngine) != address(0), "Missing previous step");

        // Deploy
        globalSettlement = globalSettlementFactory.newGlobalSettlement();

        globalSettlement.modifyParameters("cdpEngine", address(cdpEngine));
        globalSettlement.modifyParameters("liquidationEngine", address(liquidationEngine));
        globalSettlement.modifyParameters("accountingEngine", address(accountingEngine));
        globalSettlement.modifyParameters("oracleRelayer", address(oracleRelayer));
        if (address(coinSavingsAccount) != address(0)) {
          globalSettlement.modifyParameters("coinSavingsAccount", address(coinSavingsAccount));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          globalSettlement.modifyParameters("stabilityFeeTreasury", address(stabilityFeeTreasury));
        }
        if (address(redemptionRateSetter) != address(0)) {
          globalSettlement.modifyParameters("rateSetter", address(redemptionRateSetter));
        } else if (address(emergencyRateSetter) != address(0)) {
          globalSettlement.modifyParameters("rateSetter", address(emergencyRateSetter));
        }

        // Internal auth
        cdpEngine.addAuthorization(address(globalSettlement));
        liquidationEngine.addAuthorization(address(globalSettlement));
        accountingEngine.addAuthorization(address(globalSettlement));
        oracleRelayer.addAuthorization(address(globalSettlement));
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.addAuthorization(address(globalSettlement));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.addAuthorization(address(globalSettlement));
        }
        if (address(redemptionRateSetter) != address(0)) {
          redemptionRateSetter.addAuthorization(address(globalSettlement));
        } else if (address(emergencyRateSetter) != address(0)) {
          emergencyRateSetter.addAuthorization(address(globalSettlement));
        }

        // Deploy ESM
        esm = esmFactory.newESM(prot, address(globalSettlement), address(tokenBurner), threshold);
        globalSettlement.addAuthorization(address(esm));
    }

    function deployPause(uint delay, DSAuthority authority) public auth {
        require(address(coin) != address(0), "Missing previous step");
        require(address(globalSettlement) != address(0), "Missing previous step");

        pause = pauseFactory.newPause(delay, address(0), authority);
    }

    function giveControl(address usr) public auth {
        cdpEngine.addAuthorization(address(usr));
        liquidationEngine.addAuthorization(address(usr));
        accountingEngine.addAuthorization(address(usr));
        taxCollector.addAuthorization(address(usr));
        oracleRelayer.addAuthorization(address(usr));
        preSettlementSurplusAuctionHouse.addAuthorization(address(usr));
        postSettlementSurplusAuctionHouse.addAuthorization(address(usr));
        debtAuctionHouse.addAuthorization(address(usr));
        globalSettlement.addAuthorization(address(usr));
        esm.addAuthorization(address(usr));
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.addAuthorization(address(usr));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.addAuthorization(address(usr));
        }
        if (address(moneyMarketSetter) != address(0)) {
          moneyMarketSetter.addAuthorization(address(usr));
        }
        if (address(settlementSurplusAuctioneer) != address(0)) {
          settlementSurplusAuctioneer.addAuthorization(address(usr));
        }
        if (address(redemptionRateSetter) != address(0)) {
          redemptionRateSetter.addAuthorization(address(usr));
        }
        if (address(emergencyRateSetter) != address(0)) {
          emergencyRateSetter.addAuthorization(address(usr));
        }
    }

    function takeControl(address usr) public auth {
        cdpEngine.removeAuthorization(address(usr));
        liquidationEngine.removeAuthorization(address(usr));
        accountingEngine.removeAuthorization(address(usr));
        taxCollector.removeAuthorization(address(usr));
        oracleRelayer.removeAuthorization(address(usr));
        preSettlementSurplusAuctionHouse.removeAuthorization(address(usr));
        postSettlementSurplusAuctionHouse.removeAuthorization(address(usr));
        debtAuctionHouse.removeAuthorization(address(usr));
        globalSettlement.removeAuthorization(address(usr));
        esm.removeAuthorization(address(usr));
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.removeAuthorization(address(usr));
        }
        if (address(redemptionRateSetter) != address(0)) {
          redemptionRateSetter.removeAuthorization(address(usr));
        }
        if (address(emergencyRateSetter) != address(0)) {
          emergencyRateSetter.removeAuthorization(address(usr));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.removeAuthorization(address(usr));
        }
        if (address(moneyMarketSetter) != address(0)) {
          moneyMarketSetter.removeAuthorization(address(usr));
        }
        if (address(settlementSurplusAuctioneer) != address(0)) {
          settlementSurplusAuctioneer.removeAuthorization(address(usr));
        }
    }

    function addAuthToCollateralAuctionHouse(bytes32 collateralType, address usr) public auth {
        require(address(collateralTypes[collateralType].collateralAuctionHouse) != address(0), "CollateralAuctionHouse not initialized");
        collateralTypes[collateralType].collateralAuctionHouse.addAuthorization(usr);
    }

    function releaseAuthCollateralAuctionHouse(bytes32 collateralType, address usr) public auth {
        collateralTypes[collateralType].collateralAuctionHouse.removeAuthorization(usr);
    }

    function deployCollateral(
      bytes32 collateralType, address adapter, address orcl, uint bidToMarketPriceRatio
    ) public auth {
        require(collateralType != bytes32(""), "Missing collateralType name");
        require(adapter != address(0), "Missing adapter address");
        require(orcl != address(0), "Missing PIP address");

        // Deploy
        collateralTypes[collateralType].collateralAuctionHouse =
          collateralAuctionHouseFactory.newCollateralAuctionHouse(address(cdpEngine), collateralType);
        collateralTypes[collateralType].adapter = adapter;
        OracleRelayer(oracleRelayer).modifyParameters(collateralType, "orcl", address(orcl));

        // Internal references set up
        liquidationEngine.modifyParameters(collateralType, "collateralAuctionHouse", address(collateralTypes[collateralType].collateralAuctionHouse));
        cdpEngine.initializeCollateralType(collateralType);
        taxCollector.initializeCollateralType(collateralType);

        // Internal auth
        cdpEngine.addAuthorization(adapter);
        collateralTypes[collateralType].collateralAuctionHouse.addAuthorization(address(liquidationEngine));
        collateralTypes[collateralType].collateralAuctionHouse.addAuthorization(address(globalSettlement));

        // Set bid restrictions
        CollateralAuctionHouse(address(collateralTypes[collateralType].collateralAuctionHouse)).modifyParameters("bidToMarketPriceRatio", bidToMarketPriceRatio);
        CollateralAuctionHouse(address(collateralTypes[collateralType].collateralAuctionHouse)).modifyParameters("oracleRelayer", address(oracleRelayer));
        CollateralAuctionHouse(address(collateralTypes[collateralType].collateralAuctionHouse)).modifyParameters("orcl", address(orcl));
    }

    function releaseAuth() public auth {
        cdpEngine.removeAuthorization(address(this));
        liquidationEngine.removeAuthorization(address(this));
        accountingEngine.removeAuthorization(address(this));
        taxCollector.removeAuthorization(address(this));
        coin.removeAuthorization(address(this));
        oracleRelayer.removeAuthorization(address(this));
        preSettlementSurplusAuctionHouse.removeAuthorization(address(this));
        postSettlementSurplusAuctionHouse.removeAuthorization(address(this));
        debtAuctionHouse.removeAuthorization(address(this));
        globalSettlement.removeAuthorization(address(this));
        esm.removeAuthorization(address(this));
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.removeAuthorization(address(this));
        }
        if (address(redemptionRateSetter) != address(0)) {
          redemptionRateSetter.removeAuthorization(address(this));
        }
        if (address(emergencyRateSetter) != address(0)) {
          emergencyRateSetter.removeAuthorization(address(this));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.removeAuthorization(address(address(this)));
        }
        if (address(moneyMarketSetter) != address(0)) {
          moneyMarketSetter.removeAuthorization(address(address(this)));
        }
        if (address(settlementSurplusAuctioneer) != address(0)) {
          settlementSurplusAuctioneer.removeAuthorization(address(address(this)));
        }
    }

    function addCreatorAuth() public auth {
        cdpEngine.addAuthorization(msg.sender);
        accountingEngine.addAuthorization(msg.sender);
    }
}
