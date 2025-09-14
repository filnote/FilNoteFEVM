// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import { Script } from "@forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { FilNoteContract } from "../src/FilNote.sol";

contract DeployFilNote is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);
   

        FilNoteContract filNote = new FilNoteContract();
        
        console.log("FilNoteContract deployed at:", address(filNote));
        console.log("Owner:", filNote.owner());
        
        
        vm.stopBroadcast();

        console.log("Deployment completed successfully!");
        console.log("Contract address:", address(filNote));
    }
}
