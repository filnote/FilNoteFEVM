// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Types } from "./utils/Types.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IFilNoteContract {
    function getNote(uint64 id) external view returns (Types.Note memory);
    function completeNote(uint64 id) external returns (uint64);
    function defaultNote(uint64 id) external returns (uint64);
}

contract ProtocolsContract is ReentrancyGuard {
    uint64 immutable ID; 
    address immutable CREATOR;
    address immutable INVESTOR;
    address immutable FIL_NOTE_CONTRACT;

    uint256 private _fundingAmount;
    uint256 private _poolAmount;
    bool private _stopped;

    
    constructor(uint64 noteId, address noteCreator,address noteInvestor) payable {
        ID = noteId;
        CREATOR = noteCreator;
        INVESTOR = noteInvestor;
        _fundingAmount = msg.value;
        FIL_NOTE_CONTRACT = msg.sender;
        emit ProtocolCreated(noteId, noteCreator, noteInvestor);
    }

    event Received(address indexed sender, uint256 value);
    event WithdrawFundingAmount(address indexed creator, uint256 amount);
    event ProtocolCreated(uint64 indexed noteId, address indexed creator, address indexed investor);
    event WithdrawPoolAmount(address indexed account, uint256 amount);
    event Stopped(uint256 poolAmount,uint256 fundingAmount);
    
    receive() external payable {
        if(_stopped) revert Types.InvalidNoteStatus();
        _poolAmount += msg.value;
        emit Received(msg.sender, msg.value);
    }

    modifier whenNotStopped() {
        if (_stopped) revert Types.NotPermission();
        _;
    }

    modifier onlyCreator() {
        if(msg.sender != CREATOR) revert Types.NotPermission();
        _;
    }

    modifier onlyInvestor() {
        if(msg.sender != INVESTOR) revert Types.NotPermission();
        _;
    }

    modifier onlyFilNoteContract() {
        if(msg.sender != FIL_NOTE_CONTRACT) revert Types.NotPermission();
        _;
    }

 
    function _minReserve(Types.Note memory n) internal pure returns (uint256) {
        uint256 interest = (n.targetAmount * n.interestRateBps * n.borrowingDays) / (10000 * 365);
        return n.targetAmount + interest;
    }
 
    function getProtocolInfo() public view returns (Types.Note memory) {
         return IFilNoteContract(FIL_NOTE_CONTRACT).getNote(ID);
    }
    function withdrawFundingAmount() public nonReentrant whenNotStopped onlyCreator{
        Types.Note memory note = getProtocolInfo();
        if(note.status != uint8(Types.NoteStatus.ACTIVE)) revert Types.InvalidNoteStatus();
        uint256 amount = _fundingAmount;
        if(amount == 0) revert Types.InvalidAmount();
        _fundingAmount = 0; 
        (bool ok, ) = CREATOR.call{value: amount}("");
        if(!ok) revert Types.TransferFailed();
        emit WithdrawFundingAmount(CREATOR, amount);
    }

    function spWithdrawPoolAmount(uint256 amount) public nonReentrant whenNotStopped onlyCreator{
        if(amount == 0) revert Types.InvalidAmount();
        Types.Note memory note = getProtocolInfo();
        if (amount > _poolAmount) revert Types.InvalidAmount();
        uint256 minReserve = _minReserve(note);
        uint256 pool = _poolAmount;
        if (block.timestamp < note.expiryTime) {
            if(pool-amount < minReserve) revert Types.InvalidAmount();
        }else{
            if(note.status != uint8(Types.NoteStatus.COMPLETED)) revert Types.InvalidNoteStatus();
        }
        _poolAmount =pool - amount;
        (bool ok, ) = CREATOR.call{value: amount}("");
        if (!ok) revert Types.TransferFailed();
        emit WithdrawPoolAmount(msg.sender, amount);
    }

    function investorWithdrawPoolAmount() public nonReentrant whenNotStopped onlyInvestor{
        Types.Note memory note = getProtocolInfo();
        if(note.status != uint8(Types.NoteStatus.ACTIVE)) revert Types.InvalidNoteStatus();
        if(block.timestamp < note.expiryTime) revert Types.NotMatured();
        uint256 payout = _minReserve(note);
        uint256 balance = _poolAmount;
        uint256 payoutAmount;
        if(balance >= payout){
            payoutAmount = payout;
        }else{
            payoutAmount = balance;
        }
        _poolAmount -= payoutAmount;
        (bool ok, ) = INVESTOR.call{value: payoutAmount}("");
        if(!ok) revert Types.TransferFailed();
        if(payoutAmount == payout){
            IFilNoteContract(FIL_NOTE_CONTRACT).completeNote(ID);
        }else{
            IFilNoteContract(FIL_NOTE_CONTRACT).defaultNote(ID);
        }
        emit WithdrawPoolAmount(INVESTOR, payoutAmount);
    }

    function stopProtocol() public nonReentrant onlyFilNoteContract {
        _stopped = true;
        uint256 pool = _poolAmount;
        uint256 funding = _fundingAmount;
        uint256 payout = pool + funding;
        _poolAmount = 0;
        _fundingAmount = 0;
        (bool ok, ) = INVESTOR.call{value: payout}("");
        if(!ok) revert Types.TransferFailed();
        emit Stopped(pool, funding);
    }

}