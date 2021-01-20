# Release notes
All notable changes to this project will be documented in this file.


uTokens Contract
* use Ownable contract
* mint()

three scenarios for access:
1. admin/owner -> bridge -> Liquid Staking Contract -> mint()
2. staker -> trigger -> sToken contract -> mint()
3. staker -> ustaking action -> Liquid Staking Contract -> mint()

require conditions: 
1. tx.origin == admin && msg.sender == Liquid Staking Contract Address
2. tx.origin == staker address && msg.sender == sToken contract address
3. tx.origin == staker address && msg.sender == Liquid Staking Contract Address

choose to include both the contract address in uTokens or give it as value directly

* burn()
1. staker -> stake function of Liquid Staking Contract -> burn() of uTokens
require condition 
1. tx.origin == staker && msg.sender == liquid staking contract

-----------------------------------------------


sTokens Contract 
1. when calling one contract from another just include the contract shell / signature with the signature of all the functions that are called. Do not impor the whole contract.

2. use _beforeTokenTransfer instead of overriding mint, burn and transfer fns in sToken contract
3. use Ownable instead of custom owner obj and modifiers
4. change the name and symbol
5. _mint(msg.sender, 0); not required in constructor



-----------------------------------------------

Liquid Staking Contract

1. when calling one contract from another just include the contract shell / signature with the signature of all the functions that are called. Do not impor the whole contract. remove both imports

2. remove TokenTimelock.sol
3. use Ownable contract
4. generateUTokens - require msg.sender to be owner
5. remove getUtokenBalance & getStokenBalance
6. stake function - can only be called by staker - require(to == msg.sender)
7. // Verify the staking may not be required
8. STokens.setStakedBlock(to, block.number); might not be required
9. withdrawUnstakedTokens still to be deliberated





