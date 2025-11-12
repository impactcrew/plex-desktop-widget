# Lessons Learned - Critical Mistakes to Avoid

## File Cleanup Operations

### NEVER delete files without explicit user approval
- **What happened**: Deleted CHECK1.png and other test files during cleanup without asking
- **Impact**: Lost the original logo file that was needed later
- **Rule**: Always ask which files to keep/delete during cleanup operations, especially image files and test assets

### NEVER overwrite files without backing them up first
- **What happened**: Overwrote Logo.png by converting AppIcon.svg without checking what was there
- **Impact**: Destroyed the user's carefully created logo file
- **Rule**: Always read/backup a file before overwriting it, especially when the filename suggests it's important

### Always check what you're about to delete/overwrite
- **What happened**: Used Logo.png as output without checking if it already existed
- **Impact**: Lost hours of work
- **Rule**: Use `ls -la` to check if a file exists before using it as an output target

## Systematic Renaming Operations

### When renaming, find ALL instances first
- **What happened**: Renamed PlexWidget directory but missed:
  - PlexWidget.xcodeproj
  - PlexWidget/ subfolder
  - PlexWidgetApp.swift
  - PlexWidget.entitlements
  - PlexWidget.xcscheme
- **Impact**: User had to manually point out each missed file
- **Rule**: Before starting a rename operation:
  1. Run `find . -name "*OldName*"` to find ALL files/folders
  2. Run `grep -r "OldName"` to find ALL text references
  3. Create a checklist of everything to rename
  4. Execute systematically

### Example of proper systematic renaming:
```bash
# Step 1: Find all files
find . -name "*PlexWidget*" -not -path "*/build/*"

# Step 2: Find all text references
grep -r "PlexWidget" --include="*.swift" --include="*.md" --include="*.plist"

# Step 3: Rename files systematically
# Step 4: Update text references
# Step 5: Test/verify
# Step 6: Commit
```

## Icon/Image File Management

### Understand which icon file is which
- **What happened**: Confused AppIcon.svg with the actual logo after working with orange gradient icons for 4 hours
- **Impact**: Generated the wrong icon
- **Rule**:
  - AppIcon.svg = macOS app icon (rounded square with background)
  - Logo.png = Project logo for GitHub/README
  - dmg-volume-icon.icns = Orange gradient logo source
  - dmg-file-icon.icns = Dark version for DMG window

### Always know your icon sources
- **What happened**: Didn't remember that dmg-volume-icon.icns contained the orange gradient logo
- **Impact**: Wasted time trying to recreate it
- **Rule**: Document what each icon file is for in the session

## Ask Before Acting on Ambiguous Tasks

### When cleanup is requested, ask for specifics
- **What happened**: "Clean up the project" → deleted everything indiscriminately
- **Rule**: Ask "Which types of files should I remove? Debug files? Test files? Documentation?"

### When told to add something "at the top", clarify where
- **What happened**: Added disclaimer in wrong location when one already existed
- **Rule**: Search for existing similar content first, then ask where to add if unclear

## Proactive Problem Solving

### Think about consequences before executing
- **What happened**: Multiple times didn't think about:
  - "Will this overwrite something important?"
  - "Are there other files with similar names?"
  - "Does this already exist somewhere?"
- **Rule**: Pause and think before any destructive operation

### When a task seems too simple, it probably isn't
- **What happened**: "Rename PlexWidget" seemed simple but had 8+ instances across the project
- **Rule**: Complex projects have complex dependencies - always search comprehensively

## Memory and Context

### Don't forget what you've been working with
- **What happened**: Worked with orange gradient logo for 4 hours, then forgot what it was
- **Impact**: Created wrong icon
- **Rule**: Keep track of key files and their purposes throughout the session

### Read your own work
- **What happened**: Created icon files but didn't remember their names or locations
- **Rule**: When asked "where is X", search your recent actions and file operations first

## Summary Rules

1. **NEVER delete files without asking first**
2. **NEVER overwrite existing files without backing them up**
3. **ALWAYS search comprehensively before renaming operations**
4. **ALWAYS verify file existence before using as output**
5. **THINK before executing destructive operations**
6. **ASK when ambiguous - don't guess**
7. **REMEMBER what you've been working with**
8. **CHECK for existing implementations before creating duplicates**

These mistakes cost the user 4+ hours of frustration. Don't repeat them.
