const { scripts, ConfigManager } = require("@openzeppelin/cli")
const { add, push, create } = scripts
const {publicKey} = require("../privatekey")

const config = require("../config")

const LidSimplifiedPresaleTimer = artifacts.require("LidSimplifiedPresaleTimer")
const LidSimplifiedPresale = artifacts.require("LidSimplifiedPresale")

async function initialize(accounts,networkName) {
  let owner = accounts[0]

  const timerParams = config.timer

  const timer =   await LidSimplifiedPresaleTimer.deployed()
  const presale = await LidSimplifiedPresale.deployed()

  await timer.initialize(
      timerParams.startTime,
      timerParams.hardCapTimer,
      timerParams.softCap,
      presale.address,
      owner
    )
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    await initialize(accounts,networkName)
  })
}
