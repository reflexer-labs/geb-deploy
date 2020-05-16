pragma solidity ^0.5.6;

contract TokenLike {
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
}

contract GlobalSettlementLike {
    function shutdownSystem() public;
}

contract ESM {
    TokenLike public protocolToken;   // collateral
    GlobalSettlementLike public globalSettlement;  // shutdown module
    address public tokenBurner;       // burner
    uint256 public triggerThreshold;  // threshold
    uint256 public settled;

    mapping(address => uint256) public burntTokens; // per-address balance
    uint256 public totalAmountBurnt; // total balance

    // --- Logs ---
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize                         // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller,                              // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }

    constructor(address protocolToken_, address globalSettlement_, address tokenBurner_, uint256 triggerThreshold_) public {
        protocolToken = TokenLike(protocolToken_);
        globalSettlement = GlobalSettlementLike(globalSettlement_);
        tokenBurner = tokenBurner_;
        triggerThreshold = triggerThreshold_;
    }

    // -- math --
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function shutdown() external note {
        require(settled == 0,  "esm/already-settled");
        require(totalAmountBurnt >= triggerThreshold, "esm/threshold-not-reached");
        globalSettlement.shutdownSystem();
        settled = 1;
    }

    function burnTokens(uint256 amountToBurn) external note {
        require(settled == 0, "esm/already-settled");

        burntTokens[msg.sender] = add(burntTokens[msg.sender], amountToBurn);
        totalAmountBurnt = add(totalAmountBurnt, amountToBurn);

        require(protocolToken.transferFrom(msg.sender, tokenBurner, amountToBurn), "esm/transfer-failed");
    }
}
