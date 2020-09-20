const { accounts, contract, web3 } = require("@openzeppelin/test-environment")
const { expectRevert, time, BN, ether, balance } = require("@openzeppelin/test-helpers")
const {expect} = require("chai")
const config = require("../config")

const LidSimplifiedPresaleTimer = contract.fromArtifact("LidSimplifiedPresaleTimer")

const owner = accounts[0]
const presale = accounts[1]

const SECONDS_PER_HOUR = 3600

describe("LidSimplifiedPresaleTimer", function() {
  before(async function() {
    const timerParams = config.timer
    this.timer = await LidSimplifiedPresaleTimer.new()
    await this.timer.initialize(
      timerParams.startTime,
      timerParams.hardCapTimer,
      timerParams.softCap,
      presale,
      owner
    )
  })

  describe("#isStarted", function() {
    it("should be false with default param", async function() {
      const result = await this.timer.isStarted()
      expect(result).to.equal(false)
    })
    it("should be false at startTime 0", async function() {
      await this.timer.setStartTime("0", {from: owner})
      const result = await this.timer.isStarted()
      expect(result).to.equal(false)
    })
    it("should be true in the past", async function() {
      await this.timer.setStartTime("1", {from: owner})
      const result = await this.timer.isStarted()
      expect(result).to.equal(true)
    })
  })

  describe("#updateEndTime", function() {
    it("should be now+timer with 0 softcap", async function() {
      const presaleBalance = await balance.current(presale);
      await this.timer.updateEndTime();
      const result = await this.timer.endTime();
      const currentTime = await time.latest();
      if (presaleBalance >= config.timer.softCap) {
        expect(new BN(result).sub(currentTime).toString()).to.equal(
          config.timer.hardCapTimer.toString()
        );
      } else {
        expect(result.toString()).to.equal("0");
      }
    });
  });

})
