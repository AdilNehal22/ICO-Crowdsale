//converting Ether to wei:
async function ether(n) {
    return new web3.BigNumber(await web3.utils.toWei(n, 'ether'));
}

module.exports = ether; 