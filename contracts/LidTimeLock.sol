pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "./library/BasisPoints.sol";


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

    modifier onlyAfterStart {
        require(releaseStart != 0 && now > releaseStart, "Has not yet started.");
        _;
    }

    function initialize(
        uint _releaseInterval,
        uint _releaseBP,
        address owner,
        IERC20 _token
    ) external initializer {
        releaseInterval = _releaseInterval;
        releaseBP = _releaseBP;
        token = _token;

        Ownable.initialize(msg.sender);

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function claimToken() external onlyAfterStart {
        require(releaseStart != 0, "Has not yet started.");
        uint cycle = getCurrentCycleCount();
        uint totalClaimAmount = cycle.mul(startingTokens.mulBP(releaseBP));
        uint toClaim = totalClaimAmount.sub(claimedTokens);
        if (token.balanceOf(address(this)) < toClaim) toClaim = token.balanceOf(address(this));
        claimedTokens = claimedTokens.add(toClaim);
        token.transfer(releaseWallet, toClaim);
    }

    function startRelease(address _releaseWallet) external onlyOwner {
        require(releaseStart == 0, "Has already started.");
        require(token.balanceOf(address(this)) != 0, "Must have some lid deposited.");
        releaseWallet = _releaseWallet;
        startingTokens = token.balanceOf(address(this));
        releaseStart = now.add(24 hours);
    }

    function getCurrentCycleCount() public view returns (uint) {
        if (now <= releaseStart) return 0;
        return now.sub(releaseStart).div(releaseInterval).add(1);
    }

}
