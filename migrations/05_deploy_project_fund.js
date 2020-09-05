const { scripts, ConfigManager } = require('@openzeppelin/cli');
const { add, push, create } = scripts;
const {publicKey} = require("../privatekey")

async function deploy(options) {
  add({ contractsData: [
    { name: 'LidTimeLock', alias: 'LidTimeLockDev' },
    { name: 'LidTimeLock', alias: 'LidTimeLockStaking' },
    { name: 'LidTimeLock', alias: 'LidTimeLockMarketing' }
  ] });
  options.force = true;
  await push(options);
  await create(Object.assign({ contractAlias: 'LidTimeLockDev' }, options));
  await create(Object.assign({ contractAlias: 'LidTimeLockStaking' }, options));
  await create(Object.assign({ contractAlias: 'LidTimeLockMarketing' }, options));
}

module.exports = function(deployer, networkName, accounts) {
  deployer.then(async () => {
    let account = accounts[0]
    const { network, txParams } = await ConfigManager.initNetworkConfiguration({ network: networkName, from: account })
    await deploy({ network, txParams })
  })
}
