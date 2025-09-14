// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ProtocolsContract } from "./Protocols.sol";
import { Types } from "./utils/Types.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


interface IProtocolsContract {
    function stopProtocol() external;
}

contract FilNoteContract is Ownable, ReentrancyGuard {
    constructor() Ownable(msg.sender) {}

    uint64 private _nextId = 1;
    
    mapping(uint64 => Types.Note) internal _notes;
    mapping(address => uint64[]) internal _notesByCreator;
    mapping(address => uint64[]) internal _notesByInvestor;

    event Investment(
        uint64 indexed id,
        address indexed investor,
        uint256 amount,
        address protocolContract
    );
    event NoteCreated(
        uint64 indexed id,
        address indexed creator,
        uint256 targetAmount,
        uint16 interestRateBps,
        uint16 borrowingDays,
        uint64 expiryTime
    );
    event NoteStatusChanged(
        uint64 indexed id,
        uint8 status
    );

    modifier noteExists(uint64 id) {
        if (_notes[id].id == 0) revert Types.NoNote();
        _;
    }
     
    
    function getNote(uint64 id) public view noteExists(id) returns (Types.Note memory) {
        return _notes[id];
    }
    

    function getNotes(uint64[] calldata ids) external view returns (Types.Note[] memory result) {
        result = new Types.Note[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            result[i] = _notes[ids[i]];
        }
        return result;
    }
 
    function getNotesByInvestor(address investor,uint256 offset, uint256 limit) public view returns (uint64[] memory) {
        if(limit > 100) revert Types.LimitExceeded();
        uint64[] storage all = _notesByInvestor[investor];
        uint256 len = all.length;
        if(offset >= len) return new uint64[](0);
        uint256 rlen = len - offset;
        if (rlen > limit) rlen = limit;
        uint64[] memory page = new uint64[](rlen);
        for (uint256 i; i < rlen; ++i) page[i] = all[offset + i];
        return page;
    }
 
    function getNotesByCreator(address creator,uint256 offset, uint256 limit) public view returns (uint64[] memory) {
        if(limit > 100) revert Types.LimitExceeded();
        uint64[] storage all = _notesByCreator[creator];
        uint256 len = all.length;
        if(offset >= len) return new uint64[](0);
        uint256 rlen = len - offset;
        if (rlen > limit) rlen = limit;
        uint64[] memory page = new uint64[](rlen);
        for (uint256 i; i < rlen; ++i) page[i] = all[offset + i];
        return page;
    }

    function createNote(uint256 targetAmount, uint16 interestRateBps,   uint16 borrowingDays) public returns (uint64) {
        if(targetAmount  <=0 ) revert Types.InvalidTargetAmount();
        if(interestRateBps > 10_000 || interestRateBps <= 0) revert Types.InterestRateOutOfRange();
        if(borrowingDays <= 0 || borrowingDays > 1000) revert Types.InvalidBorrowingDays();
        uint64 id = _nextId;
        unchecked { _nextId = id + 1; }
        uint64 expiryTime = uint64(block.timestamp) + (borrowingDays * 1 days);
        Types.Note memory note = Types.Note({
            id:id,
            creator: msg.sender,
            targetAmount: targetAmount,
            status: uint8(Types.NoteStatus.INIT),
            investor: address(0),
            interestRateBps: interestRateBps,
            contractHash: bytes32(0),
            borrowingDays: borrowingDays,
            expiryTime: expiryTime,
            createdAt: uint64(block.timestamp),
            protocolContract: address(0)
        });
        _notes[id] = note;
        _notesByCreator[msg.sender].push(id);
        emit NoteCreated(id, msg.sender, targetAmount, interestRateBps, borrowingDays, expiryTime);
        return id;
     }

    function invest(uint64 id) external payable nonReentrant noteExists(id) returns (address) {
        Types.Note storage note = _notes[id];
        if(note.status != uint8(Types.NoteStatus.PENDING)) revert Types.InvalidNoteStatus();
        if(msg.sender == note.creator) revert Types.InvalidInvestor();
        if(msg.value != note.targetAmount) revert Types.InvalidAmount();
        if (block.timestamp >= note.expiryTime) revert Types.InvalidNoteStatus();
        note.status = uint8(Types.NoteStatus.ACTIVE);
        ProtocolsContract protocolContract = new ProtocolsContract{value: msg.value}(
            note.id,
            note.creator,
            msg.sender
        );
        note.investor = msg.sender;
        note.protocolContract = address(protocolContract);
        _notesByInvestor[msg.sender].push(id);
        emit Investment(id, msg.sender, msg.value, address(protocolContract));
        return address(protocolContract);
    }

    function closeNote(uint64 id) external  noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if(msg.sender != note.creator && msg.sender != owner()) revert Types.NotPermission();
        if(note.status != uint8(Types.NoteStatus.INIT) && note.status != uint8(Types.NoteStatus.PENDING)) revert Types.InvalidNoteStatus();
        note.status = uint8(Types.NoteStatus.CLOSED);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.CLOSED));
        return id;
    }

    function pendingNote(uint64 id,bytes32 contractHash) external onlyOwner noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if(note.status != uint8(Types.NoteStatus.INIT)) revert Types.InvalidNoteStatus();
        if(contractHash == bytes32(0)) revert Types.InvalidContractHash();
        note.status = uint8(Types.NoteStatus.PENDING);
        note.contractHash = contractHash;
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.PENDING));
        return id;
    }

    function completeNote(uint64 id) external noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if(note.status != uint8(Types.NoteStatus.ACTIVE)) revert Types.InvalidNoteStatus();
        if(msg.sender != note.protocolContract) revert Types.NotPermission();
        note.status = uint8(Types.NoteStatus.COMPLETED);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.COMPLETED));
        return id;
    }
    function defaultNote(uint64 id) external noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if(note.status != uint8(Types.NoteStatus.ACTIVE)) revert Types.InvalidNoteStatus();
        if(msg.sender != note.protocolContract) revert Types.NotPermission();
        note.status = uint8(Types.NoteStatus.DEFAULTED);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.DEFAULTED));
        return id;
    }

    function stopNote(uint64 id) external onlyOwner noteExists(id)  returns (uint64) {
        Types.Note storage note = _notes[id];
        if(note.status != uint8(Types.NoteStatus.ACTIVE)) revert Types.InvalidNoteStatus();
        note.status = uint8(Types.NoteStatus.STOP);
        IProtocolsContract(note.protocolContract).stopProtocol();
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.STOP));
        return id;
    }

}