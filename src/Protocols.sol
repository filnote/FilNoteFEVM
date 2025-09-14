// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Types } from "./utils/Types.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IFilNoteContract {
    function getNote(uint64 id) external view returns (Types.Note memory);
    function completeNote(uint64 id) external returns (uint64);
}

contract ProtocolsContract is ReentrancyGuard {
    uint64 private _id; 
    address private _creator;
    address private _investor;
    address private _filNoteContract;
    uint256 private _fundingAmount;
    uint256 private _poolAmount;
    
    constructor(uint64 noteId, address noteCreator,address noteInvestor) payable {
        _id = noteId;
        _creator = noteCreator;
        _investor = noteInvestor;
        _fundingAmount = msg.value;
        _filNoteContract = msg.sender;
        emit ProtocolCreated(noteId, noteCreator, noteInvestor);
    }

    event Received(address indexed sender, uint256 value);
    event WithdrawFundingAmount(address indexed creator, uint256 amount);
    event ProtocolCreated(uint64 indexed noteId, address indexed creator, address indexed investor);
    event WithdrawPoolAmount(address indexed account, uint256 amount);
    
    receive() external payable {
        _poolAmount += msg.value;
        emit Received(msg.sender, msg.value);
    }

    function getProtocolInfo() public view returns (Types.Note memory) {
         return IFilNoteContract(_filNoteContract).getNote(_id);
    }

    function withdrawFundingAmount() public nonReentrant {
        Types.Note memory note = getProtocolInfo();
        if(note.status != uint8(Types.NoteStatus.ACTIVE)) revert Types.InvalidNoteStatus();
        if(msg.sender != _creator) revert Types.NotPermission();
        uint256 amount = _fundingAmount;
        if(amount == 0) revert Types.InvalidAmount();
        _fundingAmount = 0; 
        (bool ok, ) = _creator.call{value: amount}("");
        if(!ok) revert Types.TransferFailed();
        emit WithdrawFundingAmount(_creator, amount);
    }

    function spWithdrawPoolAmount(uint256 amount) public nonReentrant {
        Types.Note memory note = getProtocolInfo();
        if (msg.sender != _creator) revert Types.NotPermission();
        if (amount > _poolAmount) revert Types.InvalidAmount();
        uint256 interest = (note.targetAmount * note.interestRateBps * note.borrowingDays) 
                        / (10000 * 365);
        uint256 minReserve = note.targetAmount + interest;
        
        if (block.timestamp < note.expiryTime && _poolAmount <= minReserve) {
            revert Types.InvalidAmount();
        }
        if (block.timestamp >= note.expiryTime && note.status != uint8(Types.NoteStatus.COMPLETED)) {
            revert Types.InvalidAmount();
        }
        _poolAmount -= amount;
        (bool ok, ) = _creator.call{value: amount}("");
        if (!ok) revert Types.TransferFailed();
        emit WithdrawPoolAmount(_creator, amount);
    }

    function investorWithdrawPoolAmount() public nonReentrant {
        Types.Note memory note = getProtocolInfo();
        if(note.status != uint8(Types.NoteStatus.ACTIVE)) revert Types.InvalidNoteStatus();
        if(msg.sender != _investor) revert Types.NotPermission();
        if(block.timestamp < note.expiryTime) revert Types.NotMatured();
        uint256 interest = (note.targetAmount * note.interestRateBps * note.borrowingDays) 
                        / (10000 * 365);
        uint256 payout = note.targetAmount + interest;
        uint256 balance = _poolAmount;
        uint256 payoutAmount;
        if(balance > payout){
            payoutAmount = payout;
        }else{
            payoutAmount = balance;
        }
        _poolAmount -= payoutAmount;
        (bool ok, ) = _investor.call{value: payoutAmount}("");
        if(!ok) revert Types.TransferFailed();
        IFilNoteContract(_filNoteContract).completeNote(_id);
        emit WithdrawPoolAmount(_investor, payoutAmount);
    }

    function stopProtocol() public {
        if(msg.sender != _filNoteContract) revert Types.NotPermission();
        uint256 payout = _poolAmount;
        _poolAmount = 0;
        (bool ok, ) = _investor.call{value: payout}("");
        if(!ok) revert Types.TransferFailed();
        emit WithdrawPoolAmount(_investor, payout);
    }

}