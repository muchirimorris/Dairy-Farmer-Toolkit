import os

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    changed = False

    # Replace user.uid with user.id
    if "user.uid" in content:
        content = content.replace("user.uid", "user.id")
        changed = True
        
    if "user!.uid" in content:
        content = content.replace("user!.uid", "user!.id")
        changed = True

    # Fix finance repository methods
    if "syncFinancialRecords" in content:
        content = content.replace("syncFinancialRecords", "syncFinances")
        changed = True
    if "addFinancialRecord" in content:
        content = content.replace("addFinancialRecord", "addRecord")
        changed = True
    if "deleteFinancialRecord" in content:
        content = content.replace("deleteFinancialRecord", "deleteRecord")
        changed = True

    if changed:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk('lib/src/screens'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
