// Sources flattened with hardhat v2.28.6 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File @openzeppelin/contracts/access/Ownable.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @openzeppelin/contracts/utils/Pausable.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File @openzeppelin/contracts/utils/StorageSlot.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}

// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.5.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * IMPORTANT: Deprecated. This storage-based reentrancy guard will be removed and replaced
 * by the {ReentrancyGuardTransient} variant in v6.0.
 *
 * @custom:stateless
 */
abstract contract ReentrancyGuard {
    using StorageSlot for bytes32;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev A `view` only version of {nonReentrant}. Use to block view functions
     * from being called, preventing reading from inconsistent contract state.
     *
     * CAUTION: This is a "view" modifier and does not change the reentrancy
     * status. Use it only on view functions. For payable or non-payable functions,
     * use the standard {nonReentrant} modifier instead.
     */
    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        _nonReentrantBeforeView();

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorageSlot().getUint256Slot().value = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyGuardStorageSlot().getUint256Slot().value == ENTERED;
    }

    function _reentrancyGuardStorageSlot() internal pure virtual returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }
}

// File contracts/BrixRegistry.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title BrixRegistry
 * @notice Unified on-chain registry for BRIX: IPFS fee payment, brick minting, and donations.
 * @dev Runs on Polygon L2. Optimized for low gas usage.
 *
 * Flows:
 *   1. payForIPFS  ΓåÆ user pays fee ΓåÆ event emitted ΓåÆ backend uploads to IPFS
 *   2. mint        ΓåÆ user creates on-chain brick (must have paid IPFS first)
 *   3. donate      ΓåÆ funds split between creator & platform ΓåÆ backend logs
 */
