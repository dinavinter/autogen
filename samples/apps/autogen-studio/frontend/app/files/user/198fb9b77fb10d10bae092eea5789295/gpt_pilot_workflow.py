# filename: gpt_pilot_workflow.py

# Define the workflow and agent specs for the GPT Pilot machine
workflow = {
    "name": "GPT Pilot",
    "agents": [
        {
            "name": "Product Owner agent",
            "role": "Understand requirements and write user stories",
            "tasks": [
                {
                    "name": "Ask questions",
                    "description": "Ask a couple of questions to understand the requirements better."
                },
                {
                    "name": "Write user stories",
                    "description": "Write user stories and ask you if they are all correct."
                }
            ]
        },
        {
            "name": "Architect agent",
            "role": "Decide on technologies to be used",
            "tasks": [
                {
                    "name": "Write up technologies",
                    "description": "Write up technologies that will be used for the app."
                }
            ]
        },
        {
            "name": "DevOps agent",
            "role": "Check and install necessary technologies",
            "tasks": [
                {
                    "name": "Check technologies",
                    "description": "Check if all technologies are installed on the machine and install them if not."
                }
            ]
        },
        {
            "name": "Tech Lead agent",
            "role": "Write up development tasks",
            "tasks": [
                {
                    "name": "Write development tasks",
                    "description": "Write up development tasks that the Developer must implement."
                }
            ]
        },
        {
            "name": "Developer agent",
            "role": "Describe implementation steps",
            "tasks": [
                {
                    "name": "Describe implementation",
                    "description": "Take each task and write up what needs to be done to implement it."
                }
            ]
        },
        {
            "name": "Code Monkey agent",
            "role": "Implement changes",
            "tasks": [
                {
                    "name": "Implement changes",
                    "description": "Take the Developer's description and the existing file and implement the changes."
                }
            ]
        }
    ]
}

# Print the workflow and agent specs
for agent in workflow["agents"]:
    print(f"Agent: {agent['name']}")
    print(f"Role: {agent['role']}")
    for task in agent["tasks"]:
        print(f"Task: {task['name']}")
        print(f"Description: {task['description']}")
    print("\n")