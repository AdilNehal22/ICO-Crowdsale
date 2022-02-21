// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol";



contract TokenCrowdsale is 
            Crowdsale, 
            MintedCrowdsale, 
            CappedCrowdsale, 
            TimedCrowdsale,
            WhitelistedCrowdsale,
            RefundableCrowdsale {

    // rate - the rate at which tokens are purchased in the crowdsale. If the rate is 1, then 1 wei buys 1 token. If the rate is 500, then 500 wei buys 1 token.
    // wallet - this is the account where Ether funds are sent in the ICO.
    // token - this is the address of the ERC-20 token being sold in the crowdsale.

    // Now let's implement a "cap" or limit on our crowdsale. We'll create 2 limits. First, we'll create a hard cap for the maximum amount of Ether raised in the crowdsale. This will be the cap variable. Next, we'll create a "minum cap" which will represent the minimum Ether contribution we will accept from each investor. 

    // Tracking investor contributions
    uint256 public investorMinCap = 2000000000000000; // 0.002 ether
    uint256 public investorHardCap = 50000000000000000000; // 50 ether
    mapping(address => uint256) public contributions;

    // add a feature to create an ICO presale. This will allow us to add phases to our crowdsale. When the ICO is in "presale" mode, all funds will go directly to the wallet instead of the refund vault.

    // Crowdsale Stages
    enum CrowdsaleStage {PreICO, ICO}
    // Default to presale stage
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;

    // Now we can add a timer to our crowdsale. We'll add an opening time and a closing time. We will only allow investors to purchase tokens within this time window.

    // we'll create a white list that restricts the accounts that can contribute to the crowdsale. We'll also add the ability to add investors to the whielist so that they can contribute.

    // add refund support to the crowdsale smart contract. With this feature, we'll create a fund raising goal. If the goal is met, the wallet will get to keep the funds, and investors will have tokens. If the goal is not met, investors will be able to claim refunds. During the crowdsale, all funds will be locked into a refund vault. 

    // add a feature to distribute tokens whenever the crowdsale is finalized. This will determine the economics of our token.
    uint256 public tokenSalePercentage = 70;
    uint256 public foundersPercentage = 10;
    uint256 public foundationPercentage = 10;
    uint256 public partnerPercentage = 10;

    //we will mint tokens for founders, foundation, and partners
    address public foundersFund; 
    address public foundationFund;
    address public partnersFund;

    uint256 public releaseTime;
    address public foundersTimelock;
    address public foundationTimelock;
    address public partnersTimelock;

    constructor(
            uint256 rate, 
            address wallet, 
            ERC20 token, 
            uint256 cap,
            uint256 openingTime,
            uint256 closingTime,
            uint256 goal,
            address _foundersFund,
            address _foundationFund,
            address _partnersFund,
            uint256 _releaseTime) 
        Crowdsale(rate, wallet, token)
        CappedCrowdsale(cap) 
        TimedCrowdsale(openingTime, closingTime)
        RefundableCrowdsale(goal) public {
          require(goal <= cap);
          foundersFund   = _foundersFund;
          foundationFund = _foundationFund;
          partnersFund   = _partnersFund;
          releaseTime    = _releaseTime;

    }

    /**
  * @dev Returns the amount contributed so far by a sepecific user.
  * @param _beneficiary Address of contributor
  * @return User contribution so far
  */

    function getUserContribution(address _beneficiary) public view returns(uint256){
        return contributions[_beneficiary];
    }

    /**
      @dev Allows admin to update the crowdsale stage
      @param _stage Crowdsale stage
     */

    function setCrowdsaleStage(uint _stage) public onlyOwner {
      if(uint(CrowdsaleStage.PreICO) == _stage){
        stage = CrowdsaleStage.PreICO;
      }
      else if(uint(CrowdsaleStage.ICO) == _stage){
        stage = CrowdsaleStage.ICO;
      }

      if(stage == CrowdsaleStage.PreICO) {
        rate = 500;
      } 
      else if (stage == CrowdsaleStage.ICO) {
        rate = 250;
      }
    }

    /**
   * @dev forwards funds to the wallet during the PreICO stage, then the refund vault during ICO stage
   */

    function forwardFunds() internal {
      if(stage == CrowdsaleStage.PreICO){
        wallet.transfer(msg.value);
      }else if(stage == CrowdsaleStage.ICO){
        super._forwardFunds();
      }
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
  * @param _beneficiary Token purchaser
  * @param _weiAmount Amount of wei contributed
  */

    function preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        uint256 existingContribution = contributions[_beneficiary];
        uint256 newContribution = existingContribution.add(_weiAmount);
        require(newContribution >= investorMinCap && newContribution <= investorHardCap);
        contributions[_beneficiary] = newContribution;
    }

    // feature to finalize the crowdsale. We'll create a new function that allows us to do this. First, we'll finish minting tokens so that no more tokens can be minted after the crowdsale is over. Next, we'll unpause the token. We'll only do these things if the crowdsale goal is reached.

    function finalization() internal {
      if(goalReached()){
        MintableToken mintableToken = MintableToken(token);
        uint256 alreadyMinted = mintableToken.totalSupply();

        uint256 finalTotalSupply = alreadyMinted.div(tokenSalePercentage).mul(100);

        //timelock so these entities won't rug pull
        foundersTimelock = new TokenTimelock(token, foundersFund, releaseTime);
        foundationTimelock = new TokenTimelock(token, foundationFund, releaseTime);
        partnersTimelock = new TokenTimelock(token, partnersTimelock, releaseTime);

        mintableToken.mint(address(foundersTimelock), finalTotalSupply.mul(foundersPercentage).div(100));

        mintableToken.mint(address(foundationTimelock), finalTotalSupply.mul(foundationPercentage).div(100));

        mintableToken.mint(address(partnersTimelock), finalTotalSupply.mul(partnerPercentage).div(100));

        mintableToken.finishMinting();
        PausableToken pausableToken = PausableToken(token);
        pausableToken.unpause();
        pausableToken.transferOwnership(wallet);
      }
      super.finalization();
    }

}