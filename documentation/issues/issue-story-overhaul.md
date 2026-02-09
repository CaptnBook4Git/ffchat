# [FORK] Feature: Complete Story Overhaul — Outbound/Inbound Channel Architecture with Circle-Based Distribution

**Type:** feature / enhancement

## Description

The current story implementation in FF Chat uses a single personal Matrix room for stories, which lacks privacy controls and audience segmentation. This issue proposes a complete overhaul of the story architecture to introduce a robust Outbound/Inbound channel model.

The new requirement introduces two types of dedicated rooms:
1. **Outbound-Stories-Channel**: A private, user-only room that acts as the master source for all created stories.
2. **Inbound-Stories-Channel**: A channel for each user that aggregates stories from all their contacts.

When a user posts a story to their Outbound channel, they can select specific Circles (audiences). The application will then automatically push these stories to the Inbound channels of all members within those selected Circles. This architecture ensures that stories are only distributed to intended recipients while maintaining a single management point for the author.

Furthermore, any changes made to a story in the Outbound channel (such as edits or deletions) must be automatically synchronized and reflected in all Inbound channels where the story was originally distributed.

## Current Behavior

Currently, FF Chat implements stories as single, personal Matrix rooms with a `story:` display-name prefix.
- File: `lib/utils/story_room_extension.dart` (line 14-22) - Detects story rooms by prefix.
- File: `lib/utils/own_story_config.dart` (line 12, 48-82) - Manages a single own story room via account data.
- File: `lib/pages/stories/stories_bar.dart` (line 42-87) - Handles basic story posting to the single room.
- File: `lib/pages/chat_list/chat_list.dart` (line 195-209) - Filters story rooms from the main chat list.

**Limitations:**
- No audience segmentation (one room for everything).
- No circle-based distribution.
- No synchronization for edits/deletions across recipients.

## Expected Behavior

- **Outbound Channel**: A private room (`story:outbound:<username>`) accessible only by the user for story management.
- **Inbound Channel**: A room (`story:inbound:<username>`) for each user containing all their contacts, where stories from others are received.
- **Circle-Based Distribution**: Users select Circles when posting; the app pushes content to relevant Inbound channels.
- **Synchronization**: Edits (using `m.replace`) and deletions (redactions) in the Outbound channel propagate to all distributed copies in Inbound channels.
- **Privacy**: High-level control over who sees which story via Circle membership.

## Motivation

The current model is technically limited and does not provide the privacy features expected by users in a modern social ecosystem. By implementing an Outbound/Inbound model with Circle distribution, we provide users with granular control over their content visibility, aligning with the "Family and Friends" focus of this fork. This also fixes the critical privacy implication where everyone in a story room could see everything.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/utils/own_story_config.dart` | `OwnStoryConfigExtension` | Major refactor: Move from single-room to dual-room model. |
| `lib/utils/story_room_extension.dart` | `StoryRoomExtension` | Modify detection logic for outbound/inbound rooms. |
| `lib/utils/circles_config.dart` | `CirclesConfigExtension` | Extend with distribution APIs. |
| `lib/pages/stories/stories_bar.dart` | `StoriesBar` widget | Add Circle selector and refactor posting flow. |
| `lib/pages/stories/story_viewer.dart` | `StoryViewer` | Update to read from Inbound channels and handle attribution. |
| `lib/pages/chat_list/chat_list.dart` | `ChatListController` | Update room filtering and tap handling. |
| `lib/pages/chat/send_file_dialog.dart` | `SendFileDialog` | Add Circle audience selection. |
| `lib/pages/circles/circle_detail.dart` | Circle Detail | Trigger sync on membership changes. |

### Current Implementation
The current logic relies on `ffchat.story` account data to track a single room ID. Posting is a direct send to that room. The `StoriesBar` simply lists these rooms based on the `story:` prefix.

### Dependencies
- **Issue #4 (Circles)**: Required. This overhaul relies on the existing Circles data model for audience targeting.
- **Issue #28 (Group Stories)**: Uses the same `ffchat.story_post` event type.

## Upstream Status

- Related upstream issue: None (Upstream FluffyChat #736 removed stories entirely). This is a fork-specific feature.

## Suggested Implementation Plan

1. **Phase 1: Data Model**: Create `lib/utils/story_channel_config.dart` to manage the new `ffchat.story_channels` account data and room creation logic for Outbound/Inbound channels.
2. **Phase 2: Distribution Service**: Implement `lib/utils/story_distribution_service.dart` to handle the logic of copying events from Outbound to Inbound rooms based on Circle membership.
3. **Phase 3: Audience UI**: Create `lib/pages/stories/story_audience_selector.dart` to allow users to select Circles during the story posting flow (inspired by `lib/pages/invitation_selection/invitation_selection_view.dart:89-109`).
4. **Phase 4: Refactor Posting**: Update `lib/pages/stories/stories_bar.dart` (lines 42-87) to integrate the audience selector and the new distribution service.
5. **Phase 5: Update Viewer**: Modify `lib/pages/stories/story_viewer.dart` (lines 106-154, 172-202) to support the `ffchat.story_post` event type and grouped views by author.
6. **Phase 6: Sync Engine**: Implement `lib/utils/story_sync_service.dart` to listen for redactions/edits in the Outbound channel and propagate them. Register it in `lib/widgets/matrix.dart`.
7. **Phase 7: Migration**: Implement logic in `lib/utils/story_channel_config.dart` to migrate existing stories from the old single-room model to the new Outbound channel.

## Acceptance Criteria

- [ ] Users can create an Outbound story channel that is private.
- [ ] Users can select one or more Circles when posting a story.
- [ ] Stories are correctly distributed to the Inbound channels of Circle members.
- [ ] Edits in the Outbound channel are reflected in all recipient Inbound channels.
- [ ] Deletions (redactions) in the Outbound channel propagate to all recipient Inbound channels.
- [ ] Existing stories are migrated to the new architecture without data loss.
- [ ] AGPL headers updated on all modified files.
- [ ] Ensure all new source files have the SPDX-License-Identifier: AGPL-3.0-or-later header and correct fork copyright/modification log.
- [ ] CHANGELOG.md updated with [FORK] entry.

## Technical Notes

- **Event Mapping**: We must track `outbound_event_id` to `List<{inbound_room_id, inbound_event_id}>` to handle sync accurately.
- **Offline Sync**: Propagation of edits/deletions requires background processing if the user is offline.
- **Privacy**: Inbound rooms contain all contacts; ensure presence/metadata exposure is minimized.

## Research References

- `documentation/issues/issue-story-overhaul-research.md`
- `documentation/issues/issue-circle-story-visibility-research.md`

---
*Generated by new-issue-agpl*
