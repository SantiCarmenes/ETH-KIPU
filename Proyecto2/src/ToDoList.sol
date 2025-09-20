///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract ToDoList {
    
    struct Task {
        string description;
        bool completed;
        uint256 timestamp;
    }

    Task[] private s_tasks;

    event ToDoList_TaskCreated(Task task);
    event ToDoList_TaskCompleted(Task task);
    event ToDoList_TaskDeleted(string description, uint256 timestamp);

    function createTask(string memory m_description) external {
        Task memory newTask = Task({
            description: m_description,
            completed: false,
            timestamp: block.timestamp
        });

        s_tasks.push(newTask);

        emit ToDoList_TaskCreated(newTask);
    }

    function getTask(uint256 m_index) external view returns (Task memory m_task) {
        m_task = s_tasks[m_index];

        return m_task;
    }

    function completeTask(uint256 m_index) external {
        s_tasks[m_index].completed = true;

        emit ToDoList_TaskCompleted(s_tasks[m_index]);
    }

    function deleteTask(string memory m_description) external {
        uint256 arrayLength = s_tasks.length;

        for (uint256 i = 0; i < arrayLength; i++) {
            if(keccak256(abi.encodePacked(s_tasks[i].description)) == keccak256(abi.encodePacked(m_description))) {
                s_tasks[i] = s_tasks[arrayLength - 1];
                s_tasks.pop();
                emit ToDoList_TaskDeleted(m_description, block.timestamp);
                return;
            }
        }
    }
}