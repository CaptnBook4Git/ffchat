# Story Feature Overhaul — Structured Research Report

## Suggested Issue Title
**[FORK] Feature: Complete Story Overhaul — Outbound/Inbound Channel Architecture with Circle-Based Distribution**

## Issue Type
**Feature / Enhancement** (Major Refactor)

---

## Current Behavior

The FF Chat fork currently implements stories as **single, personal Matrix rooms** with a display-name prefix `story:`.

### How it works today:
1. **Story Detection**: Rooms whose display name starts with `story:` are treated as story rooms (`lib/utils/story_room_extension.dart:14-22`).
2. **Own Story Room**: Each user has ONE own story room tracked in account data `ffchat.story` with content `{"room_id": "!..."}` (`lib/utils/own_story_config.dart:12`).
3. **Creation**: The room is created as an encrypted private chat with `getOrCreateOwnStoryRoom()` (`lib/utils/own_story_config.dart:48-82`).
4. **Posting**: The "Add to Story" button in `StoriesBar` (`lib/pages/stories/stories_bar.dart:42-87`) picks images, opens `SendFileDialog`, and sends to the own story room.
5. **Viewing**: Stories are displayed in a horizontal bar (`StoriesBar`) in the chat list body (`lib/pages/chat_list/chat_list_body.dart:142`), and tapped stories open the full-screen `StoryViewer` (`lib/pages/stories/story_viewer.dart`).
6. **Filtering**: Story rooms are excluded from normal chat list views via `getRoomFilterByActiveFilter()` (`lib/pages/chat_list/chat_list.dart:195-209`).
7. **No Audience Control**: Stories are visible to anyone who is a member of the story room. There is no mechanism to restrict specific stories to specific contacts or circles.

### Limitations of current approach:
- Single room = no audience segmentation
- No outbound/inbound separation
- No circle-based distribution
- No synchronization mechanism for edits/deletions across recipients

---

## Expected Behavior (Outbound/Inbound Architecture)

### 1. Outbound-Stories-Channel (Private, User-Only)
- A **private room** that only the user can access (no other members)
- Serves as the **master source** for all stories the user creates
- The user posts stories here, selects target Circles, and the app handles distribution
- Named: `story:outbound:<username>` or similar convention

### 2. Inbound-Stories-Channel (Per-User Aggregation)
- Each user has an **Inbound channel** that is a room containing **all their contacts**
- When another user posts a story and selects Circles that include this user, the story content is **pushed** into this user's Inbound channel
- This is what users see in their `StoriesBar` — aggregated stories from all contacts

### 3. Circle-Based Distribution Workflow
- User posts story → selects Circles → stories are pushed to the Inbound channels of all members within those Circles
- The Outbound channel retains the original story + metadata about which Circles it was distributed to

### 4. Synchronization
- Edits/deletions in the Outbound channel → reflected in all Inbound channels
- Mechanism: `m.relates_to` with `rel_type: "m.replace"` for edits, redaction for deletions

---

## Affected Files

