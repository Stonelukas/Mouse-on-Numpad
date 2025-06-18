# Settings GUI Testing Checklist

## 🎯 General GUI Testing (All Tabs)

### Window Behavior

- [x] Settings window opens correctly
- [x] Window can be resized properly
- [x] Minimum size (800x600) is enforced
- [x] Window centers on screen when opened
- [x] Close button (X) works properly
- [x] GUI prevents multiple instances (flash if already open)

### Bottom Button Bar

- [x] All buttons are visible on all tabs
- [x] **Import Settings** button is clickable, ***but Feature is not implementent yet***
- [x] **Export Settings** button is clickable, ***but Feature is not implementent yet***
- [x] **Help** button is clickable
- [x] **Apply** button is clickable
- [x] **OK** button saves and closes
- [x] **Cancel** button discards changes and closes
- [x] Buttons remain in correct position when window resized

### Tab Navigation

- [x] All 7 tabs are visible and labeled correctly
- [x] Tab switching works smoothly
- [x] Content changes appropriately when switching tabs
- [x] No visual glitches when switching tabs
- [x] Current tab remains highlighted

---

## ⌨️ Tab 4: Hotkeys Tab ✅

### ListView Display

- [x] ListView shows all hotkeys with 3 columns (Action, Current, Default), **Feature Request** - Auto update List based on Hotkeys
- [x] All essential hotkeys are listed:
  - [x] Toggle Mouse Mode
  - [x] Save Mode
  - [x] Load Mode
  - [x] Undo Movement
  - [x] Toggle Status
  - [x] Reload Script
  - [x] Settings
  - [x] Secondary Monitor
  - [x] Monitor Test
  - [x] and more
- [x] Columns are properly sized and readable
- [x] ListView allows single selection
- [x] Selected item is visually highlighted

### Button Functionality

- [ ] **Edit** button: ***Feature not implemented yet***
  - [ ] Shows MsgBox when clicked with selection
  - [ ] Shows "No Selection" error when clicked without selection
- [ ] **Reset** button: ***Feature not implemented yet***
  - [ ] Shows MsgBox when clicked with selection
  - [ ] Shows "No Selection" error when clicked without selection
- [ ] **Test** button: ***Feature not implemented yet***
  - [ ] Shows test dialog when clicked with selection
  - [ ] Shows "No Selection" error when clicked without selection

### Conflict Detection

