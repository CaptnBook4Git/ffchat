# Simplify Onboarding: "Easy Mode" for Login/Signup with Default Homeserver

**Type:** Enhancement

## Description

The current onboarding process exposes the concept of "homeservers" immediately, which can be confusing for non-technical users. This issue proposes a simplified "Easy Mode" for both Login and Sign Up flows, which defaults to a pre-configured homeserver while offering an "Expert Mode" for users who need to select a custom server.

The goal is to split the experience:
1.  **Simple (Default)**: User interacts only with the pre-defined homeserver. The server details are shown subtly at the bottom.
2.  **Expert**: The existing full homeserver selection list.

## Current Behavior

Currently, clicking "Sign In" or "Create Account" takes the user to `SignInPage`, which immediately displays a list of public homeservers and a search bar. Users must understand they need to pick a server.

- File: `lib/pages/sign_in/sign_in_page.dart`
- Behavior: Fetches and lists servers from `servers.joinmatrix.org`.

## Expected Behavior

When a specific default homeserver is configured via an environment variable (e.g., `DEFAULT_HOMESERVER`):

1.  **Simplified UI**: The `SignInPage` should hide the server list and search bar by default.
2.  **Direct Action**: It should present a clean login/registration form for the configured default server.
3.  **Footer Information**: A small footer should display:
    > "Your account will be created on [Server URL]" (for Sign Up)
    > "Logging in to [Server URL]" (for Login)
4.  **Expert Option**: The footer should contain a link/button: "Choose another server" or "Expert Mode".
    - Clicking this reveals the original server selection UI.

## Motivation

To improve user acquisition by removing friction during onboarding. Many users do not know what a "homeserver" is and just want to use the app. A pre-defined server simplifies this while keeping the decentralized option available for those who need it.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/config/setting_keys.dart` | `AppSettings` | Needs to support `String.fromEnvironment` for `defaultHomeserver` to allow build-time configuration. |
| `lib/pages/sign_in/sign_in_page.dart` | `SignInPage` | Main UI file to modify. Needs to handle the "Simple" vs "Expert" state. |
| `lib/pages/sign_in/view_model/sign_in_view_model.dart` | `SignInViewModel` | Logic for initializing the view. Might need to auto-select the default server in Simple Mode. |

### Current Implementation
The `defaultHomeserver` is currently a hardcoded string ('matrix.org') or loaded from `config.json` on web. It does not automatically trigger a simplified UI mode.

### Dependencies
- `SignInPage` uses `PublicHomeserverData` to display the list.
- `AppConfig` defines the source of the homeserver list.

## Upstream Status

- Related upstream issue: None found for this specific "Easy Mode".
- Upstream PR: None.
- Sync status: Fork specific feature.

## Implementation Plan

1.  **Configuration Update**:
    - Modify `lib/config/setting_keys.dart` to load `defaultHomeserver` from `const String.fromEnvironment('DEFAULT_HOMESERVER')`.
    
2.  **UI Modification (`SignInPage`)**:
    - Add a state variable `isSimpleMode` (defaults to true if `DEFAULT_HOMESERVER` is set).
    - If `isSimpleMode` is true:
        - Hide `HomeserverPicker` / List.
        - Show a simplified header/banner.
        - Render the `CheckHomeserver` flow UI directly for the default server (or a button to proceed).
        - Add the requested footer with the "Change Server" link.
    - If "Change Server" is clicked, set `isSimpleMode = false` and show the original UI.

3.  **Build Integration**:
    - Document that the app should be built with `--dart-define=DEFAULT_HOMESERVER=chat.example.com` to enable this mode.

## Acceptance Criteria

- [ ] `DEFAULT_HOMESERVER` environment variable triggers the new behavior.
- [ ] Sign Up screen shows "Your account is created on [Server]" in the footer.
- [ ] Login screen shows "Logging in to [Server]" in the footer.
- [ ] "Choose another server" link correctly switches to the full server list.
- [ ] Standard behavior remains unchanged if no `DEFAULT_HOMESERVER` is provided (or if configured to be explicitly disabled).
- [ ] AGPL headers updated on all modified files.
- [ ] CHANGELOG.md updated with [FORK] entry.

## Technical Notes

- Flutter's `String.fromEnvironment` is constant and works at build time, which is ideal for white-labeling or specific deployments.
- Ensure the simplified view still allows for SSO or Password logic to trigger correctly based on the default server's capabilities.

## Research References

- Flutter Dart Define: https://dart.dev/guides/environment-declarations
