const Token = artifacts.require('./Token.sol');
const TokenCrowdsale = artifacts.require('./TokenCrowdsale.sol');

const ether = (n) => new web3.BigNumber(web3.utils.toWei(n, 'ether'));

const duration = {
    seconds: function (val) { return val; },
    minutes: function (val) { return val * this.seconds(60); },
    hours: function (val) { return val * this.minutes(60); },
    days: function (val) { return val * this.hours(24); },
    weeks: function (val) { return val * this.days(7); },
    years: function (val) { return val * this.days(365); },
};

module.exports = async function(deployer, network, accounts) {
    const _name = "ICOToken";
    const _symbol = "ICOT";
    const _decimals = 18;
  
    await deployer.deploy(Token, _name, _symbol, _decimals);
    const deployedToken = await Token.deployed();
  
    const latestTime = (new Date).getTime();
  
    const rate           = 500;
    const wallet         = accounts[0]; 
    const token          = deployedToken.address;
    const openingTime    = latestTime + duration.minutes(1);
    const closingTime    = _openingTime + duration.weeks(1);
    const cap            = ether(100);
    const goal           = ether(50);
    const foundersFund   = accounts[1]; 
    const foundationFund = accounts[2]; 
    const partnersFund   = accounts[3]; 
    const releaseTime    = _closingTime + duration.days(1);
  
    await deployer.deploy(
      TokenCrowdsale,
      rate,
      wallet,
      token,
      cap,
      openingTime,
      closingTime,
      goal,
      foundersFund,
      foundationFund,
      partnersFund,
      releaseTime
    );
  
    return true;
};