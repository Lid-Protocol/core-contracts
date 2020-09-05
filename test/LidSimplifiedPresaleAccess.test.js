const { accounts, contract } = require("@openzeppelin/test-environment");
const { BN } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const config = require("../config");

const LidSimplifiedPresaleAccess = contract.fromArtifact(
  "LidSimplifiedPresaleAccess"
);
const LidStaking = contract.fromArtifact("LidStaking");
const LidTimer = contract.fromArtifact("LidSimplifiedPresaleTimer");

const owner = accounts[0];
const presale = accounts[1];

describe("LidSimplifiedPresaleAccess", function () {
  before(async function () {
    this.PresaleAccess = await LidSimplifiedPresaleAccess.new();
    this.Timer = await LidTimer.new();
    this.Staking = await LidStaking.new();
    await this.PresaleAccess.initialize(this.Staking.address);
    await this.Timer.initialize(
      config.timer.startTime,
      config.timer.hardCapTimer,
      config.timer.softCap,
      presale,
      owner
    );
  });

  describe("#getAccessTime", function () {
    it("should get access time", async function () {
      const result = await this.PresaleAccess.getAccessTime(
        accounts[2],
        config.timer.startTime
      );

      expect(result).to.be.bignumber.equal(
        new BN(config.presaleAccess.accessTime)
      );
    });
  });
});
