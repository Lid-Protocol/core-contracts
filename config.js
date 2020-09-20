const { ether, BN } = require("@openzeppelin/test-helpers");

let config = {};

config.timer = {
  startTime: 1600443840,
  hardCapTimer: 172800,
  softCap: ether("500"),
};

config.redeemer = {
  redeemBP: 400,
  redeemInterval: 3600,
  bonusRangeStart: [
    ether("0"),
    ether("100"),
    ether("200"),
    ether("300"),
    ether("400"),
    ether("500"),
    ether("1000"),
    ether("1500")
  ],
  bonusRangeBP: [
    8000,
    7000,
    6000,
    5000,
    4000,
    500,
    250,
    0
  ],
};

config.presale = {
  maxBuyPerAddress: ether("25"),
  uniswapEthBP: 5000,
  uniswapLidEthBP: 1000,
  lidEthBP: 500,
  referralBP: 250,
  hardcap: ether("2000"),
  token: "0xb48e0f69e6a3064f5498d495f77ad83e0874ab28",
  uniswapRouter: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  lidFund: "0xb63c4F8eCBd1ab926Ed9Cb90c936dffC0eb02cE2",
  access: "0xfD8e59814D601219bddd53879ADa1Ff75fD316e2",
  marketingFund: "0x0e83e69b2F7f63Ec2025cfA7EB0759419C860Be6",
  projectFund: "0x9AfB59A4f75F2Ce512AD00B83F9603c7F4AD0204",
  teamFund: "0x409e1D4026263346AC3c41d34da40De1B6f0Cb6F",
  lidLiqLocker: "0x5d05eEF83499789fD2d3e6b2A7483430B40A0325",
  tokenPoolsBP: {
    marketing: 500,
    team: 1900,
    lidFee: 100,
    project: 3100,
    liquidity: 1167,
    presale: 3000,
    lidLiq: 233
  }
};

config.timelock = {
  releaseInterval: 2592000,
  releaseBP: 1000
}

module.exports = config;
