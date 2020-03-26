pragma solidity ^0.5.11;

contract Setter {
    function file(address) public;
    function file(uint256) public;
    function file(bytes32) public;
    function file(bytes32, address) public;
    function file(bytes32, uint) public;
    function file(bytes32, bytes32, uint) public;
    function file(bytes32, bytes32, address) public;
    function file(bytes32, address, bool) public;

    function hire(address) public;
    function fire(address) public;

    function hope(address) public;
    function nope(address) public;

    function rely(address) public;
    function deny(address) public;

    function init(bytes32) public;

    function drip() public;
    function drip(bytes32) public;

    function back() public;
}

contract EndLike {
    function cage() public;
    function cage(bytes32) public;
}

contract PauseLike {
    function setAuthority(address) public;
    function setDelay(uint) public;
}

contract GovActions {
    function file(address who, bytes32 data) public {
        Setter(who).file(data);
    }

    function file(address who, address data) public {
        Setter(who).file(data);
    }

    function file(address who, uint256 data) public {
        Setter(who).file(data);
    }

    function file(address who, bytes32 what, address data) public {
        Setter(who).file(what, data);
    }

    function file(address who, bytes32 what, uint data) public {
        Setter(who).file(what, data);
    }

    function file(address who, bytes32 ilk, bytes32 what, uint data) public {
        Setter(who).file(ilk, what, data);
    }

    function file(address who, bytes32 ilk, bytes32 what, address data) public {
        Setter(who).file(ilk, what, data);
    }

    function file(address who, bytes32 ilk, address urn, bool data) public {
        Setter(who).file(ilk, urn, data);
    }

    function hire(address who, address data) public {
        Setter(who).hire(data);
    }

    function fire(address who, address data) public {
        Setter(who).fire(data);
    }

    function dripAndBack(address x, address y) public {
        Setter(x).drip();
        Setter(y).drip();
        Setter(x).back();
    }

    function dripAndFile(address who, bytes32 what, uint data) public {
        Setter(who).drip();
        Setter(who).file(what, data);
    }

    function dripAndFile(address who, bytes32 ilk, bytes32 what, uint data) public {
        Setter(who).drip(ilk);
        Setter(who).file(ilk, what, data);
    }

    function hope(address who, address usr) public {
        Setter(who).hope(usr);
    }

    function nope(address who, address usr) public {
        Setter(who).nope(usr);
    }

    function rely(address who, address to) public {
        Setter(who).rely(to);
    }

    function deny(address who, address to) public {
        Setter(who).deny(to);
    }

    function init(address who, bytes32 ilk) public {
        Setter(who).init(ilk);
    }

    function cage(address who, bytes32 data) public {
        EndLike(who).cage(data);
    }

    function cage(address end) public {
        EndLike(end).cage();
    }

    function setAuthority(address pause, address newAuthority) public {
        PauseLike(pause).setAuthority(newAuthority);
    }

    function setDelay(address pause, uint newDelay) public {
        PauseLike(pause).setDelay(newDelay);
    }

    function setAuthorityAndDelay(address pause, address newAuthority, uint newDelay) public {
        PauseLike(pause).setAuthority(newAuthority);
        PauseLike(pause).setDelay(newDelay);
    }
}
