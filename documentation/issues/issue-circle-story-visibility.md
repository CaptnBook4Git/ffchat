# [FORK] Feature: Circle-Based Story Visibility

**Type:** Enhancement / Feature

## Description

This feature enables users to control the visibility of their stories based on their contact Circles. Instead of a single story room visible to all story-enabled contacts, users will be able to select specific "audiences" (Circles) when posting a new story. 

Currently, the FF Chat fork implements Circles as client-side contact groups and Stories as dedicated Matrix rooms. However, there is no link between the two: stories are posted to a single "own story room" that all contacts can potentially see if they are in that room.

This enhancement introduces a "Room-per-Circle" approach. When a user posts a story to a specific circle, a dedicated Matrix room is created or managed for that circle. Only contacts within that circle are invited to the room, ensuring that visibility is enforced at the Matrix protocol level. This ensures cross-client compatibility: even if a contact uses a different Matrix client like Element, they will only see the stories they are authorized to see based on their room membership.

## Current Behavior

- **Circles:** Implemented as local Matrix account data (`im.ffchat.circles`). They are used for filtering contacts in the invitation UI but have no impact on story visibility.
- **Stories:** Every user has one "own story room" (tracked in `ffchat.story` account data). Any story post goes to this single room.
- **Visibility:** Controlled solely by being a member of the single story room. No option exists to restrict a specific story post to a subset of contacts.

## Expected Behavior

- When tapping the "Add to Story" button, the user is presented with an audience selector (Circles).
- The user can select one or more Circles for the story post.
- The app automatically manages (creates if necessary) dedicated Matrix rooms for each selected Circle.
- The story content is posted to the corresponding Circle-specific story rooms.
- Membership in these story rooms is synchronized with the members of the respective Circles.
- The visibility restriction works cross-client because it relies on standard Matrix room membership and encryption (Megolm).

## Motivation

Privacy is a core value of the "Family and Friends" ecosystem. Users should have granular control over who sees their personal updates. By leveraging the existing Circles feature, we provide a familiar and powerful way to manage audiences. Implementing this at the protocol level (via separate rooms) ensures that privacy is not just a client-side "suggestion" but a hard restriction enforced by the homeserver and end-to-end encryption.

## Codebase Analysis

### Affected Files

| File | Component | Relevance |
|------|-----------|-----------|
| `lib/utils/circles_config.dart` | `CirclesConfigExtension` | Store Circle-to-StoryRoom mapping in account data. |
| `lib/utils/own_story_config.dart` | `OwnStoryConfigExtension` | Handle creation/management of multiple story rooms. |
| `lib/pages/stories/stories_bar.dart` | `StoriesBar` widget | Add UI for audience selection during posting. |
| `lib/pages/chat_list/chat_list.dart` | `ChatListController` | Detect and aggregate multiple story rooms for display. |
| `lib/pages/circles/circle_detail.dart` | `CircleDetailController` | Sync room membership when Circle members change. |
| `lib/l10n/intl_en.arb` | Localization | Add strings for audience selection and story management. |

### Current Implementation

- **Circles Storage:** `lib/utils/circles_config.dart:117` uses `im.ffchat.circles` account data.
- **Story Room Creation:** `lib/utils/own_story_config.dart:59` implements `getOrCreateOwnStoryRoom`.
- **Story Bar Posting:** `lib/pages/stories/stories_bar.dart:110` handles the "Add to Story" action.
- **Circle Filtering UI:** `lib/pages/invitation_selection/invitation_selection_view.dart:89` contains the pattern for circle filter chips which can be reused.

### Dependencies

- **Matrix SDK:** Uses standard room creation and invitation methods.
- **E2EE:** Relies on Megolm key sharing which naturally follows room membership.

## Upstream Status

- **FluffyChat Upstream:** No equivalent feature. Upstream removed its original story implementation and does not have Circles.
- **Related Fork Issues:** 
  - #4 (Circles) - Basis for this feature.
  - #28 (Group Stories) - Related infrastructure for room-based stories.

## Suggested Implementation Plan

1. **Extend Data Model (`lib/utils/circles_config.dart`):** Add a mapping in account data to track which Circle ID corresponds to which Matrix Story Room ID.
2. **Refactor Story Creation (`lib/utils/own_story_config.dart`):** Modify the room creation logic to support parameterized room creation (e.g., `getOrCreateStoryRoom(String circleId)`).
3. **Audience Selector UI (`lib/pages/stories/stories_bar.dart`):** Implement a modal popup or bottom sheet that appears when clicking the "Add" button, allowing users to pick one or more circles.
4. **Room Management Logic:**
   - On post: If a room for the circle doesn't exist, create it (encrypted, private).
   - Sync members: Ensure all users in the Circle are invited to the room.
5. **Membership Synchronization (`lib/pages/circles/circle_detail.dart`):** Add hooks to update story room invitations whenever a user is added to or removed from a Circle.
6. **Localization:** Add required strings to `lib/l10n/intl_en.arb`.

## Acceptance Criteria

- [ ] User can select one or more Circles when posting a story.
- [ ] Stories are only visible to members of the selected Circles.
- [ ] Visibility is enforced cross-client (verified by checking membership in another client like Element).
- [ ] Story rooms are encrypted by default.
- [ ] Circle membership changes are reflected in story room invitations (eventually or immediately).
- [ ] **AGPL Compliance:** All modified files must include the fork copyright header and a modification log entry with the current date.
- [ ] **AGPL Compliance:** SPDX-License-Identifier: AGPL-3.0-or-later is present.
- [ ] `CHANGELOG.md` updated with `[FORK]` entry.

## Technical Notes

- **Scalability:** Posting to multiple circles means sending the event to multiple rooms. Given the low frequency of story posts, this is an acceptable trade-off for protocol-level privacy.
- **Room Naming:** Suggested naming convention for circle story rooms: `story:[username]:[circle_name]`.
- **Permissions:** The room should be configured so only the owner can post (`m.room.power_levels`).

## Research References

- Research Report: `documentation/issues/issue-circle-story-visibility-research.md`
- Matrix Spec: Room membership as access control.

---
*Generated by new-issue-agpl*
