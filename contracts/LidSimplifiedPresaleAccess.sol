pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
//TODO: Replace with abstract sc or interface. mocks should only be for testing
import "./mocks/LidStaking.sol";


contract LidSimplifiedPresaleAccess is Initializable {
    using SafeMath for uint;
    LidStaking private staking;

    function initialize(LidStaking _staking) external initializer {
        staking = _staking;
    }

    function getAccessTime(address account, uint startTime) external view returns (uint accessTime) {
        uint stakeValue = staking.stakeValue(account);
        if (stakeValue == 0) return startTime.add(15 minutes);
        if (stakeValue >= 500000 ether) return startTime.add(3 minutes));
        if (stakeValue >= 100000 ether) return startTime.add(6 minutes));
        if (stakeValue >= 50000 ether) return startTime.add(9 minutes));
        if (stakeValue >= 25000 ether) return startTime.add(12 minutes));
        if (stakeValue >=  1 ether) return startTime.add(15 minutes));
    }
}