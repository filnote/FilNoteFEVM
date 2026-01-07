// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ProtocolsContract } from "./Protocols.sol";
import { Types } from "./utils/Types.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IProtocolsContract Interface
 * @notice Interface for protocol contract interaction [中文: 协议合约交互接口]
 * @dev Defines the interface for stopping protocol contracts [中文: 定义停止协议合约的接口]
 */
interface IProtocolsContract {
    /**
     * @notice Stop the protocol contract [中文: 停止协议合约]
     * @dev This function is called to halt protocol operations [中文: 此函数用于停止协议操作]
     */
    function stopProtocol() external;
}

/**
 * @title FilNoteContract
 * @notice Main contract for managing FilNote investment notes [中文: 管理FilNote投资票据的主合约]
 * @dev This contract handles note creation, investment, and lifecycle management [中文: 此合约处理票据创建、投资和生命周期管理]
 * @author FilNote Team
 * @custom:security This contract uses OpenZeppelin's Ownable and ReentrancyGuard for security [中文: 此合约使用OpenZeppelin的Ownable和ReentrancyGuard确保安全]
 */
contract FilNoteContract is Ownable, ReentrancyGuard {
    /**
     * @notice Constructor function [中文: 构造函数]
     * @dev Initializes the contract with default platform fee and sets deployer as owner [中文: 使用默认平台费用初始化合约并设置部署者为所有者]
     * @custom:permission Only deployer can call this function [中文: 只有部署者可以调用此函数]
     */
    constructor() Ownable(msg.sender) {
        _platformFee = 200;
        _platformFeeRecipient = msg.sender;
    }

    uint64 private _nextId = 1;
    uint64[] private _allNoteIds;
    uint256 private _platformFee;
    uint256 public constant MAX_LIMIT = 100;
    uint256 public constant MAX_TARGET_AMOUNT = 1_000_000_000 ether;
    address private _platformFeeRecipient;
    mapping(address => bool) private _isAuditor;
    address[] private _auditorsList;

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
        uint16 borrowingDays
    );
    event NoteStatusChanged(uint64 indexed id, uint8 status);
    event PlatformFeeChanged(uint256 platformFee, address platformFeeRecipient);
    event WithdrawPlatformFee(
        uint256 platformFee,
        address platformFeeRecipient
    );
    event AuditorUpdated(address auditor, bool isActive);

    /**
     * @notice Modifier to check if a note exists [中文: 检查票据是否存在的修饰符]
     * @dev Reverts if the note with given ID does not exist [中文: 如果给定ID的票据不存在则回滚]
     * @param id The ID of the note to check [中文: 要检查的票据ID]
     * @custom:reverts Types.NoNote() if note does not exist [中文: 如果票据不存在则回滚Types.NoNote()]
     */
    modifier noteExists(uint64 id) {
        if (_notes[id].id == 0) revert Types.NoNote();
        _;
    }
    /**
     * @notice Modifier to check if the caller is an auditor [中文: 检查调用者是否是审计员]
     * @dev Reverts if the caller is not an auditor [中文: 如果调用者不是审计员则回滚]
     * @custom:reverts Types.NotPermission() if caller is not an auditor [中文: 如果调用者不是审计员则回滚Types.NotPermission()]
     */
    modifier onlyAuditor() {
        if (!isAuditor(msg.sender)) revert Types.NotPermission();
        _;
    }

    /**
     * @notice Check if an auditor is in the list of auditors [中文: 检查一个审计员是否在审计员列表中]
     * @dev Checks if the given address is an auditor [中文: 检查给定地址是否为审计员]
     * @param auditor The address of the auditor to check [中文: 要检查的审计员地址]
     * @return bool True if the auditor is in the list, false otherwise [中文: 如果审计员在列表中返回true，否则返回false]
     * @custom:permission Public function, anyone can call [中文: 公共函数，任何人都可以调用]
     */
    function isAuditor(address auditor) public view returns (bool) {
        return _isAuditor[auditor];
    }
    /**
     * @notice Add an auditor to the list of auditors [中文: 添加一个审计员到审计员列表中]
     * @dev Adds a new auditor address and emits an event [中文: 添加新的审计员地址并发出事件]
     * @param auditor The address of the auditor to add [中文: 要添加的审计员地址]
     * @custom:permission Only contract owner can call [中文: 只有合约所有者可以调用]
     * @custom:reverts Types.InvalidAddress() if auditor is zero address [中文: 如果审计员为零地址则回滚Types.InvalidAddress()]
     * @custom:reverts Types.AuditorAlreadyExists() if auditor already exists [中文: 如果审计员已存在则回滚Types.AuditorAlreadyExists()]
     * @custom:emits AuditorUpdated event with auditor address and true status [中文: 发出AuditorUpdated事件，包含审计员地址和true状态]
     */
    function addAuditor(address auditor) external onlyOwner {
        if (auditor == address(0)) revert Types.InvalidAddress();
        if (_isAuditor[auditor]) revert Types.AuditorAlreadyExists();
        _isAuditor[auditor] = true;
        _auditorsList.push(auditor);
        emit AuditorUpdated(auditor, true);
    }
    /**
     * @notice Remove an auditor from the list of auditors [中文: 从审计员列表中移除一个审计员]
     * @dev Removes an auditor using swap-and-pop pattern [中文: 使用交换和弹出模式移除审计员]
     * @param auditor The address of the auditor to remove [中文: 要移除的审计员地址]
     * @custom:permission Only contract owner can call [中文: 只有合约所有者可以调用]
     * @custom:reverts Types.InvalidAddress() if auditor is zero address [中文: 如果审计员为零地址则回滚Types.InvalidAddress()]
     * @custom:reverts Types.AuditorNotExists() if auditor does not exist [中文: 如果审计员不存在则回滚Types.AuditorNotExists()]
     * @custom:emits AuditorUpdated event with auditor address and false status [中文: 发出AuditorUpdated事件，包含审计员地址和false状态]
     */
    function removeAuditor(address auditor) external onlyOwner {
        if (auditor == address(0)) revert Types.InvalidAddress();
        if (!_isAuditor[auditor]) revert Types.AuditorNotExists();
        _isAuditor[auditor] = false;
        // 从数组中移除（使用 swap-and-pop 模式）
        uint256 length = _auditorsList.length;
        for (uint256 i = 0; i < length; i++) {
            if (_auditorsList[i] == auditor) {
                _auditorsList[i] = _auditorsList[length - 1];
                _auditorsList.pop();
                break;
            }
        }
        emit AuditorUpdated(auditor, false);
    }

    /**
     * @notice Get the list of auditors [中文: 获取审计员列表]
     * @dev Returns a copy of the auditors array [中文: 返回审计员数组的副本]
     * @return address[] memory The list of auditors [中文: 审计员地址列表]
     * @custom:permission Public function, anyone can call [中文: 公共函数，任何人都可以调用]
     * @custom:gas-optimization Returns memory array for gas efficiency [中文: 返回内存数组以提高gas效率]
     */
    function getAuditors() public view returns (address[] memory) {
        return _auditorsList;
    }

    /**
     * @notice Get a note by its ID [中文: 根据ID获取一个Note]
     * @dev Retrieves a specific note from storage by its unique identifier [中文: 根据唯一标识符从存储中检索特定票据]
     * @param id The ID of the note to get [中文: 要获取的票据ID]
     * @return Types.Note memory The note data structure [中文: 票据数据结构]
     * @custom:permission Public function, anyone can call [中文: 公共函数，任何人都可以调用]
     * @custom:modifier Uses noteExists modifier to ensure note exists [中文: 使用noteExists修饰符确保票据存在]
     * @custom:reverts Types.NoNote() if note does not exist [中文: 如果票据不存在则回滚Types.NoNote()]
     */
    function getNote(
        uint64 id
    ) public view noteExists(id) returns (Types.Note memory) {
        return _notes[id];
    }

    /**
     * @notice Get a list of notes with pagination [中文: 分页获取Note列表]
     * @dev Retrieves a paginated list of all notes in the system [中文: 检索系统中所有票据的分页列表]
     * @param offset The starting index for pagination [中文: 分页的起始索引]
     * @param limit The maximum number of notes to return [中文: 返回的最大票据数量]
     * @return Types.Note[] memory The paginated list of notes [中文: 分页的票据列表]
     * @custom:permission Public function, anyone can call [中文: 公共函数，任何人都可以调用]
     * @custom:reverts Types.LimitExceeded() if limit exceeds MAX_LIMIT [中文: 如果限制超过MAX_LIMIT则回滚Types.LimitExceeded()]
     * @custom:gas-optimization Returns empty array if offset exceeds total length [中文: 如果偏移量超过总长度则返回空数组]
     */
    function getNotes(
        uint256 offset,
        uint256 limit
    ) public view returns (Types.Note[] memory) {
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

    /**
     * @notice Get a list of notes by their IDs [中文: 根据IDs获取Note列表]
     * @dev Retrieves multiple notes by providing an array of note IDs [中文: 通过提供票据ID数组来检索多个票据]
     * @param ids The array of note IDs to retrieve [中文: 要检索的票据ID数组]
     * @return result The array of notes corresponding to the provided IDs [中文: 与提供的ID对应的票据数组]
     * @custom:permission External function, anyone can call [中文: 外部函数，任何人都可以调用]
     * @custom:gas-optimization Uses calldata for input parameter to save gas [中文: 对输入参数使用calldata以节省gas]
     * @custom:note Returns empty note structures for non-existent IDs [中文: 对于不存在的ID返回空票据结构]
     */
    function getNoteByIds(
        uint64[] calldata ids
    ) external view returns (Types.Note[] memory result) {
        result = new Types.Note[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            result[i] = _notes[ids[i]];
        }
        return result;
    }

    /**
     * @notice Get a list of notes by their investor with pagination [中文: 分页获取投资者的Note列表]
     * @dev Retrieves note IDs for a specific investor with pagination support [中文: 检索特定投资者的票据ID，支持分页]
     * @param investor The address of the investor [中文: 投资者的地址]
     * @param offset The starting index for pagination [中文: 分页的起始索引]
     * @param limit The maximum number of note IDs to return [中文: 返回的最大票据ID数量]
     * @return uint64[] memory The paginated list of note IDs [中文: 分页的票据ID列表]
     * @custom:permission Public function, anyone can call [中文: 公共函数，任何人都可以调用]
     * @custom:reverts Types.LimitExceeded() if limit exceeds MAX_LIMIT [中文: 如果限制超过MAX_LIMIT则回滚Types.LimitExceeded()]
     * @custom:gas-optimization Returns empty array if offset exceeds investor's note count [中文: 如果偏移量超过投资者的票据数量则返回空数组]
     */
    function getNotesByInvestor(
        address investor,
        uint256 offset,
        uint256 limit
    ) public view returns (uint64[] memory) {
        if (limit > MAX_LIMIT) revert Types.LimitExceeded();
        uint64[] storage all = _notesByInvestor[investor];
        uint256 len = all.length;
        if (offset >= len) return new uint64[](0);
        uint256 rlen = len - offset;
        if (rlen > limit) rlen = limit;
        uint64[] memory page = new uint64[](rlen);
        for (uint256 i; i < rlen; ++i) page[i] = all[offset + i];
        return page;
    }

    /**
     * @notice Get a list of notes by their creator with pagination [中文: 分页获取创建者的Note列表]
     * @dev Retrieves note IDs for a specific creator with pagination support [中文: 检索特定创建者的票据ID，支持分页]
     * @param creator The address of the note creator [中文: 票据创建者的地址]
     * @param offset The starting index for pagination [中文: 分页的起始索引]
     * @param limit The maximum number of note IDs to return [中文: 返回的最大票据ID数量]
     * @return uint64[] memory The paginated list of note IDs [中文: 分页的票据ID列表]
     * @custom:permission Public function, anyone can call [中文: 公共函数，任何人都可以调用]
     * @custom:reverts Types.LimitExceeded() if limit exceeds MAX_LIMIT [中文: 如果限制超过MAX_LIMIT则回滚Types.LimitExceeded()]
     * @custom:gas-optimization Returns empty array if offset exceeds creator's note count [中文: 如果偏移量超过创建者的票据数量则返回空数组]
     */
    function getNotesByCreator(
        address creator,
        uint256 offset,
        uint256 limit
    ) public view returns (uint64[] memory) {
        if (limit > MAX_LIMIT) revert Types.LimitExceeded();
        uint64[] storage all = _notesByCreator[creator];
        uint256 len = all.length;
        if (offset >= len) return new uint64[](0);
        uint256 rlen = len - offset;
        if (rlen > limit) rlen = limit;
        uint64[] memory page = new uint64[](rlen);
        for (uint256 i; i < rlen; ++i) page[i] = all[offset + i];
        return page;
    }

    /**
     * @notice Create a new investment note [中文: 创建新的投资票据]
     * @dev Creates a new note with specified parameters and assigns a unique ID [中文: 使用指定参数创建新票据并分配唯一ID]
     * @param targetAmount The target funding amount for the note [中文: 票据的目标融资金额]
     * @param interestRateBps The interest rate in basis points (0-10000) [中文: 利率，以基点为单位(0-10000)]
     * @param borrowingDays The number of days for the borrowing period [中文: 借款期间的天数]
     * @return uint64 The unique ID of the created note [中文: 创建的票据的唯一ID]
     * @custom:permission Public function, anyone can call [中文: 公共函数，任何人都可以调用]
     * @custom:reverts Types.InvalidTargetAmount() if targetAmount is zero, negative, or exceeds MAX_TARGET_AMOUNT [中文: 如果目标金额为零、负数或超过MAX_TARGET_AMOUNT则回滚Types.InvalidTargetAmount()]
     * @custom:reverts Types.InterestRateOutOfRange() if interest rate is invalid [中文: 如果利率无效则回滚Types.InterestRateOutOfRange()]
     * @custom:reverts Types.InvalidBorrowingDays() if borrowing days are invalid [中文: 如果借款天数无效则回滚Types.InvalidBorrowingDays()]
     * @custom:emits NoteCreated event with note details [中文: 发出包含票据详情的NoteCreated事件]
     * @custom:gas-optimization Uses unchecked arithmetic for ID increment [中文: 对ID递增使用未检查算术]
     * @custom:note Privacy certificate hash is set during audit via pendingNote() [中文: 隐私凭证哈希在审计时通过pendingNote()设置]
     */
    function createNote(
        uint256 targetAmount,
        uint16 interestRateBps,
        uint16 borrowingDays
    ) public returns (uint64) {
        if (targetAmount <= 0) revert Types.InvalidTargetAmount();
        if (targetAmount > MAX_TARGET_AMOUNT)
            revert Types.InvalidTargetAmount();
        if (interestRateBps > 10_000 || interestRateBps <= 0)
            revert Types.InterestRateOutOfRange();
        if (borrowingDays <= 0 || borrowingDays > 1000)
            revert Types.InvalidBorrowingDays();
        uint64 id = _nextId;
        unchecked {
            _nextId = id + 1;
        }
        Types.Note memory note = Types.Note({
            id: id,
            creator: msg.sender,
            targetAmount: targetAmount,
            platformFeeRateBps: _platformFee,
            platformFeeAmount: 0,
            status: uint8(Types.NoteStatus.INIT),
            investor: address(0),
            interestRateBps: interestRateBps,
            contractHash: "",
            privacyCertificateHash: "",
            privacyCredentialsAbridgedHash: "",
            borrowingDays: borrowingDays,
            expiryTime: 0,
            createdAt: uint64(block.timestamp),
            protocolContract: address(0),
            auditor: address(0)
        });
        _notes[id] = note;
        _allNoteIds.push(id);
        _notesByCreator[msg.sender].push(id);
        emit NoteCreated(
            id,
            msg.sender,
            targetAmount,
            interestRateBps,
            borrowingDays
        );
        return id;
    }

    /**
     * @notice Invest in a note by providing funding [中文: 通过提供资金投资票据]
     * @dev Processes investment by creating a protocol contract and distributing funds [中文: 通过创建协议合约和分配资金来处理投资]
     * @param id The ID of the note to invest in [中文: 要投资的票据ID]
     * @return address The address of the newly created protocol contract [中文: 新创建的协议合约地址]
     * @custom:permission External payable function, anyone can call [中文: 外部可支付函数，任何人都可以调用]
     * @custom:modifier Uses nonReentrant to prevent reentrancy attacks [中文: 使用nonReentrant防止重入攻击]
     * @custom:modifier Uses noteExists to ensure note exists [中文: 使用noteExists确保票据存在]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in PENDING status [中文: 如果票据不在PENDING状态则回滚Types.InvalidNoteStatus()]
     * @custom:reverts Types.InvalidInvestor() if investor is the note creator [中文: 如果投资者是票据创建者则回滚Types.InvalidInvestor()]
     * @custom:reverts Types.InvalidAmount() if msg.value doesn't match target amount [中文: 如果msg.value与目标金额不匹配则回滚Types.InvalidAmount()]
     * @custom:reverts Types.TransferFailed() if platform fee transfer fails [中文: 如果平台费用转账失败则回滚Types.TransferFailed()]
     * @custom:emits Investment event with investment details [中文: 发出包含投资详情的Investment事件]
     * @custom:emits WithdrawPlatformFee event with fee details [中文: 发出包含费用详情的WithdrawPlatformFee事件]
     */
    function invest(
        uint64 id
    ) external payable nonReentrant noteExists(id) returns (address) {
        Types.Note storage note = _notes[id];
        if (note.status != uint8(Types.NoteStatus.PENDING))
            revert Types.InvalidNoteStatus();
        if (msg.sender == note.creator) revert Types.InvalidInvestor();
        if (msg.value != note.targetAmount) revert Types.InvalidAmount();
        note.status = uint8(Types.NoteStatus.ACTIVE);
        uint256 payoutPlatform = Math.mulDiv(
            msg.value,
            note.platformFeeRateBps,
            10000
        );
        uint256 payoutCreator = msg.value - payoutPlatform;
        (bool ok, ) = _platformFeeRecipient.call{ value: payoutPlatform }("");
        if (!ok) revert Types.TransferFailed();
        ProtocolsContract protocolContract = new ProtocolsContract{
            value: payoutCreator
        }(note.id, note.creator, msg.sender);
        note.expiryTime = block.timestamp + (note.borrowingDays * 1 days);
        note.investor = msg.sender;
        note.protocolContract = address(protocolContract);
        note.platformFeeAmount = payoutPlatform;
        _notesByInvestor[msg.sender].push(id);
        emit Investment(id, msg.sender, msg.value, address(protocolContract));
        emit WithdrawPlatformFee(payoutPlatform, _platformFeeRecipient);
        return address(protocolContract);
    }

    /**
     * @notice Close a note to prevent further investments [中文: 关闭票据以防止进一步投资]
     * @dev Changes note status to CLOSED, preventing new investments [中文: 将票据状态更改为CLOSED，防止新投资]
     * @param id The ID of the note to close [中文: 要关闭的票据ID]
     * @return uint64 The ID of the closed note [中文: 已关闭票据的ID]
     * @custom:permission Only note creator or contract owner can call [中文: 只有票据创建者或合约所有者可以调用]
     * @custom:modifier Uses noteExists to ensure note exists [中文: 使用noteExists确保票据存在]
     * @custom:reverts Types.NotPermission() if caller is not authorized [中文: 如果调用者未授权则回滚Types.NotPermission()]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in INIT or PENDING status [中文: 如果票据不在INIT或PENDING状态则回滚Types.InvalidNoteStatus()]
     * @custom:emits NoteStatusChanged event with CLOSED status [中文: 发出包含CLOSED状态的NoteStatusChanged事件]
     */
    function closeNote(uint64 id) external noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if (msg.sender != note.creator && msg.sender != owner())
            revert Types.NotPermission();
        if (
            note.status != uint8(Types.NoteStatus.INIT) &&
            note.status != uint8(Types.NoteStatus.PENDING)
        ) revert Types.InvalidNoteStatus();
        note.status = uint8(Types.NoteStatus.CLOSED);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.CLOSED));
        return id;
    }

    /**
     * @notice Set a note to pending status for investment [中文: 将票据设置为待投资状态]
     * @dev Changes note status from INIT to PENDING and sets contract hash, encrypted privacy certificate hash, and abridged hash [中文: 将票据状态从INIT更改为PENDING并设置合约哈希、加密的隐私凭证哈希和摘要哈希]
     * @param id The ID of the note to set to pending [中文: 要设置为待投资状态的票据ID]
     * @param contractHash The IPFS CID of the associated contract [中文: 关联合约的IPFS CID]
     * @param encryptedPrivacyCertificateHash The encrypted IPFS CID of the privacy certificate (optional, can be empty string) [中文: 加密的隐私凭证IPFS CID（可选，可为空字符串）]
     * @param privacyCredentialsAbridgedHash The IPFS CID of the privacy credentials abridged (optional, can be empty string) [中文: 隐私凭证摘要的IPFS CID（可选，可为空字符串）]
     * @return uint64 The ID of the pending note [中文: 待投资票据的ID]
     * @custom:permission Only auditor can call [中文: 只有审计员可以调用]
     * @custom:modifier Uses onlyAuditor to restrict access [中文: 使用onlyAuditor限制访问]
     * @custom:modifier Uses noteExists to ensure note exists [中文: 使用noteExists确保票据存在]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in INIT status [中文: 如果票据不在INIT状态则回滚Types.InvalidNoteStatus()]
     * @custom:reverts Types.InvalidContractHash() if contract hash is empty [中文: 如果合约哈希为空则回滚Types.InvalidContractHash()]
     * @custom:emits NoteStatusChanged event with PENDING status [中文: 发出包含PENDING状态的NoteStatusChanged事件]
     */
    function pendingNote(
        uint64 id,
        string calldata contractHash,
        string calldata encryptedPrivacyCertificateHash,
        string calldata privacyCredentialsAbridgedHash
    ) external onlyAuditor noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if (note.status != uint8(Types.NoteStatus.INIT))
            revert Types.InvalidNoteStatus();
        if (bytes(contractHash).length == 0) revert Types.InvalidContractHash();
        note.status = uint8(Types.NoteStatus.PENDING);
        note.contractHash = contractHash;
        if (bytes(encryptedPrivacyCertificateHash).length > 0) {
            note.privacyCertificateHash = encryptedPrivacyCertificateHash;
        }
        if (bytes(privacyCredentialsAbridgedHash).length > 0) {
            note
                .privacyCredentialsAbridgedHash = privacyCredentialsAbridgedHash;
        }
        note.auditor = msg.sender;
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.PENDING));
        return id;
    }

    /**
     * @notice Mark a note as completed [中文: 将票据标记为已完成]
     * @dev Changes note status from ACTIVE to COMPLETED [中文: 将票据状态从ACTIVE更改为COMPLETED]
     * @param id The ID of the note to complete [中文: 要完成的票据ID]
     * @return uint64 The ID of the completed note [中文: 已完成票据的ID]
     * @custom:permission Only the protocol contract can call [中文: 只有协议合约可以调用]
     * @custom:modifier Uses noteExists to ensure note exists [中文: 使用noteExists确保票据存在]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in ACTIVE status [中文: 如果票据不在ACTIVE状态则回滚Types.InvalidNoteStatus()]
     * @custom:reverts Types.NotPermission() if caller is not the protocol contract [中文: 如果调用者不是协议合约则回滚Types.NotPermission()]
     * @custom:emits NoteStatusChanged event with COMPLETED status [中文: 发出包含COMPLETED状态的NoteStatusChanged事件]
     */
    function completeNote(uint64 id) external noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if (note.status != uint8(Types.NoteStatus.ACTIVE))
            revert Types.InvalidNoteStatus();
        if (msg.sender != note.protocolContract) revert Types.NotPermission();
        note.status = uint8(Types.NoteStatus.COMPLETED);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.COMPLETED));
        return id;
    }
    /**
     * @notice Mark a note as defaulted [中文: 将票据标记为违约]
     * @dev Changes note status from ACTIVE to DEFAULTED [中文: 将票据状态从ACTIVE更改为DEFAULTED]
     * @param id The ID of the note to mark as defaulted [中文: 要标记为违约的票据ID]
     * @return uint64 The ID of the defaulted note [中文: 违约票据的ID]
     * @custom:permission Only the protocol contract can call [中文: 只有协议合约可以调用]
     * @custom:modifier Uses noteExists to ensure note exists [中文: 使用noteExists确保票据存在]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in ACTIVE status [中文: 如果票据不在ACTIVE状态则回滚Types.InvalidNoteStatus()]
     * @custom:reverts Types.NotPermission() if caller is not the protocol contract [中文: 如果调用者不是协议合约则回滚Types.NotPermission()]
     * @custom:emits NoteStatusChanged event with DEFAULTED status [中文: 发出包含DEFAULTED状态的NoteStatusChanged事件]
     */
    function defaultNote(uint64 id) external noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if (note.status != uint8(Types.NoteStatus.ACTIVE))
            revert Types.InvalidNoteStatus();
        if (msg.sender != note.protocolContract) revert Types.NotPermission();
        note.status = uint8(Types.NoteStatus.DEFAULTED);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.DEFAULTED));
        return id;
    }

    /**
     * @notice Stop an active note [中文: 停止活跃的票据]
     * @dev Stops the protocol contract and changes note status to STOP [中文: 停止协议合约并将票据状态更改为STOP]
     * @param id The ID of the note to stop [中文: 要停止的票据ID]
     * @return uint64 The ID of the stopped note [中文: 已停止票据的ID]
     * @custom:permission Only contract owner can call [中文: 只有合约所有者可以调用]
     * @custom:modifier Uses onlyOwner to restrict access [中文: 使用onlyOwner限制访问]
     * @custom:modifier Uses noteExists to ensure note exists [中文: 使用noteExists确保票据存在]
     * @custom:reverts Types.InvalidNoteStatus() if note is not in ACTIVE status [中文: 如果票据不在ACTIVE状态则回滚Types.InvalidNoteStatus()]
     * @custom:emits NoteStatusChanged event with STOP status [中文: 发出包含STOP状态的NoteStatusChanged事件]
     * @custom:security Calls stopProtocol() on the protocol contract [中文: 在协议合约上调用stopProtocol()]
     */
    function stopNote(
        uint64 id
    ) external onlyOwner noteExists(id) returns (uint64) {
        Types.Note storage note = _notes[id];
        if (note.status != uint8(Types.NoteStatus.ACTIVE))
            revert Types.InvalidNoteStatus();
        IProtocolsContract(note.protocolContract).stopProtocol();
        note.status = uint8(Types.NoteStatus.STOP);
        emit NoteStatusChanged(id, uint8(Types.NoteStatus.STOP));
        return id;
    }

    /**
     * @notice Set the platform fee rate [中文: 设置平台费用率]
     * @dev Updates the platform fee rate in basis points [中文: 以基点为单位更新平台费用率]
     * @param platformFee The new platform fee rate in basis points (0-10000) [中文: 新的平台费用率，以基点为单位(0-10000)]
     * @custom:permission Only contract owner can call [中文: 只有合约所有者可以调用]
     * @custom:modifier Uses onlyOwner to restrict access [中文: 使用onlyOwner限制访问]
     * @custom:reverts Types.InvalidPlatformFee() if fee exceeds 10000 basis points [中文: 如果费用超过10000基点则回滚Types.InvalidPlatformFee()]
     * @custom:emits PlatformFeeChanged event with new fee and recipient [中文: 发出包含新费用和接收者的PlatformFeeChanged事件]
     */
    function setPlatformFee(uint256 platformFee) external onlyOwner {
        if (platformFee > 10_000) revert Types.InvalidPlatformFee();
        _platformFee = platformFee;
        emit PlatformFeeChanged(platformFee, _platformFeeRecipient);
    }

    /**
     * @notice Set the platform fee recipient address [中文: 设置平台费用接收者地址]
     * @dev Updates the address that receives platform fees [中文: 更新接收平台费用的地址]
     * @param platformFeeRecipient The new address to receive platform fees [中文: 接收平台费用的新地址]
     * @custom:permission Only contract owner can call [中文: 只有合约所有者可以调用]
     * @custom:modifier Uses onlyOwner to restrict access [中文: 使用onlyOwner限制访问]
     * @custom:reverts Types.InvalidAddress() if recipient is zero address [中文: 如果接收者为零地址则回滚Types.InvalidAddress()]
     * @custom:emits PlatformFeeChanged event with current fee and new recipient [中文: 发出包含当前费用和新接收者的PlatformFeeChanged事件]
     */
    function setPlatformFeeRecipient(
        address platformFeeRecipient
    ) external onlyOwner {
        if (platformFeeRecipient == address(0)) revert Types.InvalidAddress();
        _platformFeeRecipient = platformFeeRecipient;
        emit PlatformFeeChanged(_platformFee, platformFeeRecipient);
    }

    /**
     * @notice Get the current platform fee rate [中文: 获取当前平台费用率]
     * @dev Returns the platform fee rate in basis points [中文: 返回以基点为单位的平台费用率]
     * @return uint256 The current platform fee rate in basis points [中文: 当前平台费用率，以基点为单位]
     * @custom:permission External view function, anyone can call [中文: 外部视图函数，任何人都可以调用]
     * @custom:gas-optimization Pure view function with no state changes [中文: 纯视图函数，无状态更改]
     */
    function getPlatformFee() external view returns (uint256) {
        return _platformFee;
    }

    /**
     * @notice Get the current platform fee recipient address [中文: 获取当前平台费用接收者地址]
     * @dev Returns the address that receives platform fees [中文: 返回接收平台费用的地址]
     * @return address The current platform fee recipient address [中文: 当前平台费用接收者地址]
     * @custom:permission External view function, anyone can call [中文: 外部视图函数，任何人都可以调用]
     * @custom:gas-optimization Pure view function with no state changes [中文: 纯视图函数，无状态更改]
     */
    function getPlatformFeeRecipient() external view returns (address) {
        return _platformFeeRecipient;
    }

    /**
     * @notice Get the total number of notes in the system [中文: 获取系统中票据的总数]
     * @dev Returns the count of all notes that have been created [中文: 返回已创建的所有票据的数量]
     * @return uint256 The total number of notes [中文: 票据总数]
     * @custom:permission External view function, anyone can call [中文: 外部视图函数，任何人都可以调用]
     * @custom:gas-optimization Pure view function with no state changes [中文: 纯视图函数，无状态更改]
     * @custom:note This includes all notes regardless of their status [中文: 这包括所有票据，无论其状态如何]
     */
    function getTotalNotes() external view returns (uint256) {
        return _allNoteIds.length;
    }
}
