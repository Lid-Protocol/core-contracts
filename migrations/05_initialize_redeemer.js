const { scripts, ConfigManager } = require("@openzeppelin/cli")
const { add, push, create } = scripts
const {publicKey} = require("../privatekey")

const config = require("../config")

const LidSimplifiedPresaleRedeemer = artifacts.require("LidSimplifiedPresaleRedeemer")
const LidSimplifiedPresale = artifacts.require("LidSimplifiedPresale")

async function initialize(accounts,networkName) {
  let owner = accounts[0]

  const redeemerParams = config.redeemer

  const redeemer =   await LidSimplifiedPresaleRedeemer.deployed()
  const presale = await LidSimplifiedPresale.deployed()

  await redeemer.initialize(
      redeemerParams.redeemBP,
      redeemerParams.redeemInterval,
      redeemerParams.bonusRangeStart,
      redeemerParams.bonusRangeBP,
      presale.address,
      owner
    )
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    await initialize(accounts,networkName)
  })
}
