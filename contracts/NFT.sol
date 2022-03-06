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

// import "hardhat/console.sol";

contract NFT is ERC721, ERC721URIStorage, Ownable, AccessControl, StageControl, VIP {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    bytes32 private constant vipRole = "vip";
    bytes32 constant whiteListRole = "white_list";

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupStage(1, 1000, 1, whiteListRole);
        _setupStage(2, 2000, 2, whiteListRole);
        _setupStage(3, 6800, 0, NO_ROLE_LIMIT);
    }

    function createNFTs(string memory uri, uint256 stage, uint256 count) public onlyOwner onlyExistStage(stage) {
        require(_canCreateNFTsInStage(stage, count), "NFT: cannot create NFTs in stage");

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
            _setTokenURI(tokenId, uri);
            _recordNFTStage(tokenId, stage);
        }
        _createNFTsInStage(stage, count);
    }

    function createVIPNFTs(string memory uri, uint256 count) public onlyOwner {
        require(_canCreateVIPNFTs(count), "NFT: cannot create VIP NFTs");

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_msgSender(), tokenId);
            _setTokenURI(tokenId, uri);
            _recordVIPNFTs(tokenId);
        }
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
        if (from == owner()) {  // first transfer, 
            if (_isVIPToken(tokenId)) {
                require(hasRole(vipRole, to), "NFT: cannot transfer token to this user, he/she is not vip.");

                super.transferFrom(from, to, tokenId);
            } else {
                require(hasRole(whiteListRole, to), "NFT: cannot transfer token to this user, he/she is not whitelist user.");
                require(_canTransferNFTToUserInCurrentStage(to, tokenId), "NFT: to user are over purchase limited");

                super.transferFrom(from, to, tokenId);
                _recordPurchaseInCurrentStage(to, tokenId);
            }
        } else  {
            super.transferFrom(from, to, tokenId);
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
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)  public view virtual override(ERC721, AccessControl) returns (bool)  {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}