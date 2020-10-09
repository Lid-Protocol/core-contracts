pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "./library/BasisPoints.sol";
import "./LidSimplifiedPresale.sol";


contract LidTimeLock is Initializable, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public releaseInterval;
    uint public releaseStart;
    uint public releaseBP;

    uint public startingTokens;
    uint public claimedTokens;

    IERC20 private token;

    address releaseWallet;
    
    LidSimplifiedPresale private presale;

    modifier onlyAfterStart {
        uint finalEndTime = presale.finalEndTime();
        require(finalEndTime != 0 && now > finalEndTime, "Has not yet started.");
        _;
    }

    function initialize(
        uint _releaseInterval,
        uint _releaseBP,
        address owner,
        IERC20 _token,
        LidSimplifiedPresale _presale,
        address _releaseWallet
    ) external initializer {
        releaseInterval = _releaseInterval;
        releaseBP = _releaseBP;
        token = _token;
        presale = _presale;
        releaseWallet = _releaseWallet;

        Ownable.initialize(msg.sender);

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function claimToken() external onlyAfterStart {
        startingTokens = token.balanceOf(address(this)).add(claimedTokens);
        uint cycle = getCurrentCycleCount();
        uint totalClaimAmount = cycle.mul(startingTokens.mulBP(releaseBP));
        uint toClaim = totalClaimAmount.sub(claimedTokens);
        if (token.balanceOf(address(this)) < toClaim) toClaim = token.balanceOf(address(this));
        claimedTokens = claimedTokens.add(toClaim);
        token.transfer(releaseWallet, toClaim);
    }

    function reset(
        uint _releaseInterval,
        uint _releaseBP,
        LidSimplifiedPresale _presale,
        address _releaseWallet
    ) external onlyOwner {
        releaseInterval = _releaseInterval;
        releaseBP = _releaseBP;
        presale = _presale;
        releaseWallet = _releaseWallet;
    }

    function setPresale(
        LidSimplifiedPresale _presale
    ) external onlyOwner {
        presale = _presale;
    }

    function getCurrentCycleCount() public view returns (uint) {
        uint finalEndTime = presale.finalEndTime();
        if (now <= finalEndTime || finalEndTime == 0) return 0;
        return now.sub(finalEndTime).div(releaseInterval).add(1);
    }

}
