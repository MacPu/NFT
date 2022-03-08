// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./StageControl.sol";
import "./VIP.sol";
import "./Base64.sol";

import "hardhat/console.sol";  // for test

contract NFT is ERC721, ERC721URIStorage, Ownable, AccessControl, StageControl, VIP {
    using Counters for Counters.Counter;

    struct Attr {
        string name;
        string image;
        string attr0;
        uint8 attr1;
        uint8 attr2;
        uint8 attr3;
    }

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Attr) public attributes;
    
    bytes32 private constant vipRole = "vip";
    bytes32 constant whiteListRole = "whitelist";

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(vipRole, _msgSender());
        _grantRole(whiteListRole, _msgSender());
        _setupStage(1, 1000, 1, whiteListRole);
        _setupStage(2, 2000, 2, whiteListRole);
        _setupStage(3, 6800, NO_COUNT_LIMIT, NO_ROLE_LIMIT);
    }

    function mintNFTs(
        string memory name,
        string memory imageUrl,
        string memory attr0,
        uint8 attr1,
        uint8 attr2,
        uint8 attr3,
        uint256 count
        ) public onlyRole(whiteListRole) {
        require(count > 0, "NFT: If you want mint NFTs, the count must >0.");
        require(_canMintNFTsInStage(_msgSender(), count), "NFT: Cannot mint NFTs in this stage.");

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _mintNFT(name, imageUrl, attr0, attr1, attr2, attr3);
            _recordNFTStage(_msgSender(), tokenId);
        }
    }

    function mintVIPNFTs(
        string memory name,
        string memory imageUrl,
        string memory attr0,
        uint8 attr1,
        uint8 attr2,
        uint8 attr3,
        uint256 count
        ) public onlyRole(vipRole) {

        require(count > 0, "NFT: If you want mint NFTs, the count must >0.");
        require(_canMintVIPNFTs(count), "NFT: The vip NFTs has been mint out.");

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _mintNFT(name, imageUrl, attr0, attr1, attr2, attr3);
            _recordVIPNFTs(tokenId);
        }
    }

    function _mintNFT(
        string memory name,
        string memory image,
        string memory attr0,
        uint8 attr1,
        uint8 attr2,
        uint8 attr3
        ) private returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
        
        attributes[tokenId] = Attr(name, image, attr0, attr1, attr2, attr3);
        return tokenId;
    }

    function addVIP(address vipAddress) public onlyOwner {
        grantRole(vipRole, vipAddress);
    }

    function addWhiteList(address whiteListAddress) public onlyOwner {
        grantRole(whiteListRole, whiteListAddress);
    }

    function setCurrentStage(uint256 stage) public onlyOwner onlyExistStage(stage) {
        _setCurrentStage(stage);
    }

    // The following functions are overrides required by Solidity.

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {

        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        if (_isVIPToken(tokenId)) {
            require(hasRole(vipRole, to), "NFT: cannot transfer token to this user, reciver is not vip.");

            super.transferFrom(from, to, tokenId);
        } else {
            require(hasRole(whiteListRole, to), "NFT: cannot transfer token to this user, reciver is not whitelist user.");
            require(_canTransferNFTToUserInStage(to, tokenId), "NFT:revicer are over purchase limited.");

            super.transferFrom(from, to, tokenId);
            _recordTransferInStage(from, to, tokenId);
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', attributes[tokenId].name, '",',
                    '"image": "', attributes[tokenId].image, '",',
                    '"attributes": [{"trait": "Attribute1", "value": ', Strings.toString(attributes[tokenId].attr1), '},',
                    '{"trait": "Attribute2", "value": ', Strings.toString(attributes[tokenId].attr2), '},',
                    '{"trait": "Attribute3", "value": ', Strings.toString(attributes[tokenId].attr3), '},',
                    '{"trait": "Attribute0", "value": "', attributes[tokenId].attr0, '"}',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function supportsInterface(bytes4 interfaceId)  public view virtual override(ERC721, AccessControl) returns (bool)  {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}