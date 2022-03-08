// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract VIP {
    using Counters for Counters.Counter;

    Counters.Counter private _vipTokenCounter;

    uint256 private constant MAX_VIP_TOKEN_COUNT = 200;
    mapping(address => bool) private _vips;
    mapping(uint256 => bool) private _vipNFTs;

    function _recordVIPNFTs(uint256 tokenId) internal {
        require(_canMintVIPNFTs(1), "NFT: The vip NFTs has been mint out.");

        _vipNFTs[tokenId] = true;
        _vipTokenCounter.increment();
    }

    function _isVIPToken(uint256 tokenId) internal view returns(bool) {
        return _vipNFTs[tokenId];
    } 

    function _canMintVIPNFTs(uint256 count) internal view returns(bool) {
        return _vipTokenCounter.current() + count < MAX_VIP_TOKEN_COUNT;
    }
}
