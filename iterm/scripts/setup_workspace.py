#!/usr/bin/env python3
"""
Sets up an iTerm2 workspace with the following layout:

  +------------+------+-------+
  |            |      | r-top |
  |    left    | mid  +-------+
  |   (50%)    |(25%) | r-bot |
  +------------+------+-------+
                      |<-25%->|

- Left pane: 50% width
- Middle pane: 25% width
- Right pane: 25% width, split horizontally (top/bottom each 50% height)

After layout is established:
- All panes cd to the left pane's directory
- right-top cds to ascend-backend subdirectory (if it exists)
- right-bottom cds to ascend-ui subdirectory (if it exists)
"""
import os
import iterm2


def is_target_layout(root):
    """
    Check if the root is our target layout:
    - A vertical splitter with 3 children
    - First two children are sessions
    - Third child is a horizontal splitter with 2 session children
    """
    if root is None:
        return False

    # Must be a vertical splitter (vertical dividers, side-by-side children)
    if not getattr(root, "vertical", None):
        return False

    children = getattr(root, "children", None)
    if not children or len(children) != 3:
        return False

    # First two should be sessions
    if not hasattr(children[0], "session_id"):
        return False
    if not hasattr(children[1], "session_id"):
        return False

    # Third should be a horizontal splitter (vertical=False) with 2 sessions
    right_child = children[2]
    if not hasattr(right_child, "children"):  # Not a splitter
        return False
    if getattr(right_child, "vertical", True):  # Should be horizontal (vertical=False)
        return False
    if len(right_child.children) != 2:
        return False
    if not hasattr(right_child.children[0], "session_id"):
        return False
    if not hasattr(right_child.children[1], "session_id"):
        return False

    return True


def count_sessions(root):
    """Recursively count all sessions under root."""
    if root is None:
        return 0
    # If it's a session (has session_id, no children), count as 1
    if hasattr(root, "session_id") and not hasattr(root, "children"):
        return 1
    # If it's a splitter, count children recursively
    if hasattr(root, "children"):
        return sum(count_sessions(child) for child in root.children)
    return 0


def get_single_session(root):
    """Get the single session from root, regardless of structure."""
    if root is None:
        return None
    # If root IS a session
    if hasattr(root, "session_id") and not hasattr(root, "children"):
        return root
    # If root is a splitter with sessions
    if hasattr(root, "sessions"):
        sessions = root.sessions
        if len(sessions) == 1:
            return sessions[0]
    return None


def get_all_sessions(root):
    """
    Extract sessions from the target layout.
    Returns (left_sess, mid_sess, right_top_sess, right_bot_sess) or None.
    """
    if not is_target_layout(root):
        return None

    left_sess = root.children[0]
    mid_sess = root.children[1]
    right_splitter = root.children[2]
    right_top_sess = right_splitter.children[0]
    right_bot_sess = right_splitter.children[1]

    return (left_sess, mid_sess, right_top_sess, right_bot_sess)


def get_sessions_fallback(root):
    """
    Attempt to extract 4 sessions from a layout that might not exactly match
    the expected structure. Assumes sessions are in left-to-right, top-to-bottom order.
    Returns (left_sess, mid_sess, right_top_sess, right_bot_sess) or None.
    """
    if not hasattr(root, "sessions"):
        return None

    sessions = root.sessions
    if len(sessions) != 4:
        return None

    # Sessions are typically returned in order: left-to-right, top-to-bottom
    # For our layout: left, middle, right-top, right-bottom
    return tuple(sessions)


async def create_splits(session):
    """
    Starting from a single session, create the target layout.
    Returns (left_sess, mid_sess, right_top_sess, right_bot_sess).
    """
    # The original session becomes the left pane
    left_sess = session

    # Split vertically (vertical=True means vertical divider) to create middle pane
    mid_sess = await left_sess.async_split_pane(vertical=True)

    # Split middle again to create right pane
    right_sess = await mid_sess.async_split_pane(vertical=True)

    # Split right pane horizontally (vertical=False means horizontal divider)
    right_bot_sess = await right_sess.async_split_pane(vertical=False)
    right_top_sess = right_sess  # The original right session is now the top

    return (left_sess, mid_sess, right_top_sess, right_bot_sess)


