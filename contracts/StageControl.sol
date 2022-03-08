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
    uint256 internal constant NO_COUNT_LIMIT = 0xFFFFFFFF;

    mapping(uint256 => StageData) private _stages;
    mapping(uint256 => uint256) private _nftsMapping;

    uint256 private _curStage;

    modifier onlyExistStage(uint256 stage) {
        require(_hasStage(stage), "StageControl: it's a unknown stage");
                
        _;
    }

    modifier onlyInStage() {
         require(_hasStage(_curStage), "StageControl: The Token is not ready for sell.");
                
        _;
    }

    function _setupStage(
        uint256 stage, 
        uint256 maxCount, 
        uint256 purchaseLimit, 
        bytes32 roleLimit
        ) internal  {
        require(!_hasStage(stage), "StageControl: stage is exist");
        require(stage > 0, "StageControl: stage must > 0");
        require(maxCount > 0, "StageControl: maxCount must >0 ");
        require(purchaseLimit > 0, "StageControl: purchaseLimit must >0");

        _stages[stage].maxCount = maxCount;
        _stages[stage].curCount = 0;
        _stages[stage].purchaseLimit = purchaseLimit;
        _stages[stage].roleLimit = roleLimit;
    }

    function _canMintNFTsInStage(
        address user,
        uint256 count
        ) internal view returns(bool) {
        
        require(_countCanMintInStage(user, _curStage) >= count, "StageControl: Caller has enough token, cannot mint more.");
        require(_stages[_curStage].curCount + count <= _stages[_curStage].maxCount, "StageControl: Token in this stage has no enough count left.");
        
        return true;
    }

    function _setCurrentStage(uint256 curStage) internal onlyExistStage(curStage){
        _curStage = curStage;
    }

    function _getCurrentStage() internal view returns(uint256) {
        return _curStage;
    }

    function _recordNFTStage(address user, uint256 tokenId) internal onlyInStage {

        _nftsMapping[tokenId] = _curStage;
        _stages[_curStage].curCount += 1;
        _stages[_curStage].purchaseRecord[user] += 1;
    }

    function _canTransferNFTToUserInStage(address to, uint256 tokenId) internal view onlyInStage returns(bool) {
        return _canTransferNFTToUserInStage(to, tokenId, _curStage);
    }

    function _recordTransferInStage(address from, address to, uint256 tokenId) internal onlyInStage {
        uint256 stage = _getStageFromNFT(tokenId);
        require(_hasStage(stage), "StageControl: token is not in a exist stage");
        require(_canTransferNFTToUserInStage(to, tokenId));

        // console.log("begin transfer in stage", stage, _stages[stage].purchaseRecord[from], _stages[stage].purchaseRecord[to]);
        _stages[stage].purchaseRecord[to] += 1;
        _stages[stage].purchaseRecord[from] -= 1;
        // console.log("begin transfer in stage", stage, _stages[stage].purchaseRecord[from], _stages[stage].purchaseRecord[to]);
    }

    // private functions

    function _hasStage(uint256 stage) private view returns(bool) {
        return _stages[stage].maxCount > 0;
    }

    function _canOwnTokenInStage(address user,  uint256 stage, uint256 count) private view returns(bool) {
        require(_hasStage(stage), "StageControl: stage not exist");

        uint256 purchaseLimit = _stages[stage].purchaseLimit;
        if (purchaseLimit <= 0) { // no limit.
            return true;
        }
        uint256 purchase = _stages[stage].purchaseRecord[user];
        return purchase + count <= purchaseLimit;
    }

    function _getStageFromNFT(uint256 tokenId) private view returns(uint256) {
        return _nftsMapping[tokenId];
    }

    function _canTransferNFTToUserInStage(address to, uint256 tokenId, uint256 stage) private view onlyExistStage(stage) returns(bool) {
        uint256 mStage = _getStageFromNFT(tokenId);
        require(_hasStage(mStage), "StageControl: stage not exist");
        require(mStage == stage, "StageControl: this token cannot be transfered in current stage");

        return _canOwnTokenInStage(to, stage, 1);
    }

    function _tokenCountInStage(address user, uint256 stage) private view onlyExistStage(stage) returns(uint256) {
        return _stages[stage].purchaseRecord[user];
    }

    function _countCanMintInStage(address user, uint256 stage) private view onlyExistStage(stage) returns(uint256) {
        uint256 purchaseLimit = _stages[stage].purchaseLimit;
        if (purchaseLimit == NO_COUNT_LIMIT) {
            return NO_COUNT_LIMIT;
        }
        // console.log("record: ",user ,_stages[stage].purchaseRecord[user]);
        return purchaseLimit - _stages[stage].purchaseRecord[user];
    }

}
