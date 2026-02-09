# Research Report: Circles-Based Story Visibility

## Suggested Issue Title
**[FORK] Feature: Circle-Based Story Visibility (Audience Selection for Stories)**

## Issue Type
**Feature / Enhancement**

---

## 1. Current Behavior

### Circles (implemented in fork)
Circles are client-side contact groups stored in Matrix account data under event type `im.ffchat.circles`. They are **completely local to the user** — other users never see your circle names or memberships.

**Core files:**
| File | Lines | Purpose |
|------|-------|---------|
| `lib/utils/circles_config.dart` | L1-219 | Circle model (`Circle` class), `CirclesConfigExtension` on `Client` with CRUD methods: `circles`, `circlesForUser(userId)`, `createCircle`, `renameCircle`, `deleteCircle`, `addMemberToCircle`, `removeMemberFromCircle` |
| `lib/pages/circles/circles_list.dart` | L1-87 | Circle list page controller |
| `lib/pages/circles/circles_list_view.dart` | L1-78 | Circle list UI |
| `lib/pages/circles/circle_detail.dart` | L1-135 | Circle detail page controller (member management) |
| `lib/pages/circles/circle_detail_view.dart` | L1-102 | Circle detail UI |
| `lib/config/routes.dart` | L223-233 | Routes: `/rooms/circles`, `/rooms/circles/:circleId` |
| `lib/widgets/adaptive_dialogs/user_dialog.dart` | L244-289 | Circle selection popup in user dialog |
| `lib/pages/invitation_selection/invitation_selection.dart` | L40-69 | Circle-based contact filtering (`selectCircle`, `selectedCircleId`) |
| `lib/pages/invitation_selection/invitation_selection_view.dart` | L89-109 | Circle filter chips UI |

**Key architecture detail**: Circles use `im.ffchat.circles` account data (L117 of `circles_config.dart`), meaning they sync across devices but are **invisible to other users**. The `circlesForUser(userId)` method (L125-126) already allows looking up which circles a given user belongs to.

### Stories (implemented in fork)
Stories are implemented as **dedicated Matrix rooms** with a display name prefix `story:`. Each user has one "own story room" tracked in account data `ffchat.story`.

**Core files:**
| File | Lines | Purpose |
|------|-------|---------|
| `lib/utils/story_room_extension.dart` | L1-35 | `StoryRoomExtension` on Room: `isStory` (prefix check), `storyDisplayName` |
| `lib/utils/own_story_config.dart` | L1-83 | `OwnStoryConfigExtension`: `isOwnStoryRoom`, `getOrCreateOwnStoryRoom` (creates encrypted private rooms) |
| `lib/pages/stories/stories_bar.dart` | L1-229 | Horizontal stories bar widget, add-to-story action |
| `lib/pages/stories/story_viewer.dart` | L1-637 | Full-screen story viewer with autoplay, progress, video, auto-advance |
| `lib/pages/chat_list/chat_list.dart` | L152-219 | Story room detection, own story dialog, `storyRooms` getter |
| `lib/pages/chat_list/chat_list_body.dart` | L77, L142 | StoriesBar integration |
| `lib/pages/new_group/new_group.dart` | L118-162 | `CreateGroupType.story`, `_createStory()` |
| `lib/config/routes.dart` | L166-172 | Route `/rooms/story/:roomid` |

**Key architecture detail**: Stories are regular Matrix rooms. Visibility is controlled by **room membership** — only room members can see the story content. Currently there is **no circle-based audience selection** when creating or posting to a story room.

---

## 2. Expected Behavior

When a user posts a story, they should be able to select **which Circles** can see that story. Only contacts belonging to those selected Circles should be able to view the story content. This restriction must work **cross-client** (not just in FF Chat but also in Element, etc.), meaning it must be enforced at the Matrix protocol level, not just with client-side filtering.

---

## 3. Upstream Status

### FluffyChat upstream
- **No issues found** matching "circle story" or "story visibility" in `krille-mobile/fluffychat` (the upstream repo search failed due to name/access issues, but no relevant results were found).
- FluffyChat upstream **removed its original Stories feature** (which was based on MSC3588) and does not have Circles at all.

### Fork issues (CaptnBook4Git/ffchat)
| Issue | Status | Relevance |
|-------|--------|-----------|
| **#4** (Circles) | CLOSED ✅ | Circles implementation is done. The issue mentions "circle-based audience selection" as a motivation. |
| **#28** (Group Stories) | OPEN | Related: Enabling stories within group chatrooms. Different scope (room-level stories) but shares infrastructure. |
| **#27** (Unseen stories ring) | CLOSED ✅ | Visual indicator for unseen stories. |

---

## 4. Matrix Protocol Analysis: Per-Message Visibility Options

This is the **critical question**: Can the Matrix protocol restrict which users see specific messages **within a single room**?

