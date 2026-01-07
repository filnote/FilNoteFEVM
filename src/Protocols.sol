// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Types } from "./utils/Types.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
interface IFilNoteContract {
    function getNote(uint64 id) external view returns (Types.Note memory);
    function completeNote(uint64 id) external returns (uint64);
    function defaultNote(uint64 id) external returns (uint64);
    function owner() external view returns (address);
}

contract ProtocolsContract is ReentrancyGuard {
    uint64 private immutable _ID;
    address private immutable _CREATOR;
    address private immutable _INVESTOR;
    address private immutable _FIL_NOTE_CONTRACT;

    uint256 private _fundingAmount;
    uint256 private _poolAmount;
    bool private _stopped;

    constructor(
        uint64 noteId,
        address noteCreator,
        address noteInvestor
    ) payable {
        _ID = noteId;
        _CREATOR = noteCreator;
        _INVESTOR = noteInvestor;
        _fundingAmount = msg.value;
        _FIL_NOTE_CONTRACT = msg.sender;
        _poolAmount = 0;
        emit ProtocolCreated(noteId, noteCreator, noteInvestor);
    }

    event Received(address indexed sender, uint256 value);
    event WithdrawFundingAmount(address indexed creator, uint256 amount);
    event ProtocolCreated(
        uint64 indexed noteId,
        address indexed creator,
        address indexed investor
    );
    event WithdrawPoolAmount(address indexed account, uint256 amount);
    event Stopped(uint256 payout);

    receive() external payable {
        _poolAmount += msg.value;
        emit Received(msg.sender, msg.value);
    }

    modifier whenNotStopped() {
        if (_stopped) revert Types.NotPermission();
        _;
    }

    modifier onlyCreator() {
        if (msg.sender != _CREATOR) revert Types.NotPermission();
        _;
    }

    modifier onlyInvestor() {
        if (msg.sender != _INVESTOR) revert Types.NotPermission();
        _;
    }

    modifier onlyFilNoteContract() {
        if (msg.sender != _FIL_NOTE_CONTRACT) revert Types.NotPermission();
        _;
    }

    function _minReserve(Types.Note memory n) internal pure returns (uint256) {
        uint256 num = uint256(n.interestRateBps) * uint256(n.borrowingDays);
        uint256 interest = Math.mulDiv(n.targetAmount, num, (10000 * 365));
        return n.targetAmount + interest;
    }

    function getProtocolInfo() public view returns (Types.Note memory) {
        return IFilNoteContract(_FIL_NOTE_CONTRACT).getNote(_ID);
    }
    function withdrawFundingAmount()
        public
        nonReentrant
        whenNotStopped
        onlyCreator
    {
        Types.Note memory note = getProtocolInfo();
        if (note.status != uint8(Types.NoteStatus.ACTIVE))
            revert Types.InvalidNoteStatus();
        if (_fundingAmount == 0) revert Types.InvalidAmount();
        uint256 payout = _fundingAmount;
        _fundingAmount = 0;
        (bool ok, ) = _CREATOR.call{ value: payout }("");
        if (!ok) revert Types.TransferFailed();
        emit WithdrawFundingAmount(_CREATOR, payout);
    }

    function spWithdrawPoolAmount(
        uint256 amount
    ) public nonReentrant whenNotStopped onlyCreator {
        if (amount == 0) revert Types.InvalidAmount();
        Types.Note memory note = getProtocolInfo();
        uint256 minReserve = _minReserve(note);
        uint256 pool = _poolAmount;
        if (note.status != uint8(Types.NoteStatus.ACTIVE)) {
            revert Types.InvalidNoteStatus();
        }
        if (pool - amount < minReserve) {
            revert Types.InvalidAmount();
        }
        _poolAmount = pool - amount;
        (bool ok, ) = _CREATOR.call{ value: amount }("");
        if (!ok) revert Types.TransferFailed();
        emit WithdrawPoolAmount(msg.sender, amount);
    }

    function investorWithdrawPoolAmount()
        public
        nonReentrant
        whenNotStopped
        onlyInvestor
    {
        Types.Note memory note = getProtocolInfo();
        if (note.status != uint8(Types.NoteStatus.ACTIVE))
            revert Types.InvalidNoteStatus();
        if (block.timestamp < note.expiryTime) revert Types.NotMatured();
        uint256 payout = _minReserve(note);
        uint256 balance = _poolAmount;
        uint256 payoutAmount;
        if (balance >= payout) {
            payoutAmount = payout;
        } else {
            payoutAmount = balance;
        }
        _poolAmount -= payoutAmount;
        (bool ok, ) = _INVESTOR.call{ value: payoutAmount }("");
        if (!ok) revert Types.TransferFailed();
        if (payoutAmount == payout) {
            IFilNoteContract(_FIL_NOTE_CONTRACT).completeNote(_ID);
        } else {
            IFilNoteContract(_FIL_NOTE_CONTRACT).defaultNote(_ID);
        }
        emit WithdrawPoolAmount(_INVESTOR, payoutAmount);
    }

    function stopProtocol() public nonReentrant onlyFilNoteContract {
        _stopped = true;
        uint256 payout = address(this).balance;
        if (payout == 0) revert Types.InvalidAmount();
        _poolAmount = 0;
        _fundingAmount = 0;
        (bool ok, ) = _INVESTOR.call{ value: payout }("");
        if (!ok) revert Types.TransferFailed();
        emit Stopped(payout);
    }

    function getContractInfo() public view returns (Types.ProtocolInfo memory) {
        return
            Types.ProtocolInfo({
                fundingAmount: _fundingAmount,
                poolAmount: _poolAmount
            });
    }
}
