pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
//TODO: Replace with abstract sc or interface. mocks should only be for testing
import "./mocks/LidStaking.sol";

contract LidSimplifiedPresaleAccess is Initializable {
    using SafeMath for uint;
    LidStaking private staking;

    uint[24] private decayCurve;

    function initialize(LidStaking _staking) external initializer {
        staking = _staking;
        //Precalculated
        decayCurve = [
            1000000,
            750000,
            562500,
            421875,
            316406,
            237305,
            177979,
            133484,
            100113,
            75085,
            56314,
            42235,
            31676,
            23757,
            17818,
            13363,
            10023,
            7517,
            5638,
            4228,
            3171,
            2378,
            1784,
            0
        ];
    }

    function getAccessTime(address account, uint startTime) external view returns (uint accessTime) {
        uint stakeValue = staking.stakeValue(account);
        if (stakeValue == 0) return startTime.add(24 hours);
        if (stakeValue >= decayCurve[0]) return startTime;
        uint i=0;
        uint stake2 = decayCurve[0];
        while (stake2 > stakeValue && i < 24) {
            i++;
            stake2 = decayCurve[i];
        }
        if (stake2 == stakeValue) return startTime.add(i.add(1).mul(1 hours));
        return interpolate(
            startTime.add(i.mul(1 hours)),
            startTime.add(i.add(1).mul(1 hours)),
            decayCurve[i.sub(1)],
            decayCurve[i],
            stakeValue
        );
    }

    //Returns the linearly interpolated time between two timeX/stakeX points based on a stakeValue.
    function interpolate(
        uint time1,
        uint time2,
        uint stake1,
        uint stake2,
        uint stakeValue
    ) public pure returns (uint) {
        require(stakeValue > stake2, "stakeValue must be gt stake2");
        require(stakeValue < stake1, "stakeValue must be lt stake1");
        require(time2 > time1, "time2 must be after time1");
        return time1.mul(
            stakeValue.sub(stake2)
        ).add(
            time2.mul(
                stake1.sub(stakeValue)
            )
        ).div(
            stake1.sub(stake2)
        );
    }
}
