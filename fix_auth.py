import os

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    changed = False

    # Replace FirebaseAuth imports
    if "import 'package:firebase_auth/firebase_auth.dart';" in content:
        content = content.replace("import 'package:firebase_auth/firebase_auth.dart';", 
        "import 'package:provider/provider.dart';\nimport '../../services/auth_service.dart';")
        changed = True

    if "import 'package:cloud_firestore/cloud_firestore.dart';" in content:
        content = content.replace("import 'package:cloud_firestore/cloud_firestore.dart';", "")
        changed = True

    # Replace FirebaseAuth usage
    if "FirebaseAuth.instance.currentUser" in content:
        content = content.replace("FirebaseAuth.instance.currentUser", "Provider.of<AuthService>(context, listen: false).currentUser")
        changed = True

    if "FirebaseAuth.instance.signOut()" in content:
        content = content.replace("FirebaseAuth.instance.signOut()", "Provider.of<AuthService>(context, listen: false).logout()")
        changed = True

    if changed:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk('lib/src/screens'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
