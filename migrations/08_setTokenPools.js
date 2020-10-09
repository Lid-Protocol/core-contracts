const { scripts, ConfigManager } = require("@openzeppelin/cli")
const { add, push, create } = scripts
const {publicKey} = require("../privatekey")

const config = require("../config")

const LidSimplifiedPresale = artifacts.require("LidSimplifiedPresale")

async function setTokenPools(accounts,networkName) {
  let owner = accounts[0]

  const timelockParams = config.timelock

  const presale = await LidSimplifiedPresale.deployed()

  const poolsBP = config.presale.tokenPoolsBP

  await presale.setTokenPools(
    poolsBP.liquidity,
    poolsBP.presale,
    [
      config.presale.teamFund,
      config.presale.projectFund,
      config.presale.lidFund,
      config.presale.marketingFund,
      config.presale.lidLiqLocker
    ],
    [
      poolsBP.team,
      poolsBP.project,
      poolsBP.lidFee,
      poolsBP.marketing,
      poolsBP.lidLiq
    ]
  )
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    await setTokenPools(accounts,networkName)
  })
}