| File | Component | Relevance |
|------|-----------|-----------|
| `lib/utils/own_story_config.dart` (L1-84) | `OwnStoryConfigExtension` | **MAJOR REFACTOR**: Replace single room with Outbound+Inbound dual-room model |
| `lib/utils/story_room_extension.dart` (L1-36) | `StoryRoomExtension` | **MODIFY**: Add detection for outbound/inbound room types via naming or state event |
| `lib/utils/circles_config.dart` (L1-220) | `CirclesConfigExtension` | **EXTEND**: Add circle-to-member iteration API, story distribution methods |
| `lib/pages/stories/stories_bar.dart` (L1-230) | `StoriesBar` widget | **MAJOR REFACTOR**: Add Circle audience selector in posting flow, read from Inbound channels |
| `lib/pages/stories/story_viewer.dart` (L1-638) | `StoryViewer` | **MODIFY**: Handle viewing from Inbound channels, attribution to original author |
| `lib/pages/chat_list/chat_list.dart` (L152-227) | `ChatListController` | **MODIFY**: Update `storyRooms` getter to show Inbound content, hide Outbound from bar |
| `lib/pages/chat_list/chat_list_body.dart` (L77,142) | Chat list body | **MINOR**: Update StoriesBar integration |
| `lib/pages/new_group/new_group.dart` (L118-177) | `NewGroup`/`_createStory()` | **MODIFY/REMOVE**: Story creation should use new architecture, not manual room creation |
| `lib/pages/new_group/new_group_view.dart` (L31-57,92-99,132,179) | Story creation UI | **MODIFY**: Update or remove story type from segmented button |
| `lib/config/routes.dart` (L165-177) | Story route | **MODIFY**: May need routes for outbound management view |
| `lib/pages/chat/send_file_dialog.dart` (L26-43,116,144) | `SendFileDialog` | **EXTEND**: Add Circle audience selection when posting to story |
| `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` (L1-59) | Timeline filtering | **EXTEND**: Filter custom story distribution events |
| `lib/pages/invitation_selection/invitation_selection_view.dart` (L89-109) | Circle filter chips | **REUSE**: Pattern for circle audience selector UI |
| `lib/pages/circles/circle_detail.dart` (L34) | Circle detail | **EXTEND**: Trigger story room sync on member changes |
| `lib/l10n/intl_en.arb` | Localization | **ADD**: New strings for outbound/inbound, audience selection, sync status |
| `CHANGELOG.md` | Changelog | **ADD**: `[FORK]` entry |
| **NEW**: `lib/utils/story_distribution_service.dart` | Story Distribution | **CREATE**: Core logic for pushing stories from Outbound to Inbound channels |
| **NEW**: `lib/utils/story_sync_service.dart` | Story Sync | **CREATE**: Synchronization logic for edits/deletions |
| **NEW**: `lib/utils/story_channel_config.dart` | Channel Config | **CREATE**: Outbound/Inbound channel management and account data |
| **NEW**: `lib/pages/stories/story_audience_selector.dart` | Audience Selector UI | **CREATE**: Circle selection bottom sheet for story posting |

---

## Upstream Status

| Source | Issue | Status | Relevance |
|--------|-------|--------|-----------|
| krille-chan/fluffychat **#736** | "refactor: Replace stories feature with presence status msg" | **MERGED** | Upstream **removed stories entirely**. No upstream alignment possible. |
| krille-chan/fluffychat **#265** | "Stories feature has huge privacy implications" | CLOSED (stale) | Raised privacy concerns similar to this issue's motivation. No solution was implemented. |
| krille-chan/fluffychat **#267** | "Inviting multiple users with PL100 merges their stories" | CLOSED | Highlights the problem of multi-user story rooms — relevant to Inbound channel design. |
| krille-chan/fluffychat **#520** | "First stories appear to be unencrypted" | CLOSED | Relevant: Outbound/Inbound channels must enforce E2EE. |
| CaptnBook4Git/ffchat **#28** | "Group Stories" | OPEN | Defines `ffchat.story_post` custom event type — can be reused for distribution events. |
| CaptnBook4Git/ffchat **#24** | "Story visibility duration" | OPEN | Story expiry is complementary to this feature. |
| CaptnBook4Git/ffchat **#14** | "Story Expiry and Visibility Options" | OPEN | Overlaps with audience control. |

**Key finding**: Upstream FluffyChat has **no stories feature** anymore. There are **no existing issues** for outbound/inbound story distribution in any Matrix client. This is a novel fork-specific architecture. The existing fork research in `documentation/issues/issue-circle-story-visibility-research.md` recommends **Room-per-Circle** (Option A) as the only cross-client-compatible approach — this aligns with the Outbound/Inbound model.

---

## Suggested Implementation Approach

### Architecture: Custom Event Distribution via Dedicated Rooms

#### Account Data Model
```json
// New account data type: ffchat.story_channels
{
  "version": 1,
  "outbound_room_id": "!outbound:matrix.org",
  "inbound_room_id": "!inbound:matrix.org",
  "circle_distribution_log": {
    "c_abc123": ["$event1", "$event2"],
    "c_def456": ["$event1"]
  }
}
```

