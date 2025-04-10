// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import dei contratti di OpenZeppelin
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/security/ReentrancyGuard.sol";

/// @title DynamicNFT (Mitigazione con Checks-Effects-Interactions e ReentrancyGuard)
/// @notice Smart Contract con protezione contro l'attacco di rientranza usando `nonReentrant`
contract DynamicNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    
    uint256 private tokenCounter;
    mapping(uint256 => uint256) public balances; // Saldo associato a ciascun NFT

    event NFTCreated(uint256 indexed tokenId, string tokenURI);
    event MetadataUpdated(uint256 indexed tokenId, string newTokenURI);
    event Withdrawal(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    constructor() ERC721("DynamicNFT", "DNFT") {
        tokenCounter = 0;
    }

    /// @notice Creazione di un nuovo NFT
    function createNFT(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        emit NFTCreated(newTokenId, tokenURI);
        tokenCounter += 1;
        return newTokenId;
    }

    /// @notice Aggiorna i metadati di un NFT esistente
    function updateMetadata(uint256 tokenId, string memory newTokenURI) public {
        require(_existsInternal(tokenId), "Token ID does not exist");

        _setTokenURI(tokenId, newTokenURI);
        emit MetadataUpdated(tokenId, newTokenURI);
    }

    /// @notice Deposito di Ether associato a un NFT
    function deposit(uint256 tokenId) public payable {
        require(_existsInternal(tokenId), "Token ID does not exist");
        balances[tokenId] += msg.value;
    }

    /// @notice Funzione SICURA per prelevare Ether usando Checks-Effects-Interactions + ReentrancyGuard
    function withdraw(uint256 tokenId, uint256 _amount) public nonReentrant {
        // CHECKS: Controlli iniziali
        require(_existsInternal(tokenId), "Token ID does not exist");
        require(balances[tokenId] >= _amount, "Insufficient balance");

        // EFFECTS: Aggiorniamo il saldo PRIMA di inviare fondi
        balances[tokenId] -= _amount;

        // INTERACTIONS: Ora inviamo Ether al richiedente (msg.sender)
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Transfer failed");

        emit Withdrawal(tokenId, msg.sender, _amount);
    }

    /// @notice Funzione che verifica se un token esiste
    function _existsInternal(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) {
            return true;
        } catch {
            return false;
        }
    }
}
