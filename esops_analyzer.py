import sys
import requests

def analyze_fault(log_path, rtos_name):
    try:
        with open(log_path, 'r') as file:
            crash_log = file.read()
    except Exception as e:
        return f"Failed to read crash log: {str(e)}"

    # Dynamic system prompt based on the RTOS
    system_prompt = (
        f"You are the Automated Fault Detection engine of the ESOps pipeline. "
        f"Your job is to analyze embedded systems crash dumps and terminal outputs for {rtos_name} OS running on emulated hardware. "
        f"Identify the root cause of the crash or failure (e.g., Null Pointer Dereference, Infrastructure Error, "
        f"Bus Fault) and provide concise corrective actions."
    )

    payload = {
        "model": "llama3.1:8b",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Here is the {rtos_name} terminal log:\n\n{crash_log}"}
        ],
        "stream": False
    }

    url = "http://host.docker.internal:11434/api/chat"
    
    try:
        response = requests.post(url, json=payload)
        output = response.json()
        return output['message']['content']
    except Exception as e:
        return f"ESOps Analyzer Error reaching LLaMA: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python esops_analyzer.py <path_to_log> <rtos_name>")
        sys.exit(1)
        
    log_file = sys.argv[1]
    rtos = sys.argv[2]
    
    print(f"\n=== ESOps AI Automated Fault Detection Report ({rtos}) ===")
    analysis = analyze_fault(log_file, rtos)
    print(analysis)
    print("===================================================\n")