#### Custom Event Types
- **`ffchat.story_post`** (message event): Story content in Outbound room
  ```json
  {
    "type": "ffchat.story_post",
    "content": {
      "msgtype": "m.image",
      "url": "mxc://...",
      "body": "story.jpg",
      "info": { ... },
      "ffchat.target_circles": ["c_abc123", "c_def456"],
      "ffchat.outbound_event_id": "$original_event_id",
      "ffchat.outbound_room_id": "!outbound:matrix.org",
      "ffchat.author": "@user:matrix.org"
    }
  }
  ```

- **`ffchat.story_meta`** (state event): Marks a room as an Outbound or Inbound story channel
  ```json
  {
    "type": "ffchat.story_meta",
    "state_key": "",
    "content": {
      "channel_type": "outbound" | "inbound",
      "owner": "@user:matrix.org"
    }
  }
  ```

#### Synchronization via `m.relates_to`
- **Edits**: Use `m.replace` relationship type (already supported in the codebase: `RelationshipTypes.edit` in `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart:28`)
  ```json
  {
    "type": "ffchat.story_post",
    "content": {
      "m.relates_to": {
        "rel_type": "m.replace",
        "event_id": "$distributed_event_id"
      },
      "m.new_content": { ... }
    }
  }
  ```
- **Deletions**: Standard Matrix redaction (`room.redact(eventId)`) in Inbound channels, triggered when Outbound event is redacted

#### Distribution Flow
1. User posts to Outbound room → selects Circles
2. `StoryDistributionService` iterates selected circles (`client.circles` from `circles_config.dart:123`)
3. For each circle, iterate `circle.members` (list of Matrix user IDs, `circles_config.dart:18`)
4. For each member, find/create their Inbound room and send the `ffchat.story_post` event
5. Store distribution mapping in Outbound room state or account data

---

## Technical Considerations

### 1. Privacy
- **Outbound channel**: Must be truly private (no other members, encrypted)
- **Inbound channel**: Contains all contacts — they can see each other's presence unless configured otherwise
- **Alternative Inbound design**: Instead of one Inbound room with all contacts, consider per-contact DM-based distribution (pushes story events into existing DM rooms as custom events — less room overhead but mixes story and DM content)

### 2. Scalability
- **Room creation overhead**: If using Room-per-Circle approach, posting to N circles = N rooms to manage
- **Event duplication**: Same story content sent to multiple Inbound rooms = storage multiplication
- **Mitigation**: Use MXC URIs (content uploaded once, referenced by URI in multiple rooms)

### 3. Synchronization Challenges
- **Edit propagation**: When Outbound event is edited, need to find ALL corresponding events in ALL Inbound rooms and send replacements
- **Deletion propagation**: When Outbound event is redacted, need to redact ALL copies
- **Tracking**: Must maintain a mapping: `outbound_event_id → [{inbound_room_id, inbound_event_id}]`
- **Offline handling**: What if the poster is offline when an edit needs to propagate? Background processing is needed.
- **Race conditions**: If the user edits multiple times before distribution completes, must ensure ordering

### 4. Cross-Client Compatibility
- Other Matrix clients (Element, NeoChat) will see `ffchat.story_post` events as unknown event types
- Inbound rooms will appear as regular rooms in other clients
- Consider adding fallback `body` field for basic text display in non-FF Chat clients

### 5. E2EE Implications
- Each room has its own Megolm session — keys are shared per-room
- Sending the same content to multiple rooms is fine (each room encrypts independently)
- Key verification/cross-signing works normally per room

---

## IMPLEMENTATION STEPS (Required Format)

### Phase 1: Data Model & Channel Management

1. **READ**: `lib/utils/own_story_config.dart` - Lines 1-84 to understand current single-room story model (account data type `ffchat.story`, room creation with encryption)
2. **ADD**: `lib/utils/story_channel_config.dart` - Create new file with:
   - `StoryChannelConfigExtension` on Client
   - Account data type `ffchat.story_channels` storing `outbound_room_id`, `inbound_room_id`
   - `getOrCreateOutboundChannel()` - creates encrypted private room with `story:outbound:<localpart>` name, user as sole member, PL100
   - `getOrCreateInboundChannel()` - creates room with `story:inbound:<localpart>` name, invites all direct-chat contacts
   - `isOutboundChannel(Room)` / `isInboundChannel(Room)` detection via state event or naming convention
