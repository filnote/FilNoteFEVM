// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// src/FilNote.sol

contract FilNoteContract {
    address public owner;
    uint64 public nextId = 1;

    enum NoteStatus {
        PENDING,
        Active,
        Completed,
        Cancelled
    }

    struct Note {
        uint64 id;
        address creator;
        uint256 targetAmount;    
        uint256 currentAmount;    
        NoteStatus status;
        address investor;         
        uint64 interestRateBps;
        bytes32 contractHash;
        uint64 borrowingTime;
        uint64 createdAt;
    }
    mapping(uint64 => Note) public notes;
    mapping(address => Note[]) public notesByCreator;
    mapping(address => Note[]) public notesByInvestor;

    event NoteCreated(
        uint64 indexed id,
        address indexed creator,
        uint256 targetAmount,
        uint64 interestRateBps,
        uint64 borrowingTime,
        bytes32 contractHash
    );

    event Investment(
        uint64 indexed id,
        address indexed investor,
        uint256 amount
    );

     constructor() {
        owner = msg.sender;
     }

    error InvalidTargetAmount();
    error InterestRateOutOfRange();
    error InvalidContractHash();

    function getOwner() public view returns (address) {
        return owner;
    }
 
    function getNote(uint64 id) public view returns (Note memory) {
        return notes[id];
    }
 
    function getNotesByInvestor(address investor) public view returns (Note[] memory) {
        return notesByInvestor[investor];
    }
 
    function getNotesByCreator(address creator) public view returns (Note[] memory) {
        return notesByCreator[creator];
    }

    function createNote(uint256 targetAmount, uint64 interestRateBps, bytes32 contractHash, uint64 borrowingTime) public returns (uint64) {
        if(targetAmount  <=0 ) revert InvalidTargetAmount();
        if(interestRateBps > 10_000 || interestRateBps <= 0) revert InterestRateOutOfRange();
        if(contractHash == bytes32(0)) revert InvalidContractHash();
        uint64 id = nextId;
        nextId++;
        Note memory note = Note({
            id:id,
            creator: msg.sender,
            targetAmount: targetAmount,
            currentAmount: 0,
            status: NoteStatus.PENDING,
            investor: address(0),
            interestRateBps: interestRateBps,
            contractHash: contractHash,
            borrowingTime: borrowingTime,
            createdAt: uint64(block.timestamp)
        });
        notes[id] = note;
        notesByCreator[msg.sender].push(note);
        emit NoteCreated(id, msg.sender, targetAmount, interestRateBps, borrowingTime, contractHash);
        return id;
     }
}