### Option A: Separate Story Room per Circle ⭐ **RECOMMENDED**
**How it works:** When posting a story, create/manage a dedicated story room for each Circle. Invite only the Circle's members to each room.

**Matrix mechanisms involved:**
- Room membership is the native access control in Matrix
- `preset: privateChat` (invite-only) ensures only invited users can join
- Encrypted rooms (Megolm E2EE) provide cryptographic enforcement: Megolm session keys are only shared with room members' devices (see Megolm key sharing mechanism — keys are sent via Olm-encrypted `m.room_key` to-device events only to room member devices)
- **MSC3083** (merged into spec, Room Version 8+): `restricted` join rule allows auto-joining based on space membership — but this is **not needed** if we actively manage invites

**Pros:**
- ✅ **Cross-client compatible**: Any Matrix client (Element, NeoChat, etc.) will enforce visibility correctly because it's based on room membership
- ✅ **Server-side enforced**: The homeserver itself prevents non-members from seeing events
- ✅ **E2EE enforced**: Megolm keys are only distributed to room member devices, so even a compromised server can't decrypt messages for non-members
- ✅ **Simple, well-understood Matrix pattern**

**Cons:**
- ⚠️ Multiple rooms visible in other clients (but can be mitigated — see below)
- ⚠️ Room management overhead (inviting/kicking when circle membership changes)

**Mitigation for "too many rooms":**
- Use consistent naming: `story:<username>:<circlename>` (or use a custom room type via state event)
- Other clients will see these as regular rooms, but they're just invite-only story rooms — not excessive
- Could use Matrix Spaces to group them under a "Stories" space (invisible to most UIs)

### Option B: Selective Megolm Key Sharing (E2EE-based)
**How it works:** Post stories to a single room, but only share the Megolm encryption keys with devices of users who belong to selected Circles.

**Matrix mechanisms involved:**
- Megolm keys are shared via `m.room_key` to-device events (Olm-encrypted)
- The sender controls **which devices** receive the key
- Non-recipients would get "Unable to Decrypt" (UTD) errors

**Pros:**
- ✅ Single story room (cleaner)
- ✅ Protocol-level enforcement (undecryptable without keys)

**Cons:**
- ❌ **NOT cross-client compatible**: Other Matrix clients (Element) will see UTD messages, creating a confusing UX
- ❌ Room members who don't get keys may request them via `m.room_key_request` — other devices might forward them, breaking the restriction
- ❌ Key backup could also leak keys to non-intended recipients
- ❌ Technically complex: requires overriding the SDK's key sharing logic
- ❌ Non-standard behavior; goes against Matrix design intent where room membership = message access

### Option D: MSC2326 Label-Based Filtering
**How it works:** Attach labels to story events (e.g., circle IDs) and use server-side filtering to show only matching events.

**Matrix mechanisms involved:**
- `m.labels` field on events
- Server-side `/sync`, `/messages` filtering by label
- In encrypted rooms: SHA256 hash of `label + room_id` as server-visible label

**Pros:**
- ✅ Single room
- ✅ Server can filter events efficiently

