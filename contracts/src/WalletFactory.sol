// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {Wallet} from "./Wallet.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract WalletFactory {
    Wallet public immutable walletImplemenatation;

    constructor(IEntryPoint entryPoint) {
	walletImplementation = new Wallet(entryPoint, address(this));
    }

    function createAccount(
        address[] memory owners,
        uint256 salt
    ) external returns (Wallet) {
	// Get the counterfactual address
	address addr = getAddress(owners, salt);
	// Check if the code at the counterfactual address is a non-empty
	uint256 codeSize = addr.code.length;
	if (codeSize > 0) {
	    // If the code is anon-empty, i.e account already deployed, retun the wallet at the counterfactual address
	    return Wallet(payable(addr));
	}

	// If the code is empty, deploy a new wallet
	bytes memory walletInit = abi.encodeCall(Wallet.initialize, owner);
	ERC1967Proxy proxy = new ERC1967Proxy{salt: bytes32(salt)}(
	    address(walletImplemenattion),
	    walletInit
	);

	// Return the newly deployed Wallet
	return Wallet(payable(address(proxy)));
    }

    function getAddress(
	address[] memory owners,
	uint256 salt
    ) public view returns (address) {
	// Encode the initialized function in our wallet with the owners array is an arg into a bytes array
	bytes memory walletInit = abi.encodeCall(Wallet.initialize, owners);
	// Encode the proxyContract's constructor arguments which include the address walletImplementation and the walletInit
	bytes memory proxyConstructor = abi.encode(
	    address(walletImplementation),
	    walletInit
	);
	// Encode the creation code for ERC1967Proxy along with the encoded proxyConstructor data
	bytes memory bytecode = abi.encodePacked(
	    type(ERC1967Proxy).creationCode,
	    proxyConstructor
	);
	// Compute the keccak256 hash of the bytecode generated
	bytes32 bytecodeHash = keccak256(bytecode);
	// Use the hash and the salt to compute the counterfactual address of the proxy
	return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}
