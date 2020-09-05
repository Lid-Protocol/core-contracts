pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/lifecycle/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./uniswapV2Periphery/interfaces/IUniswapV2Router01.sol";
import "./library/BasisPoints.sol";
import "./LidSimplifiedPresaleTimer.sol";
import "./LidSimplifiedPresaleRedeemer.sol";
import "./LidSimplifiedPresaleAccess.sol";


contract LidSimplifiedPresale is Initializable, Ownable, ReentrancyGuard, Pausable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public maxBuyPerAddress;

    uint public referralBP;

    uint public uniswapEthBP;
    uint public lidEthBP;

    uint public uniswapTokenBP;
    uint public presaleTokenBP;
    address[] public tokenPools;
    uint[] public tokenPoolBPs;

    uint public hardcap;
    uint public totalTokens;

    bool public hasSentToUniswap;
    bool public hasIssuedTokens;

    uint public finalEndTime;
    uint public finalEth;

    IERC20 private token;
    IUniswapV2Router01 private uniswapRouter;
    LidSimplifiedPresaleTimer private timer;
    LidSimplifiedPresaleRedeemer private redeemer;
    LidSimplifiedPresaleAccess private access;
    address payable private lidFund;

    mapping(address => uint) public accountEthDeposit;
    mapping(address => uint) public earnedReferrals;

    mapping(address => uint) public referralCounts;

    modifier whenPresaleActive {
        require(timer.isStarted(), "Presale not yet started.");
        require(!isPresaleEnded(), "Presale has ended.");
        _;
    }

    modifier whenPresaleFinished {
        require(timer.isStarted(), "Presale not yet started.");
        require(isPresaleEnded(), "Presale has not yet ended.");
        _;
    }

    function initialize(
        uint _maxBuyPerAddress,
        uint _uniswapEthBP,
        uint _lidEthBP,
        uint _referralBP,
        uint _hardcap,
        address owner,
        LidSimplifiedPresaleTimer _timer,
        LidSimplifiedPresaleRedeemer _redeemer,
        LidSimplifiedPresaleAccess _access,
        IERC20 _token,
        IUniswapV2Router01 _uniswapRouter,
        address payable _lidFund
    ) external initializer {
        Ownable.initialize(msg.sender);
        Pausable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        token = _token;
        timer = _timer;
        redeemer = _redeemer;
        access = _access;
        lidFund = _lidFund;

        maxBuyPerAddress = _maxBuyPerAddress;

        uniswapEthBP = _uniswapEthBP;
        lidEthBP = _lidEthBP;

        referralBP = _referralBP;
        hardcap = _hardcap;

        uniswapRouter = _uniswapRouter;
        totalTokens = token.totalSupply();
        token.approve(address(uniswapRouter), token.totalSupply());

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function deposit() external payable whenNotPaused {
        deposit(address(0x0));
    }

    function setTokenPools(
        uint _uniswapTokenBP,
        uint _presaleTokenBP,
        address[] calldata _tokenPools,
        uint[] calldata _tokenPoolBPs
    ) external onlyOwner whenNotPaused {
        require(_tokenPools.length == _tokenPoolBPs.length, "Must have exactly one tokenPool addresses for each BP.");
        delete tokenPools;
        delete tokenPoolBPs;
        uniswapTokenBP = _uniswapTokenBP;
        presaleTokenBP = _presaleTokenBP;
        for (uint i = 0; i < _tokenPools.length; ++i) {
            tokenPools.push(_tokenPools[i]);
        }
        uint totalTokenPoolBPs = uniswapTokenBP.add(presaleTokenBP);
        for (uint i = 0; i < _tokenPoolBPs.length; ++i) {
            tokenPoolBPs.push(_tokenPoolBPs[i]);
            totalTokenPoolBPs = totalTokenPoolBPs.add(_tokenPoolBPs[i]);
        }
        require(totalTokenPoolBPs == 10000, "Must allocate exactly 100% (10000 BP) of tokens to pools");
    }

    function sendToUniswap() external whenPresaleFinished nonReentrant whenNotPaused {
        require(msg.sender == tx.origin, "Sender must be origin - no contract calls.");
        require(tokenPools.length > 0, "Must have set token pools");
        require(!hasSentToUniswap, "Has already sent to Uniswap.");
        finalEndTime = now;
        finalEth = address(this).balance;
        hasSentToUniswap = true;
        uint uniswapTokens = totalTokens.mulBP(uniswapTokenBP);
        uint uniswapEth = finalEth.mulBP(uniswapEthBP);
        uniswapRouter.addLiquidityETH.value(uniswapEth)(
            address(token),
            uniswapTokens,
            uniswapTokens,
            uniswapEth,
            address(0x000000000000000000000000000000000000dEaD),
            now
        );
    }

    function issueTokens() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        require(!hasIssuedTokens, "Has already issued tokens.");
        hasIssuedTokens = true;
        for (uint i = 0; i < tokenPools.length; ++i) {
            token.transfer(
                tokenPools[i],
                totalTokens.mulBP(tokenPoolBPs[i])
            );
        }
    }

    function releaseEthToAddress(address payable receiver, uint amount) external onlyOwner whenNotPaused returns(uint) {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        receiver.transfer(amount);
    }

    function redeem() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Must have sent to Uniswap before any redeems.");
        uint claimable = redeemer.calculateReedemable(msg.sender, finalEndTime, totalTokens.mulBP(presaleTokenBP));
        redeemer.setClaimed(msg.sender, claimable);
        token.transfer(msg.sender, claimable);
    }

    function deposit(address payable referrer) public payable whenPresaleActive nonReentrant whenNotPaused {
        require(now >= access.getAccessTime(msg.sender, timer.startTime()), "Time must be at least access time.");
        uint endTime = timer.updateEndTime();
        require(endTime == 0 || endTime >= now, "Endtime past.");
        require(msg.sender != referrer, "Sender cannot be referrer.");
        uint accountCurrentDeposit = redeemer.accountDeposits(msg.sender);
        uint fee = msg.value.mulBP(referralBP);
        //Remove fee in case final purchase needed to end sale without dust errors
        if (msg.value < 0.01 ether) fee = 0;
        require(
            accountCurrentDeposit.add(msg.value) <= getMaxWhitelistedDeposit(),
            "Deposit exceeds max buy per address for whitelisted addresses."
        );
        require(address(this).balance.sub(fee) <= hardcap, "Cannot deposit more than hardcap.");

        redeemer.setDeposit(msg.sender, msg.value.sub(fee), address(this).balance.sub(fee));

        if (referrer != address(0x0) && referrer != msg.sender) {
            earnedReferrals[referrer] = earnedReferrals[referrer].add(fee);
            referralCounts[referrer] = referralCounts[referrer].add(1);
            referrer.transfer(fee);
        } else {
            lidFund.transfer(fee);
        }
    }

    function getMaxWhitelistedDeposit() public view returns (uint) {
        return maxBuyPerAddress;
    }

    function isPresaleEnded() public view returns (bool) {
        uint endTime =  timer.endTime();
        if (hasSentToUniswap) return true;
        return (
            (address(this).balance >= hardcap) ||
            (timer.isStarted() && (now > endTime && endTime != 0))
        );
    }

}
