This is witnet example of RNG using WitnetRequestBoard.

1. copy `.env.example` to `.env` and provide private key and rpc url
2. change contract address from `scripts/deploy_mycontract.js` according to https://github.com/witnet/witnet-solidity-bridge/blob/master/migrations/witnet.addresses.json WitnetRequestBoard section
3. `npx hardhat run scripts/deploy_mycontract.js`
4. get address of deployed contract from console and change at `scripts/ask_randomness.js` and `scripts/test_request.js`
5. ask randomness from witnet `npx hardhat run scripts/ask_randomness.js`
6. run `npx hardhat run scripts/test_request.js` and wait for result

FYI: My first request on Ultron testnet has been settled in 38 minutes. I've asked in Witnet Community for information and get response `there was a delay in the Ultron<>Witnet bridge — most usually the wait is way less than that`. Second request has ben settled in ~3 minutes.
