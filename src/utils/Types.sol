// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title Types Library
 * @notice Library containing data structures and error definitions for FilNote contract [中文: 包含FilNote合约数据结构定义和错误定义的库]
 * @dev This library defines the core data structures used throughout the FilNote system [中文: 此库定义了FilNote系统使用的核心数据结构]
 * @author FilNote Team
 * @custom:security All data structures are designed with security considerations [中文: 所有数据结构都考虑了安全性]
 */
library Types {
    /**
     * @notice Enumeration of possible note statuses [中文: 票据可能状态的枚举]
     * @dev Defines the lifecycle states of investment notes [中文: 定义投资票据的生命周期状态]
     * @custom:status INIT - Note created but not yet approved for investment [中文: INIT - 票据已创建但尚未批准投资]
     * @custom:status INVALID - Note is invalid (unused in current implementation) [中文: INVALID - 票据无效(在当前实现中未使用)]
     * @custom:status PENDING - Note approved and waiting for investment [中文: PENDING - 票据已批准并等待投资]
     * @custom:status CLOSED - Note closed by creator or owner [中文: CLOSED - 票据被创建者或所有者关闭]
     * @custom:status ACTIVE - Note has active investment and protocol contract [中文: ACTIVE - 票据有活跃投资和协议合约]
     * @custom:status COMPLETED - Note successfully completed [中文: COMPLETED - 票据成功完成]
     * @custom:status DEFAULTED - Note defaulted by borrower [中文: DEFAULTED - 票据被借款人违约]
     * @custom:status STOP - Note stopped by owner [中文: STOP - 票据被所有者停止]
     */
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
    /**
     * @notice Structure representing an investment note [中文: 表示投资票据的结构体]
     * @dev Contains all necessary information for a FilNote investment [中文: 包含FilNote投资的所有必要信息]
     * @custom:security All fields are immutable after creation except status [中文: 除状态外，所有字段在创建后都是不可变的]
     */
    struct Note {
        uint64 id;                      ///< Unique identifier for the note [中文: 票据的唯一标识符]
        uint256 targetAmount;           ///< Target funding amount in wei [中文: 目标融资金额，以wei为单位]
        uint256 platformFeeRateBps;     ///< Platform fee rate in basis points [中文: 平台费用率，以基点为单位]
        uint256 platformFeeAmount;      ///< Actual platform fee amount collected [中文: 实际收取的平台费用金额]
        address creator;                ///< Address of the note creator [中文: 票据创建者地址]
        address investor;               ///< Address of the investor [中文: 投资者地址]
        address protocolContract;       ///< Address of the protocol contract [中文: 协议合约地址]
        address auditor;                ///< Address of the auditor [中文: 审计员地址]
        bytes32 contractHash;            ///< Hash of the associated contract [中文: 关联合约的哈希]
        uint64 expiryTime;              ///< Timestamp when the note expires [中文: 票据到期的时间戳]
        uint64 createdAt;               ///< Timestamp when the note was created [中文: 票据创建的时间戳]
        uint16 borrowingDays;           ///< Number of days for borrowing period [中文: 借款期间的天数]
        uint16 interestRateBps;          ///< Interest rate in basis points [中文: 利率，以基点为单位]
        uint8 status;                   ///< Current status of the note [中文: 票据的当前状态]
    }

    /**
     * @notice Structure for protocol contract information [中文: 协议合约信息的结构体]
     * @dev Contains funding and pool information for protocol contracts [中文: 包含协议合约的资金和池信息]
     */
    struct ProtocolInfo {
        uint256 fundingAmount;          ///< Amount of funding provided [中文: 提供的资金金额]
        uint256 poolAmount;             ///< Amount in the protocol pool [中文: 协议池中的金额]
    }

    // ============ Error Definitions ============
    // [中文: 错误定义]

    /**
     * @notice Error thrown when target amount is invalid [中文: 当目标金额无效时抛出的错误]
     * @dev Triggered when targetAmount is zero or negative [中文: 当targetAmount为零或负数时触发]
     */
    error InvalidTargetAmount();
    /**
     * @notice Error thrown when interest rate is out of valid range [中文: 当利率超出有效范围时抛出的错误]
     * @dev Triggered when interestRateBps is not between 1 and 10000 [中文: 当interestRateBps不在1到10000之间时触发]
     */
    error InterestRateOutOfRange();
    /**
     * @notice Error thrown when contract hash is invalid [中文: 当合约哈希无效时抛出的错误]
     * @dev Triggered when contractHash is zero bytes32 [中文: 当contractHash为零bytes32时触发]
     */
    error InvalidContractHash();
    /**
     * @notice Error thrown when borrowing days are invalid [中文: 当借款天数无效时抛出的错误]
     * @dev Triggered when borrowingDays is zero or exceeds maximum limit [中文: 当borrowingDays为零或超过最大限制时触发]
     */
    error InvalidBorrowingDays();
    /**
     * @notice Error thrown when note status is invalid for the operation [中文: 当票据状态对操作无效时抛出的错误]
     * @dev Triggered when note status does not match expected state [中文: 当票据状态与预期状态不匹配时触发]
     */
    error InvalidNoteStatus();
    /**
     * @notice Error thrown when investor is invalid [中文: 当投资者无效时抛出的错误]
     * @dev Triggered when investor is the same as note creator [中文: 当投资者与票据创建者相同时触发]
     */
    error InvalidInvestor();
    /**
     * @notice Error thrown when investment amount is invalid [中文: 当投资金额无效时抛出的错误]
     * @dev Triggered when msg.value does not match note target amount [中文: 当msg.value与票据目标金额不匹配时触发]
     */
    error InvalidAmount();
    /**
     * @notice Error thrown when note does not exist [中文: 当票据不存在时抛出的错误]
     * @dev Triggered when trying to access a non-existent note [中文: 当尝试访问不存在的票据时触发]
     */
    error NoNote();
    /**
     * @notice Error thrown when limit exceeds maximum allowed value [中文: 当限制超过最大允许值时抛出的错误]
     * @dev Triggered when pagination limit exceeds MAX_LIMIT constant [中文: 当分页限制超过MAX_LIMIT常量时触发]
     */
    error LimitExceeded();
    /**
     * @notice Error thrown when no extra funds are available [中文: 当没有额外资金可用时抛出的错误]
     * @dev Triggered when trying to withdraw more than available [中文: 当尝试提取超过可用金额时触发]
     */
    error NoExtraFunds();
    /**
     * @notice Error thrown when caller does not have permission [中文: 当调用者没有权限时抛出的错误]
     * @dev Triggered when unauthorized user tries to perform restricted action [中文: 当未授权用户尝试执行受限操作时触发]
     */
    error NotPermission();
    /**
     * @notice Error thrown when transfer operation fails [中文: 当转账操作失败时抛出的错误]
     * @dev Triggered when ETH transfer returns false [中文: 当ETH转账返回false时触发]
     */
    error TransferFailed();
    /**
     * @notice Error thrown when note has not matured yet [中文: 当票据尚未到期时抛出的错误]
     * @dev Triggered when trying to access note before expiry time [中文: 当在到期时间之前尝试访问票据时触发]
     */
    error NotMatured();
    /**
     * @notice Error thrown when platform fee is invalid [中文: 当平台费用无效时抛出的错误]
     * @dev Triggered when platform fee exceeds 10000 basis points [中文: 当平台费用超过10000基点时触发]
     */
    error InvalidPlatformFee();
    /**
     * @notice Error thrown when address is invalid [中文: 当地址无效时抛出的错误]
     * @dev Triggered when address is zero address [中文: 当地址为零地址时触发]
     */
    error InvalidAddress();
    /**
     * @notice Error thrown when auditor already exists [中文: 当审计员已存在时抛出的错误]
     * @dev Triggered when trying to add an existing auditor [中文: 当尝试添加已存在的审计员时触发]
     */
    error AuditorAlreadyExists();
    /**
     * @notice Error thrown when auditor does not exist [中文: 当审计员不存在时抛出的错误]
     * @dev Triggered when trying to remove a non-existent auditor [中文: 当尝试移除不存在的审计员时触发]
     */
    error AuditorNotExists();
}