// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {ToDoList} from "../src/ToDoList.sol";

contract DeployToDoList is Script {
    function run() external returns (ToDoList) {
        // vm.startBroadcast() le dice a Forge que las siguientes
        // transacciones deben ser enviadas a la red.
        vm.startBroadcast();

        // Esta línea despliega tu contrato.
        ToDoList toDoList = new ToDoList();

        // vm.stopBroadcast() detiene el envío de transacciones.
        vm.stopBroadcast();

        return toDoList;
    }
}