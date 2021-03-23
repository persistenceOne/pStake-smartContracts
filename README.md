# pStakeSmartContracts
Ethereum Smart Contracts pertaining to the pSTAKE DeFi App. pStake is a liquid staking solution which helps in unlocking the liquidity of the staked assets. pStake solution is built up using ERC20 contracts over Ethereum Blockchain. pStake is thoroughly focused on security and this document describes the different aspects of the smart contracts and mechanisms which will help in auditing the smart contracts. Following is the description of prominent contracts: 

## UTokens Contract
This contract is used for minting and burning ustkTokens which are pegged with the protocol token of a blockchain for which the liquid staking mechanism is enabled. The tokens are not staked yet, they act as a representation of assets on other Blockchain with Ethereum. These ustkTokens can be used for liquid staking or creating yield using other DeFi means. 

## STokens Contract
This contract is used for minting and burning stkTokens for which the liquid stacking mechanism is enabled. The tokens are considered staked and the corresponding asset on other Blockchain is staked as per the amount of tokens in this contract for a specific address. The owner of the tokens continuously accrues returns on the stkTokens kept. 

## Liquid Staking Contract
This contract is used for staking, unstaking and withdrawal of unbonded tokens. On staking request, the ustkTokens are converted to stkTokens which start accruing returns. Also unstaking operation initiates a withdrawal delay of certain days, after which the ustkTokens can be redeemed back using withdraw unbonding tokens action. 

## TokenWrapper Contract
This contract is used for deposit and withdraw operations of ustkTokens. This enables transfer of value between two blockchains when the protocol token is converted to its pegged representative or vice versa. 


