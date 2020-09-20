pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract LidSimplifiedPresaleTimer is Initializable, Ownable {
    using SafeMath for uint;

    uint public startTime;
    uint public endTime;
    uint public hardCapTimer;
    uint public softCap;
    address public presale;

    function initialize(
        uint _startTime,
        uint _hardCapTimer,
        uint _softCap,
        address _presale,
        address owner
    ) external initializer {
        Ownable.initialize(msg.sender);
        startTime = _startTime;
        hardCapTimer = _hardCapTimer;
        softCap = _softCap;
        presale = _presale;
        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function setStartTime(uint time) external onlyOwner {
        startTime = time;
    }

    function setEndTime(uint time) external onlyOwner {
        endTime = time;
    }

    function updateSoftCap(uint valueWei) external onlyOwner {
        softCap = valueWei;
    }

    function updateEndTime() external returns (uint) {
        if (endTime != 0) return endTime;
        if (presale.balance >= softCap) {
            endTime = now.add(hardCapTimer);
            return endTime;
        }
        return 0;
    }

    function isStarted() external view returns (bool) {
        return (startTime != 0 && now > startTime);
    }

}
