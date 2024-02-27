async function main() {
  const MyContract = await ethers.getContractFactory('MyContract');
  const address = '0x97d3311384971341ef88ccC8A246E1DB335bC64F'; // TODO: change to deployed contract address
  const contract = await MyContract.attach(address);
  console.log('Asking for randomness');
  await contract.askForRandomness({
    value: ethers.parseEther("0.1"), // possible need to change according to network
    gasLimit: 400000 // possible need to change according to network
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
