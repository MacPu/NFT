// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

abstract contract StageControl {
    struct StageData {
        uint256 maxCount;
        uint256 curCount;
        uint256 purchaseLimit;  // <=0  is no limited
        bytes32 roleLimit;
        mapping(address => uint256) purchaseRecord;
    }

    bytes32 internal constant NO_ROLE_LIMIT = 0x00;

    mapping(uint256 => StageData) private _stages;
    mapping(uint256 => uint256) private _nftsMapping;

    uint256 private _curStage;

    modifier onlyExistStage(uint256 stage) {
        require(_hasStage(stage), "StageControl: you cannot mint in current stage");
                
        _;
    }

    function _setupStage(
        uint256 stage, 
        uint256 maxCount, 
        uint256 purchaseLimit, 
        bytes32 roleLimit
        ) internal  {
        require(!_hasStage(stage), "StageControl: stage is exist");
        require(maxCount > 0, "StageControl: maxCount must >0 ");

        _stages[stage].maxCount = maxCount;
        _stages[stage].curCount = 0;
        _stages[stage].purchaseLimit = purchaseLimit;
        _stages[stage].roleLimit = roleLimit;
    }

    function _canMintNFTsInStage(
        address to,
        uint256 stage, 
        uint256 count
        ) internal view  onlyExistStage(stage) returns(bool) {
        
        require(_canOwnTokenInStage(to, stage, count), "StageControl: The user has enough token, cannot mint more.");
        
        return _stages[stage].curCount + count <= _stages[stage].maxCount;
    }

    function _afterMintNFTsInStage(uint256 stage, uint256 count) internal onlyExistStage(stage) {

        _stages[stage].curCount += count;
    }

    function _setCurrentStage(uint256 curStage) internal onlyExistStage(curStage){
        _curStage = curStage;
    }

    function _getCurrentStage() internal view returns(uint256) {
        return _curStage;
    }

    function _recordNFTStage(uint256 tokenId, uint256 stage) internal onlyExistStage(stage) {
        _nftsMapping[tokenId] = stage;
    }

    function _canTransferNFTToUserInCurrentStage(address to, uint256 tokenId) internal view returns(bool) {
        return _canTransferNFTToUserInStage(to, tokenId, _curStage);
    }

    function _recordPurchaseInCurrentStage(address to, uint256 tokenId) internal {
        require(_canTransferNFTToUserInCurrentStage(to, tokenId));

        _stages[_curStage].purchaseRecord[to] += 1;
    }

    // private functions

    function _hasStage(uint256 stage) private view returns(bool) {
        return _stages[stage].maxCount > 0;
    }

    function _canOwnTokenInStage(address to,  uint256 stage, uint256 count) private view returns(bool) {
        require(_hasStage(stage), "StageControl: stage not exist");

        uint256 purchaseLimit = _stages[stage].purchaseLimit;
        if (purchaseLimit <= 0) { // no limit.
            return true;
        }
        uint256 purchase = _stages[stage].purchaseRecord[to];
        return purchase + count <= purchaseLimit;
    }

    function _getStageFromNFT(uint256 tokenId) internal view returns(uint256) {
        return _nftsMapping[tokenId];
    }

    function _canTransferNFTToUserInStage(address to, uint256 tokenId, uint256 stage) internal view onlyExistStage(stage) returns(bool) {
        uint256 mStage = _getStageFromNFT(tokenId);
        require(_hasStage(mStage), "StageControl: stage not exist");
        require(mStage == stage, "StageControl: this token cannot be transfered in current stage");

        return _canOwnTokenInStage(to, stage, 1);
    }

}