async def resize_panes(tab, left_sess, mid_sess, right_top_sess, right_bot_sess):
    """
    Resize panes to 50-25-25 layout with right pane split 50-50 vertically.
    """
    # Read current dimensions
    left_cols = await left_sess.async_get_variable("session.columns")
    mid_cols = await mid_sess.async_get_variable("session.columns")
    right_cols = await right_top_sess.async_get_variable("session.columns")

    total_cols = int(left_cols) + int(mid_cols) + int(right_cols)
    if total_cols <= 0:
        print("Could not determine total columns.")
        return

    # Calculate target widths: 50%, 25%, 25%
    target_left = total_cols // 2
    remaining = total_cols - target_left
    target_mid = remaining // 2
    target_right = remaining - target_mid

    # Get row counts for height calculations
    left_rows = left_sess.grid_size.height
    mid_rows = mid_sess.grid_size.height
    right_top_rows = right_top_sess.grid_size.height
    right_bot_rows = right_bot_sess.grid_size.height

    # Calculate right pane heights (50-50 split)
    total_right_rows = right_top_rows + right_bot_rows
    target_right_top_rows = total_right_rows // 2
    target_right_bot_rows = total_right_rows - target_right_top_rows

    # Set preferred sizes
    left_sess.preferred_size = iterm2.Size(target_left, left_rows)
    mid_sess.preferred_size = iterm2.Size(target_mid, mid_rows)
    right_top_sess.preferred_size = iterm2.Size(target_right, target_right_top_rows)
    right_bot_sess.preferred_size = iterm2.Size(target_right, target_right_bot_rows)

    await tab.async_update_layout()


async def setup_directories(left_sess, mid_sess, right_top_sess, right_bot_sess):
    """
    CD all panes to left pane's directory, then:
    - right-top goes to ascend-backend if it exists
    - right-bottom goes to ascend-ui if it exists
    """
    # Get the left pane's working directory
    root_dir = await left_sess.async_get_variable("session.path")

    if not root_dir:
        print("Could not determine the root directory from the left pane.")
        return

    # CD middle and right panes to root
    await mid_sess.async_send_text(f"cd {root_dir}\n")
    await right_top_sess.async_send_text(f"cd {root_dir}\n")
    await right_bot_sess.async_send_text(f"cd {root_dir}\n")

    # Check for subdirectories and CD if they exist
    backend_path = os.path.join(root_dir, "ascend-backend")
    ui_path = os.path.join(root_dir, "ascend-ui")

    if os.path.isdir(backend_path):
        await right_top_sess.async_send_text(f"cd {backend_path}\n")

    if os.path.isdir(ui_path):
        await right_bot_sess.async_send_text(f"cd {ui_path}\n")


async def main(connection):
    app = await iterm2.async_get_app(connection)
    window = app.current_terminal_window
    if window is None:
        print("No current iTerm2 window.")
        return

    tab = window.current_tab
    if tab is None:
        print("No current tab.")
        return

    root = tab.root
    session_count = count_sessions(root)
    print(f"Detected {session_count} session(s) in current tab.")

    # Check if already in target layout (or close to it with 4 sessions)
    if is_target_layout(root) or session_count == 4:
        print("Layout appears to match target (4 sessions). Proceeding...")
        sessions = get_all_sessions(root)
        if sessions is None:
            sessions = get_sessions_fallback(root)
        if sessions is None:
            print("Error: Could not extract sessions from layout.")
            print(tab.pretty_str())
            return

        left_sess, mid_sess, right_top_sess, right_bot_sess = sessions

        print("Resizing panes to 50-25-25 layout...")
        await resize_panes(tab, left_sess, mid_sess, right_top_sess, right_bot_sess)

        print("Setting up directories...")
        await setup_directories(left_sess, mid_sess, right_top_sess, right_bot_sess)
        print("Workspace setup complete.")
        return

    # Check if single session - we can create the layout
    if session_count == 1:
        single_session = get_single_session(root)
        if single_session is None:
            print("Error: Could not get the single session.")
            print(tab.pretty_str())
            return

        print("Single session detected. Creating splits...")
        await create_splits(single_session)

        # Re-fetch the app state after splits to get fresh session references
        app = await iterm2.async_get_app(connection)
        window = app.current_terminal_window
        tab = window.current_tab
        root = tab.root

        print("Splits created. Current layout:")
        print(tab.pretty_str())

        # Get fresh session references from the new layout
        sessions = get_all_sessions(root)
        if sessions is None:
            print("Layout doesn't exactly match expected structure, trying fallback...")
            sessions = get_sessions_fallback(root)
            if sessions is None:
                print(f"Error: Could not extract 4 sessions. Found {count_sessions(root)} sessions.")
                return
            print("Successfully extracted sessions using fallback method.")

        left_sess, mid_sess, right_top_sess, right_bot_sess = sessions

        print("Resizing panes to 50-25-25 layout...")
        await resize_panes(tab, left_sess, mid_sess, right_top_sess, right_bot_sess)

        print("Setting up directories...")
        await setup_directories(left_sess, mid_sess, right_top_sess, right_bot_sess)

        print("Workspace setup complete.")
        return

    # Some other layout - exit
    print("Current tab has an unexpected layout. Cannot proceed.")
    print("Expected: 1 session (to create layout) OR 4 sessions in target layout.")
    print(f"Found: {session_count} sessions")
    print("\nCurrent layout:")
    print(tab.pretty_str())


iterm2.run_until_complete(main)
