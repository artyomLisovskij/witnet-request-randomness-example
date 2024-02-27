function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {
    const MyContract = await ethers.getContractFactory('MyContract');
    const address = '0x97d3311384971341ef88ccC8A246E1DB335bC64F'; // TODO: change to deployed contract address
    const contract = await MyContract.attach(address);
    while (!await contract.checkQueryByInternalId(0)) {
      console.log('Not yet');
      await sleep(5000);
    }
    console.log('Request settled!')
    await contract.getWitnetQueryResult(0);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});