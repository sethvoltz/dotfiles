#!/usr/bin/env python3
import iterm2


def is_flat_three_pane_vertical_split(root):
    # We want one splitter, vertical=True, with exactly 3 Session children (no nested splitters)
    if root is None:
        return False
    if not getattr(root, "vertical", None):
        return False
    children = getattr(root, "children", None)
    if not children or len(children) != 3:
        return False
    # Child is either Splitter or Session; Sessions have session_id
    for ch in children:
        if hasattr(ch, "children"):  # Splitter
            return False
        if not hasattr(ch, "session_id"):  # Not a Session
            return False
    return True


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
    if not is_flat_three_pane_vertical_split(root):
        print("This tab is not a simple 3-up horizontal layout (3 side-by-side panes).")
        print(
            "Tip: this expects one vertical splitter with exactly 3 session children."
        )
        # Helpful for debugging your layout:
        print(tab.pretty_str())
        return

    left_sess, mid_sess, right_sess = root.children  # spatial order for a flat splitter

    # Read current widths in columns
    left_cols = await left_sess.async_get_variable("session.columns")
    mid_cols = await mid_sess.async_get_variable("session.columns")
    right_cols = await right_sess.async_get_variable("session.columns")

    total = int(left_cols) + int(mid_cols) + int(right_cols)
    if total <= 0:
        print("Could not determine total columns.")
        return

    # Targets that sum exactly to total
    target_left = total // 2
    remaining = total - target_left
    target_mid = remaining // 2
    target_right = remaining - target_mid

    # Preserve current row counts; only change width
    left_rows = left_sess.grid_size.height
    mid_rows = mid_sess.grid_size.height
    right_rows = right_sess.grid_size.height

    left_sess.preferred_size = iterm2.Size(target_left, left_rows)
    mid_sess.preferred_size = iterm2.Size(target_mid, mid_rows)
    right_sess.preferred_size = iterm2.Size(target_right, right_rows)

    await tab.async_update_layout()


iterm2.run_until_complete(main)
