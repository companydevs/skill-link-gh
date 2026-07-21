@echo off
echo ========================================
echo  REMOVE API KEYS FROM GIT HISTORY
echo ========================================
echo.
echo This script will remove exposed API keys from Git history.
echo WARNING: This will rewrite Git history!
echo.
echo Before running this script:
echo 1. Create a backup of your repository
echo 2. Ensure all team members have pushed their changes
echo 3. Notify team that they will need to re-clone the repository
echo.
pause

echo.
echo Creating passwords file...
echo AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc > passwords.txt
echo AIzaSyBQBpe_XlRPEcuTZKTz3YNJ8QwvnPLdAoc >> passwords.txt
echo AIzaSyAz-79s5Gi7H1iA61awMSC47KemjDmBLFk >> passwords.txt

echo.
echo Option 1: Use BFG Repo-Cleaner (Recommended)
echo ---------------------------------------------
echo.
echo 1. Download BFG from https://rtyley.github.io/bfg-repo-cleaner/
echo 2. Place bfg.jar in this directory
echo 3. Run these commands:
echo.
echo    git clone --mirror https://github.com/companydevs/skill-link-gh.git repo-backup.git
echo    java -jar bfg.jar --replace-text passwords.txt repo-backup.git
echo    cd repo-backup.git
echo    git reflog expire --expire=now --all
echo    git gc --prune=now --aggressive
echo    git push --force
echo.
echo.
echo Option 2: Manual Git Filter (Alternative)
echo ------------------------------------------
echo.
echo Run these Git commands:
echo    git filter-branch --tree-filter "find . -name '*.dart' -o -name '*.xml' -o -name '*.json' | xargs sed -i 's/AIzaSyCeGxqoYlPBqAXDX5JMp89wwJfmQEM-ZWc/REDACTED_MAPS_KEY/g'" --all
echo    git push origin --force --all
echo    git push origin --force --tags
echo.
pause
