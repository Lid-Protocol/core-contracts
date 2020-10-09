const { scripts, ConfigManager } = require("@openzeppelin/cli")
const { add, push, create } = scripts
const {publicKey} = require("../privatekey")

const config = require("../config")

const LidSimplifiedPresaleTimer = artifacts.require("LidSimplifiedPresaleTimer")
const LidSimplifiedPresaleRedeemer = artifacts.require("LidSimplifiedPresaleRedeemer")
const LidSimplifiedPresale = artifacts.require("LidSimplifiedPresale")

async function initialize(accounts,networkName) {
  let owner = accounts[0]

  const presaleParams = config.presale

  const timer =    await LidSimplifiedPresaleTimer.deployed()
  const redeemer = await LidSimplifiedPresaleRedeemer.deployed()
  const presale =  await LidSimplifiedPresale.deployed()

  await presale.initialize(
      presaleParams.maxBuyPerAddress,
      presaleParams.uniswapEthBP,
      presaleParams.lidEthBP,
      presaleParams.referralBP,
      presaleParams.hardcap,
      owner,
      timer.address,
      redeemer.address,
      presaleParams.access,
      presaleParams.token,
      presaleParams.uniswapRouter,
      presaleParams.lidFund,
    )
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    await initialize(accounts,networkName)
  })
}
