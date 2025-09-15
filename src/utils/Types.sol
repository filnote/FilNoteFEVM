// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library Types {
    enum NoteStatus {
        INIT,
        INVALID,
        PENDING,
        CLOSED,
        ACTIVE,
        COMPLETED,
        DEFAULTED,
        STOP
    }
    struct Note {
        uint64 id;
        uint256 targetAmount;
        uint256 platformFeeRateBps;
        uint256 platformFeeAmount;    
        address creator;
        address investor;
        address protocolContract;
        bytes32 contractHash;
        uint64 expiryTime;
        uint64 createdAt;
        uint16 borrowingDays;
        uint16 interestRateBps;
        uint8 status;
    }

    error InvalidTargetAmount();
    error InterestRateOutOfRange();
    error InvalidContractHash();
    error InvalidBorrowingDays();
    error InvalidNoteStatus();
    error InvalidInvestor();
    error InvalidAmount();
    error NoNote();
    error LimitExceeded();
    error NoExtraFunds();
    error NotPermission();
    error TransferFailed();
    error NotMatured();
    error InvalidPlatformFee();
    error InvalidAddress();
}