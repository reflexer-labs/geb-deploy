pragma solidity ^0.6.7;

abstract contract Setter {
    function modifyParameters(bytes32, address) virtual public;
    function modifyParameters(bytes32, uint) virtual public;
    function modifyParameters(bytes32, uint, uint) virtual public;
    function modifyParameters(bytes32, uint, uint, address) virtual public;
    function modifyParameters(bytes32, bytes32, uint) virtual public;
    function modifyParameters(bytes32, bytes32, address) virtual public;
    function addAuthorization(address) virtual public;
    function removeAuthorization(address) virtual public;
    function initializeCollateralType(bytes32) virtual public;
    function updateAccumulatedRate() virtual public;
    function redemptionPrice() virtual public;
    function taxMany(uint start, uint end) virtual public;
    function taxSingle(bytes32) virtual public;
    function setAllowance(address, uint256) virtual external;
}

abstract contract GlobalSettlementLike {
    function shutdownSystem() virtual public;
    function freezeCollateralType(bytes32) virtual public;
}

abstract contract PauseLike {
    function setAuthority(address) virtual public;
    function setDelay(uint) virtual public;
    function setDelayMultiplier(uint) virtual public;
    function setProtester(address) virtual public;
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

    function modifyParameters(address targetContract, bytes32 parameter, uint data1, uint data2) public {
        Setter(targetContract).modifyParameters(parameter, data1, data2);
    }

    function modifyParameters(address targetContract, bytes32 collateralType, uint data1, uint data2, address data3) public {
        Setter(targetContract).modifyParameters(collateralType, data1, data2, data3);
    }

    function modifyTwoParameters(
      address targetContract1,
      address targetContract2,
      bytes32 parameter1,
      bytes32 parameter2,
      uint data1,
      uint data2
    ) public {
      Setter(targetContract1).modifyParameters(parameter1, data1);
      Setter(targetContract2).modifyParameters(parameter2, data2);
    }

    function modifyTwoParameters(
      address targetContract1,
      address targetContract2,
      bytes32 collateralType1,
      bytes32 collateralType2,
      bytes32 parameter1,
      bytes32 parameter2,
      uint data1,
      uint data2
    ) public {
      Setter(targetContract1).modifyParameters(collateralType1, parameter1, data1);
      Setter(targetContract2).modifyParameters(collateralType2, parameter2, data2);
    }

    function removeAuthorizationAndModify(
      address targetContract,
      address to,
      bytes32 parameter,
      uint data
    ) public {
      Setter(targetContract).removeAuthorization(to);
      Setter(targetContract).modifyParameters(parameter, data);
    }

    function updateRateAndModifyParameters(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).updateAccumulatedRate();
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxManyAndModifyParameters(address targetContract, uint start, uint end, bytes32 parameter, uint data) public {
        Setter(targetContract).taxMany(start, end);
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxSingleAndModifyParameters(address targetContract, bytes32 collateralType, bytes32 parameter, uint data) public {
        Setter(targetContract).taxSingle(collateralType);
        Setter(targetContract).modifyParameters(collateralType, parameter, data);
    }

    function updateRedemptionRate(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).redemptionPrice();
        Setter(targetContract).modifyParameters(parameter, data);
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

    function setProtester(address pause, address protester) public {
        PauseLike(pause).setProtester(protester);
    }

    function setDelay(address pause, uint newDelay) public {
        PauseLike(pause).setDelay(newDelay);
    }

    function setAuthorityAndDelay(address pause, address newAuthority, uint newDelay) public {
        PauseLike(pause).setAuthority(newAuthority);
        PauseLike(pause).setDelay(newDelay);
    }

    function setDelayMultiplier(address pause, uint delayMultiplier) public {
        PauseLike(pause).setDelayMultiplier(delayMultiplier);
    }

    function setAllowance(address join, address account, uint allowance) public {
        Setter(join).setAllowance(account, allowance);
    }

    function multiSetAllowance(address join, address[] memory accounts, uint[] memory allowances) public {
        for (uint i = 0; i < accounts.length; i++) {
            Setter(join).setAllowance(accounts[i], allowances[i]);
        }
    }
}
