// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

contract SecureDynamicNFT is ERC721URIStorage, Ownable {
    uint256 private tokenCounter;
    
    mapping(uint256 => uint256) public balances;
    mapping(uint256 => uint8) public reputation;

    event NFTCreated(uint256 indexed tokenId, string tokenURI);
    event MetadataUpdated(uint256 indexed tokenId, string newTokenURI);

    constructor() ERC721("SecureNFT", "SNFT") {
        tokenCounter = 0;
    }

    function createNFT(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        balances[newTokenId] = 0;
        reputation[newTokenId] = 235; // prima era 100, mettiamo 235 per comodità
        tokenCounter += 1;
        emit NFTCreated(newTokenId, tokenURI);
        return newTokenId;
    }

    function updateMetadata(uint256 tokenId, string memory newTokenURI) public {
        require(_existsInternal(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only the owner can update metadata");
        _setTokenURI(tokenId, newTokenURI);
        emit MetadataUpdated(tokenId, newTokenURI);
    }

    function deposit(uint256 tokenId) public payable {
        require(_existsInternal(tokenId), "Token ID does not exist");
        balances[tokenId] += msg.value;
    }

    /// Reward con controllo su overflow
    function reward(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not your NFT");
        require(reputation[tokenId] <= 245, "Overflow risk: max reputation reached");
        reputation[tokenId] += 10;
    }

    /// Penalize con controllo su underflow
    function penalize(uint256 tokenId) public {
        require(reputation[tokenId] >= 20, "Underflow risk: too low to penalize");
        reputation[tokenId] -= 20;
    }

    function _existsInternal(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) {
            return true;
        } catch {
            return false;
        }
    }
}
