// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

/// @title DynamicNFT - Versione sicura (mitigazione phishing via msg.sender)
contract DynamicNFT is ERC721URIStorage, Ownable {
    
    uint256 private tokenCounter;
    address public ownerPhishable;
    mapping(uint256 => uint256) public balances;

    event NFTCreated(uint256 indexed tokenId, string tokenURI);
    event MetadataUpdated(uint256 indexed tokenId, string newTokenURI);

    constructor() ERC721("DynamicNFT", "DNFT") {
        tokenCounter = 0;
        ownerPhishable = msg.sender;
    }

    function createNFT(address recipient, string memory tokenURI) public onlyOwner returns (uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        emit NFTCreated(newTokenId, tokenURI);
        tokenCounter += 1;
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

    /// MITIGAZIONE: usa msg.sender invece di tx.origin
    function withdrawAll(address payable _to) public {
        require(msg.sender == ownerPhishable, "Not authorized"); // Sicuro
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function _existsInternal(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) {
            return true;
        } catch {
            return false;
        }
    }

    receive() external payable {}
}
