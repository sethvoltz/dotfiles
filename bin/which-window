#!/usr/bin/env python

import time
from Quartz import CGWindowListCopyWindowInfo, kCGWindowListExcludeDesktopElements, kCGNullWindowID
from Foundation import NSSet, NSMutableSet

wl1 = CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID)
print 'Move target window'
time.sleep(5)
wl2 = CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID)

w = NSMutableSet.setWithArray_(wl1)
w.minusSet_(NSSet.setWithArray_(wl2))
print '\nList of windows that moved:'
print w
print '\n'

