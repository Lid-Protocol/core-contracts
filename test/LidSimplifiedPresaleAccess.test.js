//Importing test environment and bring up local blockchain to run tests 
const { accounts, contract } = require("@openzeppelin/test-environment");
//Importing oz test helpers
const { BN } = require("@openzeppelin/test-helpers");
//Importing chai interface
const { expect } = require("chai");
//Importing config.js file 
const config = require("../config");

//Importing all smart contracts
const LidSimplifiedPresaleAccess = contract.fromArtifact("LidSimplifiedPresaleAccess");
const LidStaking = contract.fromArtifact("LidStaking");
const LidTimer = contract.fromArtifact("LidSimplifiedPresaleTimer");

//defining account holder names. The accounts[] array is provided by oz
const owner = accounts[0];
const presale = accounts[1];

  //// STARTING TESTS ////

/** 
 * Testing the functionalities of LidSimplifiedPresaleAccess
*/
describe("LidSimplifiedPresaleAccess", function () {
  //execute following before everyone else
  before(async function () {
    //creating contract objects
    this.PresaleAccess = await LidSimplifiedPresaleAccess.new();
    this.Timer = await LidTimer.new();
    this.Staking = await LidStaking.new();
    //initializing the PresaleAccess sc
    await this.PresaleAccess.initialize(this.Staking.address);
    //Initializing the Timer sc
    await this.Timer.initialize(
      config.timer.startTime,
      config.timer.hardCapTimer,
      config.timer.softCap,
      presale,
      owner
    );
  });

  //Function PresaleAccess.getAccessTime()
  describe("#getAccessTime", function () {
    it("should get access time", async function () {
      const result = await this.PresaleAccess.getAccessTime(
        accounts[2],
        config.timer.startTime
      );
      expect(result).to.be.bignumber
        .equal(new BN(config.presaleAccess.accessTime));
    });
  });
});