3. **MODIFY**: `lib/utils/own_story_config.dart:12` - Deprecate or repurpose `ffchat.story` account data type; add migration logic that converts existing story room into the new Outbound channel
4. **MODIFY**: `lib/utils/story_room_extension.dart:14-23` - Update `isStory` getter to recognize both old `story:` prefix AND new `story:outbound:` / `story:inbound:` prefixes; add `isOutboundStory` and `isInboundStory` getters

### Phase 2: Story Distribution Service

5. **READ**: `lib/utils/circles_config.dart` - Lines 116-127 to understand `circles` getter and `circlesForUser(userId)` for iterating circle members
6. **ADD**: `lib/utils/story_distribution_service.dart` - Create new file with:
   - `StoryDistributionService` class taking a `Client` parameter
   - `distributeStory({required String outboundEventId, required String outboundRoomId, required List<String> circleIds})` method
   - Logic: for each circleId → get `circle.members` → for each member → get/find their Inbound room → send `ffchat.story_post` event with `ffchat.outbound_event_id` reference
   - `syncEdit({required String outboundEventId, required Map<String, Object?> newContent})` - propagates edits using `m.relates_to` with `rel_type: m.replace`
   - `syncDeletion({required String outboundEventId})` - redacts all distributed copies
   - Internal mapping storage: maintain `outbound_event_id → [{inbound_room_id, inbound_event_id}]` in room state or account data

### Phase 3: Audience Selector UI

7. **READ**: `lib/pages/invitation_selection/invitation_selection_view.dart` - Lines 89-109 to reuse circle filter chips pattern for audience selection
8. **ADD**: `lib/pages/stories/story_audience_selector.dart` - Create new file with:
   - `StoryAudienceSelector` widget (bottom sheet / modal)
   - Displays all user's Circles as selectable chips
   - Returns `List<String>` of selected circle IDs
   - Uses `client.circles` from `circles_config.dart:123`

### Phase 4: Update Story Posting Flow

9. **READ**: `lib/pages/stories/stories_bar.dart` - Lines 42-87 to understand current `_addToOwnStory()` flow
10. **MODIFY**: `lib/pages/stories/stories_bar.dart:42-87` - Refactor `_addToOwnStory()`:
    - Step 1: Show `StoryAudienceSelector` to get selected circles
    - Step 2: Get/create Outbound channel (instead of `getOrCreateOwnStoryRoom`)
    - Step 3: Post story to Outbound channel with `ffchat.target_circles` metadata
    - Step 4: Call `StoryDistributionService.distributeStory()` to push to Inbound channels
    - Step 5: Navigate to story viewer
11. **MODIFY**: `lib/pages/chat/send_file_dialog.dart:26-43` - Add optional `targetCircles` parameter for circle metadata attachment when sending to story rooms

### Phase 5: Update Story Viewing

12. **MODIFY**: `lib/pages/chat_list/chat_list.dart:216-227` - Update `storyRooms` getter:
    - For the current user: show the Outbound channel (with "Manage" option)
    - For other users: show Inbound channel stories (aggregated from `ffchat.story_post` events)
    - Filter out raw Inbound rooms from the main story bar; show aggregated per-author stories instead
13. **MODIFY**: `lib/pages/stories/story_viewer.dart:106-154` - Update `_load()`:
    - When viewing Inbound stories: filter for `ffchat.story_post` event type
    - Display `ffchat.author` attribution in the header (Line 294, title)
    - Handle `m.replace` relationships for edited stories
14. **MODIFY**: `lib/pages/stories/story_viewer.dart:172-202` - Update `_rebuildEvents()`:
    - Add support for `ffchat.story_post` message type
    - Filter by `ffchat.author` to group stories by original poster