- [x] **Scan for Conflicts** button is clickable
- [x] Shows "Scanning..." status temporarily
- [x] Displays "No conflicts detected" message
- [ ] ConflictStatus text updates appropriately - not sure if this works (Don't know how to test it)

### Reset All

- [x] **Reset All** button shows confirmation dialog
- [x] Confirmation requires double confirmation
- [x] Success message shown after reset
- [ ] ***not fully implemented***

---

## 🏃 Tab 1: Movement Tab

### Movement Speed Section

- [x] Base Speed slider (1-50) works
- [x] Acceleration toggle checkbox works
- [x] Max Speed slider (5-100) enables/disables with acceleration
- [x] Acceleration Rate slider (1-10) enables/disables with acceleration
- [x] All sliders show current values

### Movement Preview

- [x] Preview area displays correctly
- [x] Live preview updates when settings change
- [x] Grid pattern is visible
- [x] Movement visualization is smooth

### Movement Mode

- [x] Normal mode radio button works
- [x] Precision mode radio button works
- [x] Fast mode radio button works
- [x] Mode changes affect preview

### Scroll Settings

- [x] Scroll Speed slider (1-10) works
- [x] Smooth Scrolling checkbox works
- [x] Values display correctly

---

## 📍 Tab 2: Positions Tab

### Position List

- [x] ListView displays saved positions correctly
- [x] Columns show: Name, X, Y, Monitor, Created
- [x] List supports selection
- [x] Empty state shows appropriate message

### Action Buttons

- [x] **Save Current** button opens save dialog
- [x] **Go to Position** moves mouse when position selected
- [x] **Go to Position** shows error when no selection
- [x] **Delete** removes selected position with confirmation
- [x] **Delete** shows error when no selection
- [x] **Clear All** shows confirmation and clears list

### Import/Export

- [x] **Import Positions** opens file dialog
- [x] **Export Positions** saves to file
- [x] Import validates file format
- [x] Export includes all position data

### Monitor Tools

- [x] **Test Monitors** button opens monitor test
- [x] Monitor dropdown shows all available monitors
- [x] Current monitor display is accurate

### Backup/Restore

- [x] **Create Backup** saves current positions
- [x] **Restore Backup** loads saved positions
- [x] Backup confirmation shows file location

---

## 🎨 Tab 3: Visuals Tab

### Status Indicator

- [ ] Position dropdown shows all options (corners + center) - What Dropdown?? ***Feature not implemented yet***
- [ ] Size slider (Small/Medium/Large) works- ***Feature not implemented yet***
- [ ] Opacity slider (0-100%) works - ***Feature not implemented yet***
- [ ] Always on Top checkbox works - ***Feature not implemented yet***
- [ ] Test Position button shows preview- ***Feature not implemented yet***

### Tooltip Settings

- [ ] Show Tooltips checkbox enables/disables section ***Feature not implemented yet***
- [ ] Position dropdown works ***Feature not implemented yet***
- [ ] Duration slider (500-5000ms) works ***Feature not implemented yet***
- [ ] Fade Effect checkbox works ***Feature not implemented yet***
- [ ] Test Tooltip button shows sample ***Feature not implemented yet***

### Audio Feedback

- [x] Enable Sounds checkbox enables/disables section
- [ ] Volume slider (0-100%) works ***Feature not implemented yet***
- [x] Test buttons play sounds:
  - [ ] Mode Change sound ***Feature not implemented yet***
  - [ ] Position Saved sound ***Feature not implemented yet***
  - [ ] Error sound ***Feature not implemented yet***

### Color Theme

- [x] Theme dropdown shows all themes
- [x] Preview updates when theme selected
- [ ] Custom theme colors can be selected (if enabled) ***Feature not implemented yet***

---

## ⚡ Tab 5: Advanced Tab

### Performance Settings

- [ ] Low Memory Mode checkbox works ***Feature not fully implemented yet***
- [ ] Update Frequency dropdown (Normal/Fast/Turbo) works ***Feature not fully implemented yet***
- [ ] Multi-threading checkbox works (if available) ***Feature not fully implemented yet***

### Logging

- [ ] Enable Logging checkbox works ***Feature not fully implemented yet***
- [ ] Log Level dropdown (Debug/Info/Warning/Error) works ***Feature not fully implemented yet***
- [ ] **View Logs** opens log file ***Feature not fully implemented yet***
- [ ] **Clear Logs** removes log file with confirmation ***Feature not fully implemented yet***

### Advanced Options

- [ ] Start with Windows checkbox works ***Feature not fully implemented yet***
- [ ] Run as Administrator checkbox shows UAC info ***Feature not fully implemented yet***
- [ ] Check for Updates dropdown works ***Feature not fully implemented yet***
- [ ] Beta Features checkbox enables experimental options ***Feature not fully implemented yet***

### Danger Zone

- [ ] **Reset to Defaults** shows confirmation ***Feature not fully implemented yet***
- [ ] **Clear All Data** shows double confirmation ***Feature not fully implemented yet***
- [ ] Reset actually restores default settings ***Feature not fully implemented yet***

---

## 👤 Tab 6: Profiles Tab

### Profile List

- [x] ListView shows existing profiles
- [ ] Default profile is marked - Only Text ***"Current Profile: Default"**
- [ ] Active profile is highlighted

### Profile Actions

- [ ] **New Profile** creates profile with name dialog ***Feature not implemented yet***
- [ ] **Duplicate** copies selected profile ***Feature not implemented yet***
- [ ] **Rename** allows profile renaming ***Feature not implemented yet***
- [ ] **Delete** removes profile with confirmation ***Feature not fully implemented yet***
- [ ] **Set as Default** updates default profile ***Feature not implemented yet***

### Auto-Switch Rules

- [ ] Rules list shows for selected profile ***Feature not implemented yet***
- [ ] **Add Rule** opens rule configuration ***Feature not implemented yet***
- [ ] **Edit Rule** modifies existing rule ***Feature not implemented yet***
- [ ] **Remove Rule** deletes with confirmation ***Feature not implemented yet***
- [ ] Rule types work: Application, Time, Network ***Feature not implemented yet***

### Import/Export

- [x] **Import Profile** loads .ini file ***Feature not fully implemented yet***
- [x] **Export Profile** saves selected profile ***Feature not fully implemented yet***
- [ ] Import validates profile format

---

## ℹ️ Tab 7: About Tab

### Version Information

- [x] Current version displays correctly
- [ ] Build date is shown
- [x] AutoHotkey version is displayed
- [ ] License type is shown

### System Information

- [ ] Windows version detected correctly ***Feature not fully implemented yet*** shows "Operating System: 10.0.26100"
- [ ] Monitor count is accurate ***Feature not implemented yet***
- [ ] System uptime displays ***Feature not implemented yet***
- [ ] Memory usage shown ***Feature not implemented yet***

### Actions

- [x] **Check for Updates** button works - for now no online version to check for new versions
- [ ] **View Changelog** opens changelog ***Feature not implemented yet***
- [ ] **Report Issue** opens GitHub/email ***Feature not fully implemented yet***
- [ ] **View Documentation** opens help ***Feature not fully implemented yet***

### Links

- [ ] GitHub repository link works ***Feature not implemented yet***
- [ ] Author website link works ***Feature not implemented yet***
- [ ] Donate button works (if present) ***Feature not implemented yet***
- [ ] License link shows license text ***Feature not implemented yet***

---

## 🔄 Integration Testing

### Data Persistence

***not in all Tabs***

- [x] Settings persist after clicking **OK**
- [x] Settings persist after clicking **Apply**
- [x] Settings revert after clicking **Cancel**
- [x] Settings survive application restart

### Tab Validation

- [x] Invalid inputs show error messages - ***not everywhere***
- [x] Tab with errors is highlighted - Opens tab with error automatically
- [x] Cannot apply settings with validation errors
- [x] Error messages are clear and helpful

### Performance

- [x] No lag when switching tabs
- [x] Controls respond immediately
- [x] Window resizing is smooth
- [ ] No memory leaks after extended use

### Edge Cases

- [ ] Handles missing config file gracefully
- [ ] Handles corrupted settings file
- [x] Works with multiple monitors
- [ ] Works with different DPI settings
- [ ] Handles read-only config directory

---

## 📝 Test Execution Notes

### Priority Order

1. **Critical**: Window behavior, button functionality, data persistence
2. **High**: Tab-specific features, validation, error handling
3. **Medium**: Visual feedback, tooltips, preview features
4. **Low**: Cosmetic issues, minor UI polish

### Test Environment

- [ ] Test on Windows 10
- [x] Test on Windows 11
- [x] Test with single monitor
- [x] Test with multiple monitors
- [ ] Test with different screen resolutions
- [ ] Test with admin and non-admin accounts

### Regression Testing
After any code changes:

- [ ] Re-test affected tab completely
- [ ] Test tab switching
- [ ] Test data persistence
- [ ] Test window behavior
- [ ] Check for memory leaks
