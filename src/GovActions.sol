pragma solidity ^0.5.15;

contract Setter {
    function modifyParameters(bytes32, address) public;
    function modifyParameters(bytes32, uint) public;
    function modifyParameters(bytes32, bytes32, uint) public;
    function modifyParameters(bytes32, bytes32, address) public;
    function addAuthorization(address) public;
    function removeAuthorization(address) public;
    function initializeCollateralType(bytes32) public;
    function updateAccumulatedRate() public;
    function taxAll() public;
    function taxSingle(bytes32) public;
}

contract GlobalSettlementLike {
    function shutdownSystem() public;
    function freezeCollateralType(bytes32) public;
}

contract PauseLike {
    function setAuthority(address) public;
    function setDelay(uint) public;
}

contract GovActions {
    function modifyParameters(address targetContract, bytes32 parameter, address data) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 collateralType, bytes32 parameter, uint data) public {
        Setter(targetContract).modifyParameters(collateralType, parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 collateralType, bytes32 parameter, address data) public {
        Setter(targetContract).modifyParameters(collateralType, parameter, data);
    }

    function updateRateAndModifyParameters(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).updateAccumulatedRate();
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxAllAndModifyParameters(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).taxAll();
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxSingleAndModifyParameters(address targetContract, bytes32 collateralType, bytes32 parameter, uint data) public {
        Setter(targetContract).taxSingle(collateralType);
        Setter(targetContract).modifyParameters(collateralType, parameter, data);
    }

    function addAuthorization(address targetContract, address to) public {
        Setter(targetContract).addAuthorization(to);
    }

    function removeAuthorization(address targetContract, address to) public {
        Setter(targetContract).removeAuthorization(to);
    }

    function initializeCollateralType(address targetContract, bytes32 collateralType) public {
        Setter(targetContract).initializeCollateralType(collateralType);
    }

    function shutdownSystem(address globalSettlement) public {
        GlobalSettlementLike(globalSettlement).shutdownSystem();
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