### Phase 6: Synchronization

15. **ADD**: `lib/utils/story_sync_service.dart` - Create new file with:
    - Event listener on Outbound room for edits/redactions
    - On `m.replace` event in Outbound → call `StoryDistributionService.syncEdit()`
    - On redaction in Outbound → call `StoryDistributionService.syncDeletion()`
    - Background processing: queue sync operations and process when online
16. **MODIFY**: `lib/widgets/matrix.dart:366` (near `requestHistoryOnLimitedTimeline`) - Register `StorySyncService` listener during client initialization

### Phase 7: Circle Membership Sync

17. **MODIFY**: `lib/pages/circles/circle_detail.dart:34` - After adding/removing members from a Circle:
    - If a story room exists for that Circle, invite/kick the member from the corresponding Inbound rooms
    - Call `StoryDistributionService` to update Inbound channel membership
18. **MODIFY**: `lib/utils/circles_config.dart:186-218` - In `addMemberToCircle()` and `removeMemberFromCircle()`:
    - Add optional callback/hook for story room membership sync
    - Alternatively, fire a client-side event that `StorySyncService` listens to

### Phase 8: Update Story Creation UI

19. **MODIFY**: `lib/pages/new_group/new_group.dart:118-134` - Update `_createStory()`:
    - Remove direct room creation; instead call `StoryChannelConfigExtension.getOrCreateOutboundChannel()`
    - Navigate to the Outbound channel management view
20. **MODIFY**: `lib/pages/new_group/new_group_view.dart:55-56` - Update story creation label to reflect new "Outbound Channel" concept
21. **MODIFY**: `lib/pages/chat_list/chat_list.dart:152-190` - Update `onChatTap()` story handling:
    - Outbound rooms → show management UI (edit, delete, view distribution status)
    - Inbound content → open StoryViewer normally

### Phase 9: Localization & Documentation

22. **MODIFY**: `lib/l10n/intl_en.arb` - Add new localization strings:
    - `outboundStoryChannel`, `inboundStoryChannel`
    - `selectAudience`, `selectCirclesForStory`
    - `storyDistributed`, `storyDistributionFailed`
    - `syncingStories`, `storyEdited`, `storyDeleted`
    - `manageOutboundChannel`, `viewInboundStories`
23. **MODIFY**: `CHANGELOG.md` - Add `[FORK] Complete Story Overhaul: Outbound/Inbound channels with Circle-based distribution`

### Phase 10: Migration & Backward Compatibility

24. **MODIFY**: `lib/utils/story_channel_config.dart` (new file from Step 2) - Add migration logic:
    - Detect existing `ffchat.story` account data
    - Convert the existing story room to an Outbound channel
    - Create a new Inbound channel
    - Set `ffchat.story_meta` state event on both channels
    - Preserve all existing story content

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Room proliferation (many rooms per user) | Medium | Use naming conventions + state events for detection; hide from other clients via room type |
| Event duplication (same content in N rooms) | Low | MXC URIs are content-addressed; only metadata is duplicated |
| Sync failures (offline, network) | High | Queue-based sync with retry; store pending operations in local storage |
| Migration breaks existing stories | High | Implement migration path that preserves existing `ffchat.story` rooms |
| Performance with many circles/members | Medium | Batch operations; lazy distribution (send on view, not on post) |
| E2EE key sharing delays | Low | Standard Matrix behavior; acceptable for story content |

---

## Dependencies on Other Fork Issues

| Issue | Dependency Type | Notes |
|-------|----------------|-------|
| **#4** (Circles) | **Required** ✅ | Already implemented. Circles data model is the foundation. |
| **#28** (Group Stories) | **Complementary** | Uses `ffchat.story_post` event type — coordinate namespacing. |
| **#24** (Story Visibility Duration) | **Complementary** | Expiry logic should work with both Outbound and Inbound channels. |
| **#14** (Story Expiry) | **Complementary** | Auto-delete in Outbound should trigger deletion sync to Inbound. |
| **#33** (Circles UI) | **Nice-to-have** | Better Circles UI improves audience selection experience. |