**Cons:**
- ❌ **MSC2326 is NOT merged** into the Matrix spec (still draft/open since 2019)
- ❌ No server implementations exist (Synapse, Conduit, etc. don't support it)
- ❌ **Not enforceable**: Labels are metadata — anyone with room access can still read all events; the server filtering is a convenience, not a security boundary
- ❌ In E2EE rooms, the hashed labels leak some information
- ❌ Other clients won't filter by labels, so all content would be visible

### Option D: Custom State Event with Client-Side Filtering
**How it works:** Post stories with a `circle_ids` metadata field. FF Chat clients filter display based on circle membership.

**Cons:**
- ❌ **Purely client-side**: Any other Matrix client sees everything
- ❌ No security enforcement at all
- ❌ Violates the user's stated requirement for cross-client compatibility

---

## 5. Recommended Implementation Approach

### **Primary: Room-per-Circle Stories (Option A)**

This is the only approach that provides **true cross-client, server-enforced, and E2EE-enforced** visibility control. Here's the detailed design:

#### 5.1 Data Model Extension

Extend account data `im.ffchat.circles` (or a new `im.ffchat.circle_stories`) to map circles to story room IDs:

```json
{
  "version": 1,
  "circle_story_rooms": {
    "c_abc123": "!storyroom1:matrix.org",
    "c_def456": "!storyroom2:matrix.org"
  }
}
```

#### 5.2 Story Posting Flow

1. User taps "Add to Story" → shown a **circle audience selector** (using existing circle filter chips pattern from `invitation_selection_view.dart` L89-109)
2. User selects one or more Circles
3. For each selected Circle:
   - If no story room exists for that Circle → create one (`preset: privateChat`, `name: story:<username>:<circleName>`, encrypted)
   - Sync room membership with Circle members (invite missing, optionally kick removed)
   - Post the story content to the room
4. Save the Circle→Room mapping in account data

#### 5.3 Story Viewing Flow

- `StoriesBar` already shows all rooms where `isStory == true` — no change needed for viewing
- `StoryViewer` already navigates between story rooms — no change needed

#### 5.4 Circle Membership Sync

When Circle membership changes (user added/removed from a Circle):
- Find the associated story room
- Invite/kick users as needed
- This could be lazy (on next story post) rather than immediate

#### 5.5 Affected Files

| File | Change |
|------|--------|
| `lib/utils/circles_config.dart` | Add `circleStoryRooms` mapping, `getOrCreateStoryRoomForCircle()` |
| `lib/utils/own_story_config.dart` | Extend or refactor to support multiple story rooms per user |
| `lib/pages/stories/stories_bar.dart` | Add circle audience selector when posting |
| `lib/pages/chat_list/chat_list.dart` | Update `storyRooms` to include circle story rooms |
| `lib/pages/circles/circle_detail.dart` | Trigger membership sync on member add/remove |
| `lib/l10n/intl_en.arb` | New strings for circle audience selection |

---

## 6. Technical Considerations

### Matrix Room Permissions
- Story rooms should use `preset: privateChat` (invite-only)
- The story owner should have PL 100 (room creator default)
- Members should have PL 0 (can view but not post)
- Use `m.room.power_levels` to prevent non-owners from sending messages

### State Events
- Consider a `ffchat.story_meta` state event to mark the room as a circle-scoped story room:
  ```json
  {
    "type": "ffchat.story_meta",
    "content": {
      "circle_id": "c_abc123",
      "circle_name": "Close Friends",
      "owner": "@user:matrix.org"
    }
  }
  ```

### Client-Side vs Server-Side Filtering
- **Server-side**: Room membership enforces who can see events. ✅
- **Client-side**: FF Chat can use the `ffchat.story_meta` state event to understand the relationship between rooms and circles. Other clients simply see invite-only rooms.

### E2EE
- Story rooms should be encrypted by default (matching `own_story_config.dart` L59-78 pattern)
- Megolm key sharing automatically restricts decryption to room members' devices

### Scalability
- A user with 5 circles posts 1 story visible to all = 5 copies of the message (one per room)
- This is acceptable for story volumes (stories are ephemeral, not high-volume)
- Alternative: Post to only 1 room when only 1 circle is selected

---

## 7. Summary: Approach Comparison

| Approach | Cross-Client | Server-Enforced | E2EE-Enforced | Complexity | Status |
|----------|:---:|:---:|:---:|:---:|:---:|
| **A. Room-per-Circle** ⭐ | ✅ | ✅ | ✅ | Medium | Standard Matrix |
| B. Selective Key Sharing | ❌ | ❌ | ✅ | High | Non-standard |
| C. Label Filtering (MSC2326) | ❌ | ❌ | ❌ | Medium | Draft MSC (no impl) |
| D. Client-Side Filtering | ❌ | ❌ | ❌ | Low | Not secure |

**Recommendation:** **Option A (Room-per-Circle)** is the only approach that satisfies the requirement of cross-client compatibility with server-enforced and cryptographically-enforced visibility. While it creates additional rooms, this is the **Matrix-native way** — rooms are the fundamental unit of access control in Matrix, and trying to work around this leads to either insecure or incompatible solutions.

---

## IMPLEMENTATION STEPS

1. **READ**: `lib/utils/circles_config.dart` - Lines 1-219 to understand current Circle storage and CRUD methods.
2. **MODIFY**: `lib/utils/circles_config.dart` - Add `circleStoryRooms` map to `CirclesConfigExtension` and logic to get/create a story room for a specific circle.
3. **READ**: `lib/utils/own_story_config.dart` - Lines 1-83 to understand current story room creation and ownership logic.
4. **MODIFY**: `lib/utils/own_story_config.dart` - Refactor to support multiple story rooms per user, possibly using the circle-scoped room mapping.
5. **READ**: `lib/pages/stories/stories_bar.dart` - Lines 1-229 to understand the current "Add to Story" button logic.
6. **MODIFY**: `lib/pages/stories/stories_bar.dart` - Update the story posting flow to include a circle selection popup before room creation/posting.
7. **READ**: `lib/pages/invitation_selection/invitation_selection_view.dart` - Lines 89-109 to reuse the circle filter chips UI for audience selection.
8. **MODIFY**: `lib/pages/circles/circle_detail.dart` - Add logic to invite/remove users from the corresponding story room when they are added/removed from a circle.
9. **MODIFY**: `lib/l10n/intl_en.arb` - Add new localization keys for "Select Circle Audience", "Public Story", etc.
