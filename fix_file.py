import re

with open("lib/features/teacher/screens/teacher_dashboard_screen.dart", "r") as f:
    content = f.read()

# Find class _ClassPerformanceCard extends StatefulWidget { ...
# and class _ClassPerformanceCardState extends State<_ClassPerformanceCard> { ... }
start_idx = content.find("class _ClassPerformanceCard extends StatefulWidget {")

if start_idx != -1:
    # We need to find the matching closing brace for _ClassPerformanceCardState
    # It starts at: class _ClassPerformanceCardState extends State<_ClassPerformanceCard> {
    state_start_idx = content.find("class _ClassPerformanceCardState extends State<_ClassPerformanceCard> {", start_idx)
    
    # Simple brace counting
    brace_count = 0
    in_class = False
    end_idx = -1
    for i in range(state_start_idx, len(content)):
        if content[i] == '{':
            brace_count += 1
            in_class = True
        elif content[i] == '}':
            brace_count -= 1
        
        if in_class and brace_count == 0:
            end_idx = i + 1
            break
            
    if end_idx != -1:
        extracted = content[start_idx:end_idx]
        new_content = content[:start_idx] + content[end_idx:]
        new_content += "\n\n" + extracted + "\n"
        
        with open("lib/features/teacher/screens/teacher_dashboard_screen.dart", "w") as f:
            f.write(new_content)
        print("Successfully extracted and appended.")
    else:
        print("Could not find end of state class.")
else:
    print("Could not find start of class.")
