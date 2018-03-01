var SafeMath = artifacts.require('zeppelin-solidity/contracts/math/SafeMath.sol');
var Lethery = artifacts.require("../contacts/Lethery.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.deploy(
    Lethery, 
    '0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE',
    web3.toWei(.05, 'ether'), 
    web3.toWei(.005, 'ether')
    );
};
