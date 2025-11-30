#!/bin/bash
#
# TaaOS Hot Corners Configuration
# Custom hot corner actions for productivity
#

# Top-Left: Show Activities
qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "ShowDesktopGrid"

# Top-Right: Show All Windows
qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "ExposeAll"

# Bottom-Left: Show Desktop
qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "ShowDesktop"

# Bottom-Right: Launch TaaOS AI
taaos-ai-gui &
