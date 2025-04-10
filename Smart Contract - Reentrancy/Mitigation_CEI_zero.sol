// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import dei contratti OpenZeppelin
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

/// @title DynamicNFT - Sicuro contro attacco di rientranza con reset saldo
/// @notice Usa il pattern Checks-Effects-Interactions e azzera il saldo PRIMA della call
contract DynamicNFT is ERC721URIStorage, Ownable {

    uint256 private tokenCounter;
    mapping(uint256 => uint256) public balances;

    event NFTCreated(uint256 indexed tokenId, string tokenURI);
    event MetadataUpdated(uint256 indexed tokenId, string newTokenURI);
    event Withdrawal(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    constructor() ERC721("DynamicNFT", "DNFT") {
        tokenCounter = 0;
    }

    /// @notice Crea un nuovo NFT
    function createNFT(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        emit NFTCreated(newTokenId, tokenURI);
        tokenCounter++;
        return newTokenId;
    }

    /// @notice Aggiorna i metadati del token
    function updateMetadata(uint256 tokenId, string memory newTokenURI) public {
        require(_existsInternal(tokenId), "Token does not exist");
        _setTokenURI(tokenId, newTokenURI);
        emit MetadataUpdated(tokenId, newTokenURI);
    }

    /// @notice Permette di depositare Ether associato al tokenId
    function deposit(uint256 tokenId) public payable {
        require(_existsInternal(tokenId), "Token does not exist");
        balances[tokenId] += msg.value;
    }

    /// @notice Funzione SICURA per prelevare Ether usando Checks-Effects-Interactions
    function withdraw(uint256 tokenId) public {
        require(_existsInternal(tokenId), "Token does not exist");

        // CHECKS: Controlli iniziali per verificare se il prelievo è valido
        uint256 amount = balances[tokenId];
        require(amount > 0, "No funds to withdraw");

        // EFFECTS: Stato aggiornato prima della call esterna
        balances[tokenId] = 0;

        // INTERACTIONS: Solo dopo aver aggiornato lo stato
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed");

        emit Withdrawal(tokenId, msg.sender, amount);
    }

    /// @dev Verifica l'esistenza di un token
    function _existsInternal(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) {
            return true;
        } catch {
            return false;
        }
    }
}
