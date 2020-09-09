//Importing test environment and bring up local blockchain to run tests 
const { accounts, contract, web3 } = require("@openzeppelin/test-environment");
//Importing oz test helpers
const {
  expectRevert,
  time,
  BN,
  ether,
  balance,
} = require("@openzeppelin/test-helpers");
//Importing chai
const { expect, assert } = require("chai");
//Importing config.js file 
const config = require("../config");

//Importing all smart contracts
const Token = contract.fromArtifact("Token");
const TeamLock = contract.fromArtifact("LidTimeLock");
const DaoLock = contract.fromArtifact("LidTimeLock");
const LidSimplifiedPresale = contract.fromArtifact("LidSimplifiedPresale");
const LidSimplifiedPresaleRedeemer = contract.fromArtifact("LidSimplifiedPresaleRedeemer");
const LidSimplifiedPresaleTimer = contract.fromArtifact("LidSimplifiedPresaleTimer");
const LidSimplifiedPresaleAccess = contract.fromArtifact("LidSimplifiedPresaleAccess");

//defining account holder names. The accounts[] array is provided by oz
const owner = accounts[0];
const depositors = [
  accounts[1],
  accounts[2],
  accounts[3],
  accounts[4],
  accounts[5],
];
const projectFund = accounts[6];
const teamFund = accounts[7];
const initialTokenHolder = accounts[8];

//Defining MAX tokens
const TOTAL_TOKENS = ether("100000000");

const SECONDS_PER_HOUR = 3600;

/** 
 * Testing the functionalities of LidSimplifiedPresale
*/
describe("LidSimplifiedPresale", function () {
  //execute following before everyone else
  before(async function () {
  
    this.Token = await Token.new();
    this.TeamLock = await TeamLock.new();
    this.DaoLock = await DaoLock.new();
    this.Presale = await LidSimplifiedPresale.new();
    this.Redeemer = await LidSimplifiedPresaleRedeemer.new();
    this.Timer = await LidSimplifiedPresaleTimer.new();
    this.Access = await LidSimplifiedPresaleAccess.new();

    //initialising Token SC
    await this.Token.initialize(TOTAL_TOKENS, initialTokenHolder);
    //Initialising Redeemer SC
    await this.Redeemer.initialize(
      config.redeemer.redeemBP,
      config.redeemer.redeemInterval,
      config.redeemer.bonusRangeStart,
      config.redeemer.bonusRangeBP,
      this.Presale.address,
      owner
    );
    //Initialising Presale SC
    await this.Presale.initialize(
      config.presale.maxBuyPerAddress,
      config.presale.uniswapEthBP,
      config.presale.lidEthBP,
      config.presale.referralBP,
      config.presale.hardcap,
      owner,
      this.Timer.address,
      this.Redeemer.address,
      this.Access.address,
      this.Token.address,
      config.presale.uniswapRouter,
      config.presale.lidFund
    );

    //Transferring all tokens to Presale SC
    await this.Token.transfer(this.Presale.address, TOTAL_TOKENS, {
      from: initialTokenHolder,
    });
    //Setting up the token pools
    this.Presale.setTokenPools(
      config.presale.uniswapTokenBP,
      config.presale.presaleTokenBP,
      [this.DaoLock.address, this.TeamLock.address, projectFund],
      [
        config.presale.tokenDistributionBP.dev,
        config.presale.tokenDistributionBP.marketing,
        config.presale.tokenDistributionBP.team,
      ]
    );
  });

  //// STARTING TESTS ////

  /** 
   * Testing the functionalities before the presale has started
  */
  describe("State: Before Presale Start", function () {
    before(async function () {
      const startTime = await this.Timer.startTime();
    });
    //function Presale.deposit()
    describe("#deposit", function () {
      it("Should revert", async function () {
        await expectRevert(
          this.Presale.deposit({ from: depositors[0] }),
          "Presale not yet started."
        );
      });
    });
    //function Presale.sendToUniswap() 
    describe("#sendToUniswap", function () {
      it("Should revert", async function () {
        await expectRevert(
          this.Presale.sendToUniswap({ from: depositors[0] }),
          "Presale not yet started."
        );
      });
    });
  });

  /** 
   * Testing the functionalities after the presale has ended
  */
  describe("State: Presale Ended", function () {
    //execute following before everyone else
    before(async function () {
      //Initialising the presale
      await this.Timer.initialize(
        config.timer.startTime,
        config.timer.hardCapTimer,
        config.timer.softCap,
        this.Presale.address,
        owner
      );
      //setting presale endtime
      await this.Timer.setEndTime(
        (Math.floor(Date.now() / 1000) - 60).toString(),
        { from: owner }
      );
    });
    //function Presale.deposit()
    describe("#deposit", function () {
      it("Should revert", async function () {
        await expectRevert(
          this.Presale.deposit({ from: depositors[0] }),
          "Presale has ended."
        );
      });
    });
  });
});
