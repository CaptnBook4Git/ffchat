# Feature: Add Story Expiry and Visibility Options (Auto-delete vs Hide-from-others)

**Type:** enhancement

## Description

The recently introduced "Stories" feature in this fork allows users to post ephemeral content by creating specialized rooms with a "story:" prefix. However, at present, these stories persist indefinitely because no expiration or visibility management logic has been implemented. This issue aims to bring the "ephemeral" aspect to the feature by allowing users to define a Time-To-Live (TTL) for their stories.

Beyond simple deletion, users have expressed a desire for privacy-focused visibility options. When a story "expires," the user should be able to choose between two distinct behaviors: complete deletion from the server (redaction) or hiding the story from other participants while keeping it visible to the author. This second option effectively turns the story into a private archive entry for the creator.

Implementing this requires a combination of Matrix-standard retention policies (MSC1763) and custom client-side filtering. Since Matrix does not natively support "per-user visibility" for a single event in a shared room where the event remains visible only to the sender after a certain time, we will need to implement a hybrid approach. This involves local caching for the author and logic-based exclusion for other participants once the expiry timestamp is reached.

The user interface must be updated to provide these configuration options during the story creation process. This ensures that the intent for the story's lifecycle is captured at the moment of posting, providing a seamless user experience consistent with modern social media platforms.

## Current Behavior

Currently, the stories feature relies on a simple naming convention.
- File: `lib/utils/story_room_extension.dart`
- Stories are detected purely by checking if a room name starts with the "story:" prefix. 
- There is no metadata associated with these rooms regarding their expiration time.
- Once created, a story room remains visible to all invited members forever, unless manually left or deleted by the administrator.

## Expected Behavior

Users should be presented with a configuration UI when creating a new story.
- **Expiry Time (X):** A configurable duration (e.g., 24 hours, 1 week) after which the story "expires."
- **Expiration Mode:**
    - **Complete Deletion:** The room or the content is redacted/deleted from the Matrix server entirely.
    - **Archive (Hide from others):** The story becomes invisible to all other participants but remains accessible to the author in their "Stories Archive."
- The app should automatically handle the transition from "active" to "expired" based on the chosen mode.

## Motivation

The core value of "Stories" is their ephemerality. Without an automated way to expire content, the feature is merely a collection of permanent group chats with a specific name prefix. Adding expiry and visibility options increases user privacy, reduces server clutter, and allows authors to maintain a private history of their shared moments without leaving them public to others indefinitely.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/pages/new_group/new_group.dart` | Creation Logic | Needs to handle new expiry parameters during room creation. |
| `lib/pages/new_group/new_group_view.dart` | Creation UI | Needs new input fields for TTL and visibility mode. |
| `lib/utils/own_story_config.dart` | Data Storage | Will handle local caching for the "Hide from others" (Archive) mode. |
| `lib/pages/stories/story_viewer.dart` | Viewer | Needs to check expiry status before rendering content for non-authors. |
| `lib/pages/stories/stories_bar.dart` | UI Component | May need to display a "time remaining" indicator. |
| `lib/utils/story_room_extension.dart` | Metadata | Needs getters to read expiry metadata from room state or account data. |

### Current Implementation
The current implementation in `lib/utils/story_room_extension.dart` uses a simple getter:
```dart
bool get isStory => getLocalizedDisplayname().startsWith('story:');
```
This logic needs to be expanded to check for expiration timestamps stored in the room's state events or account data.

### Dependencies
- **Matrix SDK:** Uses `m.room.retention` (MSC1763) if available on the homeserver.
- **Account Data:** Custom configuration might be stored in `org.matrix.msc.story.config` or similar namespaced account data.

## Upstream Status

- **Upstream (krille-chan/fluffychat):** Does not have a stories feature.
- **Matrix Specification:** MSC1763 (Retention) is relevant for server-side deletion but does not cover the "hide for others" use case.

## Suggested Implementation Plan

1.  **Define Metadata Structure:** Decide where to store the expiry timestamp and mode (e.g., in a custom room state event `com.ffchat.story.settings`).
2.  **UI Updates:** Modify `lib/pages/new_group/new_group_view.dart` to include a "Story Settings" section with a duration picker and a toggle for "Delete vs. Archive".
3.  **Creation Logic:** Update `lib/pages/new_group/new_group.dart` to send the state event with the selected settings during room creation.
4.  **Expiry Manager:** Create `lib/utils/story_expiry_manager.dart` to periodically check for expired stories and trigger the appropriate action.
5.  **Filtering Logic:** Update `lib/pages/stories/story_viewer.dart` and `lib/utils/story_room_extension.dart` to filter out expired stories from the UI if the user is not the author and the mode is "Archive".
6.  **Local Archive:** If "Archive" is selected, ensure the content is cached or remains accessible via `lib/utils/own_story_config.dart`.

## Acceptance Criteria

- [ ] Users can select a custom expiry duration when creating a story.
- [ ] Users can choose between "Complete Deletion" and "Hide for others".
- [ ] Stories in "Delete" mode are redacted or the room is left/forgotten after time X.
- [ ] Stories in "Archive" mode become invisible to guests/others but stay visible to the author.
- [ ] Metadata is correctly stored in the Matrix room state.
- [ ] AGPLv3 headers are updated on all modified and newly created files.
- [ ] CHANGELOG.md is updated with a [FORK] entry describing the enhancement.

## Technical Notes

- **MSC1763 Support:** Check if the homeserver supports room retention. If not, client-side redaction is a fallback but less reliable.
- **Client-Side Enforcement:** For "Hide for others", the app must actively filter these rooms out of the stories bar for everyone except the creator.
- **Edge Case:** If the author switches devices, the "Archive" stories should ideally be reconstructible from the Matrix history (unless redacted).

## Research References

- Matrix MSC1763: Room retention
- Existing story logic: `lib/utils/story_room_extension.dart`

---
*Generated by new-issue-agpl*
