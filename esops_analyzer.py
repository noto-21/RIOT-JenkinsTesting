import sys
import requests
import json

def analyze_fault(log_path):
    # Read the raw crash output from the Zephyr test execution
    try:
        with open(log_path, 'r') as file:
            crash_log = file.read()
    except Exception as e:
        return f"Failed to read crash log: {str(e)}"

    # Craft a highly specific system prompt tailored to ESOps architecture
    system_prompt = (
        "You are the Automated Fault Detection engine of the ESOps pipeline. "
        "Your job is to analyze embedded systems crash dumps, register state outputs, "
        "or compiler failures from Zephyr RTOS running on emulated hardware. "
        "Identify the root cause of the crash (e.g., Null Pointer Dereference, Stack Overflow, "
        "Bus Fault) and provide concise corrective actions for the C codebase."
    )

    # Construct the payload for local LLaMA instance
    payload = {
        "model": "llama3.1:8b",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Here is the Zephyr crash log:\n\n{crash_log}"}
        ],
        "stream": False
    }

    # Query local LLaMA via Ollama's REST API
    # Note: Using host.docker.internal to allow the Docker container to look outward to the host machine
    url = "http://host.docker.internal:11434/api/chat"
    
    try:
        response = requests.post(url, json=payload)
        output = response.json()
        return output['message']['content']
    except Exception as e:
        return f"ESOps Analyzer Error reaching LLaMA: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python esops_analyzer.py <path_to_log>")
        sys.exit(1)
        
    log_file = sys.argv[1]
    print("\n=== ESOps AI Automated Fault Detection Report ===")
    analysis = analyze_fault(log_file)
    print(analysis)
    print("===================================================\n")
