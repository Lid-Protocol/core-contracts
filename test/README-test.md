# LID Protocol: The Liquidity Dividends Protocol uses new technology that provides solutions for depositing Liquidity into Uniswap.

### Testing: This document highlights steps to start the dev-environment and run the tests inside core-contracts/tests direcory. Follow the 3 steps below to run the tests:

## Fork and clone the core-contracts repo in your local machine:
- Click on the fork button on the top-right of the repo
- Once forked in your account your_username/core-contracts, click on clone and copy the URL
- Open a terminal and run command ```git clone URL```
- You should see the downloaded folder core-contracts.

## Install dependencies required for running the tests
- Check your node and npm version by ```node -v``` and ```npm -v```. Make sure to have node version 12.18.3 and npm version 6.14.6
- You can use ```nvm ls``` to see all installed node versions and ```nvm use [version]``` to select the right version
- Go inside the core-contracts ```CD core-contracts``` from the terminal and run ```npm install```. This will install all dependencies in package.json file 
- Install openzeppelin CLI ```npm install @openzeppelin/cli```
- You can now compile the smart contracts using ```oz compile``` 
- Run the tests by using ```npm run test```

## Play around

- ```npm run test``` will run all the tests inside the core-contracts/tests directory.
- You can see which tests passed and failed and tweak your test files 
- Run ```oz compile``` and ```npm run test``` to check the tests on the edited files again

# Do not change the SC inside the core-contracts/contracts directory to pass the tests.  If you feel the tests are right and there is an issue in the SCs then please contact the developer.

### LID Socials

[<img align="left" alt="MxMaster2s | Instagram" width="22px" src="https://cdn.iconscout.com/icon/free/png-256/telegram-1754812-1490132.png" />][telegram]
[<img align="left" alt="MxMaster2s | LinkedIn" width="22px" src="https://cdn.iconscout.com/icon/free/png-256/twitter-213-569318.png" />][twitter]
[<img align="left" alt="MxMaster2s | Discord" width="22px" src="https://image.flaticon.com/icons/svg/2111/2111370.svg" />][discord]

[telegram]: https://t.me/LIDProtocol
[twitter]: https://twitter.com/LID_Protocol?s=20
[discord]: https://discord.gg/Gs5HWn5
