async function main() {
    const MyContract = await ethers.getContractFactory('MyContract');
    console.log('Deploying MyContract...');
    const contract = await MyContract.deploy(
        "0x58D8ECe142c60f5707594a7C1D90e46eAE5AF431" // TODO: change to your network Witnet
      );
    await contract.waitForDeployment();
    const address = await contract.getAddress()
    console.log('MyContract deployed to:', address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});