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
    constructor() Ownable(msg.sender) {
        _platformFee = 200;
        _platformFeeRecipient = msg.sender;
    }

    uint64 private _nextId = 1;
    uint64[] private _allNoteIds;
    uint256 private _platformFee;
    uint256 public constant MAX_LIMIT = 100;
    address private _platformFeeRecipient;

    
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
    event PlatformFeeChanged(
        uint256 platformFee,
        address platformFeeRecipient
    );
    event WithdrawPlatformFee(
        uint256 platformFee,
        address platformFeeRecipient
    );

    modifier noteExists(uint64 id) {
        if (_notes[id].id == 0) revert Types.NoNote();
        _;
    }
     
 
    function getNote(uint64 id) public view noteExists(id) returns (Types.Note memory) {
        return _notes[id];
    }

    function getNotes(uint256 offset, uint256 limit) public view returns (Types.Note[] memory) {
        if (limit > MAX_LIMIT) revert Types.LimitExceeded();
        uint256 len = _allNoteIds.length;
        if (offset >= len) return new Types.Note[](0);
        uint256 rlen = len - offset;
        if (rlen > limit) rlen = limit;
        Types.Note[] memory page = new Types.Note[](rlen);
        for (uint256 i; i < rlen; ++i) {
            uint64 id = _allNoteIds[offset + i];
            page[i] = _notes[id];
        }
        return page;
    }

    
 
    function getNoteByIds(uint64[] calldata ids) external view returns (Types.Note[] memory result) {
        result = new Types.Note[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            result[i] = _notes[ids[i]];
        }
        return result;
    }
 
    function getNotesByInvestor(address investor,uint256 offset, uint256 limit) public view returns (uint64[] memory) {
        if(limit > MAX_LIMIT) revert Types.LimitExceeded();
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
        if(limit > MAX_LIMIT) revert Types.LimitExceeded();
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
            platformFeeRateBps: _platformFee,
            platformFeeAmount: 0,
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
        _allNoteIds.push(id);
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
        uint256 payoutPlatform = (msg.value * note.platformFeeRateBps) / 10000;
        uint256 payoutCreator = msg.value - payoutPlatform;
        (bool ok, ) = _platformFeeRecipient.call{value: payoutPlatform}("");
        if(!ok) revert Types.TransferFailed();
        ProtocolsContract protocolContract = new ProtocolsContract{value: payoutCreator}(
            note.id,
            note.creator,
            msg.sender
        );
        note.investor = msg.sender;
        note.protocolContract = address(protocolContract);
        note.platformFeeAmount = payoutPlatform;
        _notesByInvestor[msg.sender].push(id);
        emit Investment(id, msg.sender, msg.value, address(protocolContract));
        emit WithdrawPlatformFee(payoutPlatform, _platformFeeRecipient);
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
        IProtocolsContract(note.protocolContract).stopProtocol();
        note.status = uint8(Types.NoteStatus.STOP);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.STOP));
        return id;
    }

    function setPlatformFee(uint256 platformFee) external onlyOwner {
        if(platformFee > 10_000) revert Types.InvalidPlatformFee();
        _platformFee = platformFee;
        emit PlatformFeeChanged(platformFee, _platformFeeRecipient);
    }

    function setPlatformFeeRecipient(address platformFeeRecipient) external onlyOwner {
        if(platformFeeRecipient == address(0)) revert Types.InvalidAddress();
        _platformFeeRecipient = platformFeeRecipient;
        emit PlatformFeeChanged(_platformFee, platformFeeRecipient);
    }

    function getPlatformFee() external view returns (uint256) {
        return _platformFee;
    }

    function getPlatformFeeRecipient() external view returns (address) {
        return _platformFeeRecipient;
    }

    function getTotalNotes() external view returns (uint256) {
        return _allNoteIds.length;
    }

}