# Security Tests

The contracts in this folder are the fuzz scripts for the CollateralJoin7 contract.

To run the fuzzer, set up Echidna (https://github.com/crytic/echidna) on your machine.

Then run
```
echidna-test src/test/fuzz/<name of file>.sol --contract <Name of contract> --config src/test/fuzz/echidna.yaml
```

Configs are in this folder (echidna.yaml).

In this run we will not be checking for bounds. The collateralJoin contract is actually bounded by the collateral supply, so there is little to test in terms of bounds.

# Results

## CollateralJoin7

### Contract Fuzz

This contract will setup a ```collateralJoin7``` (as well as a SAFEEngine). It generates a User contract for every address calling it to interact with Join (except for changing the flashLoan fee). It allows for as many users as setup in echidna to join, exit and flashloan random amounts. For every call a number of assertions are checked. It also allows for anyone to call ```fuzzFlashLoanFee()``` and change the fee to a random value up to 100%.

#### Public functions
#### join
Will use the callers contract to Join with collateral. Amount necessary to join is minted on the act by the fuzzing contract. If join succeeds it asserts:
- Contract is enabled;
- Balance of collateral in Join increased by the right amount;
- Balance of collateral from caller is decreased by the correct amount;
- Collateral balance in SAFEEngine increases by the correct amount.

#### exit
Will use the callers contract to exit collateral. If exit succeeds it asserts:
- Contract is enabled;
- Balance of collateral in Join decreased by the right amount;
- Balance of collateral from caller is increased by the correct amount;
- Collateral balance in SAFEEngine decreases by the correct amount.

#### flashloan
Will use the callers contract to request a flashloan. Flashloan fees are minted for caller so he can pay back.
- Contract is enabled;
- User balance remains constant;
- Join balance remains constant;
- FeeReceiver balance increases by the correct fee amount.

#### properties
In between every call to the public functions the following properties are checked:
- echidna_total_join: Total amount joined is accurate;
- echidna_supply_integrity: totalSupply from collateral is equal to sum of balance from all users, join and feeReceiver;
- echidna_join_integrity: Check all users collateralBalance in SAFEEngine;
- echidna_enabled: Contract remains enabled;
- echidna_collateralType: CollateralType is correct;
- echidna_collateral: Collateral address is correct;
- echidna_decimals: Decimals is unchanged (contract enforces 18);
- echidna_feeReceiver: FeeReceiver is correct;
- echidna_loanFee: LoanFee is correct.

Note: To check if all functions execute without error dapp tools can be used (```dapp test -m test_fuzz```). The config file (echidna.yaml) is setup to ignore the functions used for testing with DSTest. Test with checkAsserts: true to ensure the assertions in the public functions are tested by echidna.

Results:
```
Analyzing contract: /Users/fabio/Documents/reflexer/geb-deploy/src/test/fuzz/collateralJoin7Fuzz.sol:Fuzz
echidna_collateral: passed! 🎉
echidna_collateralType: passed! 🎉
echidna_total_join: passed! 🎉
echidna_loanFee: passed! 🎉
echidna_join_integrity: passed! 🎉
echidna_feeReceiver: passed! 🎉
echidna_decimals: passed! 🎉
echidna_supply_integrity: passed! 🎉
echidna_enabled: passed! 🎉
assertion in join: passed! 🎉
assertion in flashloan: passed! 🎉
assertion in exit: passed! 🎉
assertion in fuzzFlashLoanFee: passed! 🎉

Seed: 7142549760982577499
```

#### Conclusion: No exceptions noted