contract BrixRegistry is Ownable, ReentrancyGuard, Pausable {
    // Custom Errors
    error InsufficientFee(uint256 required, uint256 sent);
    error AlreadyPaid();
    error AlreadyMinted();
    error InvalidBrickId();
    error InvalidCID();
    error NotPaidForIPFS();
    error ZeroDonation();
    error ZeroWithdrawal();
    error TransferFailed();
    error InvalidAddress();
    error InvalidPercentage();
    error InvalidFee();
    error NoStuckFunds();

    // Constants
    uint256 public constant MAX_PLATFORM_FEE_PERCENT = 40;
    uint256 public constant MAX_IPFS_FEE = 10 ether;

    // State
    struct Brick {
        address creator;
        string ipfsCid;
        uint256 totalDonated;
    }

    mapping(uint256 => Brick) public bricks;
    uint256 public brickCount;

    /// @notice Tracks which brickIds have already paid for IPFS (prevents MEV frontrunning)
    /// @dev Maps keccak256(abi.encodePacked(brickId, msg.sender)) => bool
    mapping(bytes32 => bool) public paidForIpfs;

    /// @notice Tracks which specific bricks have already been minted to prevent double-minting
    mapping(bytes32 => bool) public isMinted;

    /// @notice Pull-payment mapping for safe donation withdrawals (prevents blocking)
    mapping(address => uint256) public pendingWithdrawals;

    address public platformFeeAddress;
    uint256 public ipfsFee; // fee in wei for IPFS distribution
    uint256 public platformFeePercent = 10; // default 10%, max 40%

    /// @notice Accumulated IPFS fees available for owner withdrawal
    uint256 public collectedIpfsFees;

    /// @notice Total donations currently pending withdrawal (artist + platform)
    uint256 public totalPendingDonations;

    // Events
    /// @notice Emitted when a user pays for IPFS distribution (no state stored)
    event PaidForIPFS(address indexed user, bytes32 brickId);

    /// @notice Emitted when a new brick is minted on-chain
    event BrickCreated(uint256 indexed id, address indexed creator, string ipfsCid);

    /// @notice Emitted when a donation is made to a brick
    event Donated(
        uint256 indexed brickId,
        address indexed donor,
        uint256 amount,
        uint256 artistAmount,
        uint256 platformAmount
    );

    /// @notice Emitted when IPFS fee is updated
    event IpfsFeeUpdated(uint256 oldFee, uint256 newFee);

    /// @notice Emitted when platform fee percent is updated
    event PlatformFeeUpdated(uint256 oldPercent, uint256 newPercent);

    /// @notice Emitted when platform fee address is updated
    event PlatformFeeAddressUpdated(address oldAddress, address newAddress);

    /// @notice Emitted when the owner withdraws accumulated IPFS fees
    event FeesWithdrawn(address owner, uint256 amount);

    /// @notice Emitted when a creator or platform withdraws their accumulated donations
    event DonationWithdrawn(address account, uint256 amount);

    /// @notice Emitted when the owner withdraws stuck funds
    event StuckFundsWithdrawn(address owner, uint256 amount);

    // Constructor
    /**
     * @param _platformFeeAddress Address that receives the platform share of donations
     * @param _ipfsFee Initial fee (wei) users pay for IPFS distribution
     */
    constructor(address _platformFeeAddress, uint256 _ipfsFee) Ownable(msg.sender) {
        if (_platformFeeAddress == address(0)) revert InvalidAddress();
        platformFeeAddress = _platformFeeAddress;
        ipfsFee = _ipfsFee;
    }

    // FLOW 1 payForIPFS

    /**
     * @notice User pays the IPFS fee. Backend listens for the event and uploads to IPFS.
     * @param brickId The off-chain brick UUID representation (bytes32).
     * @dev Bound to the msg.sender to prevent MEV front-running.
     *      Fee is tracked separately and can be withdrawn by the owner.
     *      Excess ETH is refunded to the sender.
     */
    function payForIPFS(bytes32 brickId) external payable nonReentrant whenNotPaused {
        if (brickId == bytes32(0)) revert InvalidBrickId();
        if (msg.value < ipfsFee) revert InsufficientFee(ipfsFee, msg.value);

        bytes32 id = keccak256(abi.encodePacked(brickId, msg.sender));
        if (paidForIpfs[id]) revert AlreadyPaid();

        paidForIpfs[id] = true;
        collectedIpfsFees += ipfsFee; // Only track the actual fee

        // Refund excess ETH
        if (msg.value > ipfsFee) {
            (bool ok, ) = payable(msg.sender).call{ value: msg.value - ipfsFee }("");
            if (!ok) revert TransferFailed();
        }

        emit PaidForIPFS(msg.sender, brickId);
    }

    // FLOW 2 Onchain Mint

    /**
     * @notice Mint a brick on-chain after IPFS distribution is complete.
     * @param brickId The off-chain brick representation (bytes32) that was paid for.
     * @param ipfsCid The IPFS CID of the brick metadata
     * @dev Caller must have paid for IPFS for this specific brickId.
     *      Stores minimal data: creator address, ipfsCid, totalDonated (0).
     */
    function mint(bytes32 brickId, string calldata ipfsCid) external nonReentrant whenNotPaused {
        if (brickId == bytes32(0)) revert InvalidBrickId();
        if (bytes(ipfsCid).length == 0) revert InvalidCID();

        bytes32 paymentId = keccak256(abi.encodePacked(brickId, msg.sender));
        if (isMinted[paymentId]) revert AlreadyMinted();
        if (!paidForIpfs[paymentId]) revert NotPaidForIPFS();

        isMinted[paymentId] = true;
        delete paidForIpfs[paymentId]; // Free storage slot to refund gas

        uint256 id = ++brickCount;

        bricks[id] = Brick({ creator: msg.sender, ipfsCid: ipfsCid, totalDonated: 0 });

        emit BrickCreated(id, msg.sender, ipfsCid);
    }

    // FLOW 3 Donate

    /**
     * @notice Donate MATIC to a minted brick. Funds are split between the
     *         creator and the platform according to `platformFeePercent`.
     * @param brickId On-chain brick ID (sequential, starts at 1)
     * @dev Uses Pull-Payment pattern. Funds are accumulated in pendingWithdrawals
     *      to prevent blocking if the creator is a contract that cannot receive ETH.
     */
    function donate(uint256 brickId) external payable nonReentrant whenNotPaused {
        if (brickId == 0 || brickId > brickCount) revert InvalidBrickId();
        if (msg.value == 0) revert ZeroDonation();

        Brick storage brick = bricks[brickId];

        // Platform takes percent (truncates down). Artist gets the rest (keeps the 1 wei remainder if any).
        uint256 platformAmount = (msg.value * platformFeePercent) / 100;
        uint256 artistAmount = msg.value - platformAmount;

        brick.totalDonated += msg.value;

        // Pull-payment: add to pending withdrawals instead of tracking failures
        pendingWithdrawals[platformFeeAddress] += platformAmount;
        pendingWithdrawals[brick.creator] += artistAmount;
        totalPendingDonations += msg.value;

        emit Donated(brickId, msg.sender, msg.value, artistAmount, platformAmount);
    }

    /**
     * @notice Allows a user (artist or platform) to withdraw their accumulated donations.
     * @dev Safe pull-payment withdrawal function. Can be called even when paused to rescue funds.
     */
    function withdrawDonation() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert ZeroWithdrawal();

        pendingWithdrawals[msg.sender] = 0;
        totalPendingDonations -= amount;

        (bool ok, ) = payable(msg.sender).call{ value: amount }("");
        if (!ok) revert TransferFailed();

        emit DonationWithdrawn(msg.sender, amount);
    }

    // Admin Functions

    /**
     * @notice Update the IPFS distribution fee
     * @dev Capped at MAX_IPFS_FEE to prevent owner abuse
     */
    function setIpfsFee(uint256 _newFee) external onlyOwner {
        if (_newFee > MAX_IPFS_FEE) revert InvalidFee();
        uint256 oldFee = ipfsFee;
        ipfsFee = _newFee;
        emit IpfsFeeUpdated(oldFee, _newFee);
    }

    /**
     * @notice Update the platform fee percentage (0 to MAX_PLATFORM_FEE_PERCENT)
     * @dev Capped at 40% platform can never take more than 40% of donations
     */
    function setPlatformFeePercent(uint256 _newPercent) external onlyOwner {
        if (_newPercent > MAX_PLATFORM_FEE_PERCENT) revert InvalidPercentage();
        uint256 oldPercent = platformFeePercent;
        platformFeePercent = _newPercent;
        emit PlatformFeeUpdated(oldPercent, _newPercent);
    }

    /**
     * @notice Update the platform fee address
     */
    function setPlatformFeeAddress(address _newAddress) external onlyOwner {
        if (_newAddress == address(0)) revert InvalidAddress();
        address oldAddress = platformFeeAddress;
        platformFeeAddress = _newAddress;
        emit PlatformFeeAddressUpdated(oldAddress, _newAddress);
    }

    /**
     * @notice Withdraw only accumulated IPFS fees (not donation funds)
     * @dev Only callable by the contract owner. Tracks fees separately for safety.
     */
    function withdrawIpfsFees() external onlyOwner {
        uint256 amount = collectedIpfsFees;
        if (amount == 0) revert ZeroWithdrawal();

        collectedIpfsFees = 0;

        (bool ok, ) = payable(msg.sender).call{ value: amount }("");
        if (!ok) revert TransferFailed();

        emit FeesWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Emergency: withdraw ALL stuck funds (if bug causes funds to be trapped)
     * @dev Only withdraws balance that is not accounted for by pending donations and IPFS fees.
     */
    function withdrawStuckFunds() external onlyOwner {
        uint256 accountedFor = totalPendingDonations + collectedIpfsFees;
        uint256 balance = address(this).balance;

        if (balance <= accountedFor) revert NoStuckFunds();

        uint256 stuck = balance - accountedFor;

        (bool ok, ) = payable(msg.sender).call{ value: stuck }("");
        if (!ok) revert TransferFailed();

        emit StuckFundsWithdrawn(msg.sender, stuck);
    }

    /**
     * @notice Pause the contract (stops payForIPFS, mint, donate). Withdrawals still work.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Fallback to accept unstructured ETH transfers
     * @dev Any ETH sent here can be rescued via withdrawStuckFunds.
     *      No fallback() intentional: reject ETH sent via unknown function calls.
     */
    receive() external payable {}

    //View Helpers

    /**
     * @notice Get brick details
     */
    function getBrick(
        uint256 brickId
    ) external view returns (address creator, string memory ipfsCid, uint256 totalDonated) {
        if (brickId == 0 || brickId > brickCount) revert InvalidBrickId();
        Brick storage b = bricks[brickId];
        return (b.creator, b.ipfsCid, b.totalDonated);
    }

    /**
     * @notice Check if a specific address has paid for a specific brickId
     * @dev Returns false if the user has already minted (paidForIpfs is deleted post-mint).
     *      Use hasMinted() to check mint status separately.
     */
    function hasPaid(bytes32 brickId, address user) external view returns (bool) {
        return paidForIpfs[keccak256(abi.encodePacked(brickId, user))];
    }

    /**
     * @notice Check if a brickId has already been minted by a specific user
     */
    function hasMinted(bytes32 brickId, address user) external view returns (bool) {
        return isMinted[keccak256(abi.encodePacked(brickId, user))];
    }
}
