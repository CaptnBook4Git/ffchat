# Fix Issue #4

> **Stand:** 7.2.2026

# Contact Circles Feature

## What is it?
Contact Circles is a contact organization feature that allows users to group their Matrix contacts into named circles (e.g., "Family", "Work", "Friends") for easier management and targeted communication.

## Key Features
- **Circle Management**: Create, rename, and delete circles from Settings
- **Member Management**: Add or remove contacts from circles
- **Quick Add**: Add any user to a circle directly from their profile dialog
- **Invitation Filtering**: Filter contacts by circle when selecting invitation recipients

## How to Use

### Creating a Circle
1. Go to **Settings** → **Circles**
2. Tap the **+** button
3. Enter a circle name and confirm

### Adding Contacts to a Circle
**Method 1 - From Circle Detail:**
1. Go to Settings → Circles → [Circle Name]
2. Tap "Add Members"
3. Select contacts to add

**Method 2 - From User Profile:**
1. Tap on any user's avatar to open their profile
2. Tap "Add to Circle"
3. Select which circle(s) to add them to

### Using Circles for Invitations
1. When inviting users to a room, tap the circle filter chips at the top
2. Select one or more circles to filter the contact list
3. Only contacts in the selected circles will be shown

## Technical Notes
- Circles are stored in your Matrix account data (synced across devices)
- No data is shared with other users - circles are completely private
- Circles use Matrix user IDs, so they work across all federated servers

---

*Generated automatically for Issue #4*

