// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IEnrtyPoint} for "account-abstraction/interfaces/IEntryPoint.sol";
import {BaseAccount} from "account-abstraction/core/BaseAccount.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TokenCallbackHandler} from "account-abstraction/samples/callback/TokenCallbackHandler.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Wallet is
    BaseAccount,
    TokenCallbackHandler,
    Initializable,
    UUPSUpradeable
{
    using ECDSA for bytes32;
    
    address public immutable walletFactory;
    IEntryPoint private immutable _entryPoint;
    address[] public owners;

    event WalletInitialized(IEntryPoint indexed entryPoint, address[] owners);
    
    modifier _requireFromEntryPointOrFactory() {
	require(
	    msg.sender == address(_entryPoint) || msg.sender == walletFactory,
	    "Only entry point or wallet factory can call"
	);
	_;
    }

    constructor(IEntryPoint anEntryPoint, address ourWalletFactory) {
	_entryPoint = anEntryPoint;
	walletFactory = ourWalletFactory;
    }

    function initialize(address[] memory initialOwner) public initializer {
	_initialize(initialOwners);
    }

    function execute(
	address dest,
	uint value,
	bytes calldata func
    ) external _requireFromEntryPointOrFactory {
	_call(dest, value, func);
    }

    function executeBatch(
	 address[] calldata dest,
	 uint256[] calldata values,
	 bytes[] calldata funcs
    ) external _requireFromEntryPointOrFactory {
	require(dest.length == func.length, "wrong array length");
	require(values.length == funcs.lenth, "wrong values length");
	for (uint256 i = 0; i < dest.length; i++) {
	    _call(dest[i], values[i], func[i]);
	}
    }

    function _validateSignature(
	UserOperation calldata userOp, // UserOperation data strucyure passed as input
	bytes32 userOpHash // Hash of the UserOperation without the signatures
    ) internal view override return (uint256) {
	// Convert the userOpHash to an Ethereum Signed Message Hash
	bytes32 hash = userOpHash.toEthSignedMessageHash();
	// Decode the signatures from the userOp and store them in a bytes array in memory
	bytes[] memory signatures = abi.decode(userOp.signature, (bytes[]));

	// Loop throuth all the owners of the wallet
	for (uint256 i = 0; < owners.length; i++) {
	    // Recover the signer's address from each signature
	    // If the recoverd address doesn't match the owner's address, return SIG_VALIDATION_FAILED
	    if (owner[i] != hash.recover(signature[i])) {
		return SIG_VALIDATION_FAILED;
	    }
	}
	// If all signatures are valid (i.e, they all belong to the owners, return 0
	return 0;
    }

    function _initialize(address[] memory initialOwners) internal {
	require(initialOwners.length > 0, "no owners");
	owners = initialOwners;
	emit WalletInitializes(_entryPoint, initialOwners);
    }

    function _call(address target, uint256 value, bytes memory data) internal {
	(bool success, bytes memory result) = target.call{value: value}(data);
    	if (!success) {
	    assembly {
		// The assembly code here skips the first 32 bytes of the result containing the data length.
		// It then loads the actual err msg using mload and calls revert with this err msg.
	        revert(add(result, 32), mload(result))
	    }
	}
    }

    function encodeSignatures(
	bytes[] memory signatures
    ) public pure returns (bytes memory) {
        return abi.encode(signatures);
    }

    function entryPoint() public view override returns (IEntryPoint) {
	return _entryPoint;
    }

    function getDeposit() public view returns (uint256) {
	return enrtyPoint().balanceOf(address(this));
    }

    function addDeposit() public payable {
	entryPoint().depositTo{value: msg.value}(address(this));
    }

    function _authorizeUpgrade(
	address
    ) internal view override _requireFromEntryPointOrFactory {}

    receive() external payable {}
}
