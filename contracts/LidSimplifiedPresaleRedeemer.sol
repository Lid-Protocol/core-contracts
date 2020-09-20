pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./uniswapV2Periphery/interfaces/IUniswapV2Router01.sol";
import "./library/BasisPoints.sol";
import "./LidSimplifiedPresaleTimer.sol";


contract LidSimplifiedPresaleRedeemer is Initializable, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public redeemBP;
    uint public redeemInterval;

    uint[] public bonusRangeStart;
    uint[] public bonusRangeBP;
    uint public currentBonusIndex;

    uint public totalShares;
    uint public totalDepositors;
    mapping(address => uint) public accountDeposits;
    mapping(address => uint) public accountShares;
    mapping(address => uint) public accountClaimedTokens;

    address private presale;

    modifier onlyPresaleContract {
        require(msg.sender == presale, "Only callable by presale contract.");
        _;
    }

    function initialize(
        uint _redeemBP,
        uint _redeemInterval,
        uint[] calldata _bonusRangeStart,
        uint[] calldata _bonusRangeBP,
        address _presale,
        address owner
    ) external initializer {
        Ownable.initialize(msg.sender);

        redeemBP = _redeemBP;
        redeemInterval = _redeemInterval;
        presale = _presale;

        require(
            _bonusRangeStart.length == _bonusRangeBP.length,
            "Must have equal values for bonus range start and BP"
        );
        require(_bonusRangeStart.length <= 10, "Cannot have more than 10 items in bonusRange");
        for (uint i = 0; i < _bonusRangeStart.length; ++i) {
            bonusRangeStart.push(_bonusRangeStart[i]);
        }
        for (uint i = 0; i < _bonusRangeBP.length; ++i) {
            bonusRangeBP.push(_bonusRangeBP[i]);
        }

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function setClaimed(address account, uint amount) external onlyPresaleContract {
        accountClaimedTokens[account] = accountClaimedTokens[account].add(amount);
    }

    function setDeposit(address account, uint deposit, uint postDepositEth) external onlyPresaleContract {
        if (accountDeposits[account] == 0) totalDepositors = totalDepositors.add(1);
        accountDeposits[account] = accountDeposits[account].add(deposit);
        uint sharesToAdd;
        if (currentBonusIndex.add(1) >= bonusRangeBP.length) {
            //final bonus rate
            sharesToAdd = deposit.addBP(bonusRangeBP[currentBonusIndex]);
        } else if (postDepositEth < bonusRangeStart[currentBonusIndex.add(1)]) {
            //Purchase doesnt push to next start
            sharesToAdd = deposit.addBP(bonusRangeBP[currentBonusIndex]);
        } else {
            //purchase straddles next start
            uint previousBonusBP = bonusRangeBP[currentBonusIndex];
            uint newBonusBP = bonusRangeBP[currentBonusIndex.add(1)];
            uint newBonusDeposit = postDepositEth.sub(bonusRangeStart[currentBonusIndex.add(1)]);
            uint previousBonusDeposit = deposit.sub(newBonusDeposit);
            sharesToAdd = newBonusDeposit.addBP(newBonusBP).add(
                previousBonusDeposit.addBP(previousBonusBP));
            currentBonusIndex = currentBonusIndex.add(1);
        }
        accountShares[account] = accountShares[account].add(sharesToAdd);
        totalShares = totalShares.add(sharesToAdd);
    }

    function updateBonus(
        uint[] calldata _bonusRangeStart,
        uint[] calldata _bonusRangeBP
    ) external onlyOwner {
        require(
            _bonusRangeStart.length == _bonusRangeBP.length,
            "Must have equal values for bonus range start and BP"
        );
        require(_bonusRangeStart.length <= 10, "Cannot have more than 10 items in bonusRange");
        for (uint i = 0; i < _bonusRangeStart.length; ++i) {
            bonusRangeStart.push(_bonusRangeStart[i]);
        }
        for (uint i = 0; i < _bonusRangeBP.length; ++i) {
            bonusRangeBP.push(_bonusRangeBP[i]);
        }
    }

    function calculateRatePerEth(uint totalPresaleTokens, uint depositEth, uint hardCap) external view returns (uint) {

        uint tokensPerEtherShare = totalPresaleTokens
        .mul(1 ether)
        .div(
            getMaxShares(hardCap)
        );

        uint bp;
        if (depositEth >= bonusRangeStart[bonusRangeStart.length.sub(1)]) {
            bp = bonusRangeBP[bonusRangeBP.length.sub(1)];
        } else {
            for (uint i = 1; i < bonusRangeStart.length; ++i) {
                if (bp == 0) {
                    if (depositEth < bonusRangeStart[i]) {
                        bp = bonusRangeBP[i.sub(1)];
                    }
                }
            }
        }
        return tokensPerEtherShare.addBP(bp);
    }

    function calculateReedemable(
        address account,
        uint finalEndTime,
        uint totalPresaleTokens
    ) external view returns (uint) {
        if (finalEndTime == 0) return 0;
        if (finalEndTime >= now) return 0;
        uint earnedTokens = accountShares[account].mul(totalPresaleTokens).div(totalShares);
        uint claimedTokens = accountClaimedTokens[account];
        uint cycles = now.sub(finalEndTime).div(redeemInterval).add(1);
        uint totalRedeemable = earnedTokens.mulBP(redeemBP).mul(cycles);
        uint claimable;
        if (totalRedeemable >= earnedTokens) {
            claimable = earnedTokens.sub(claimedTokens);
        } else {
            claimable = totalRedeemable.sub(claimedTokens);
        }
        return claimable;
    }

    function getMaxShares(uint hardCap) public view returns (uint) {
        uint maxShares;
        for (uint i = 0; i < bonusRangeStart.length; ++i) {
            uint amt;
            if (i < bonusRangeStart.length.sub(1)) {
                amt = bonusRangeStart[i.add(1)].sub(bonusRangeStart[i]);
            } else {
                amt = hardCap.sub(bonusRangeStart[i]);
            }
            maxShares = maxShares.add(amt.addBP(bonusRangeBP[i]));
        }
        return maxShares;
    }
}
