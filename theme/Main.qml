import QtQuick
import SddmComponents 2.0

Rectangle {
    id: root

    width: 1280
    height: 720
    color: surfaceColor

    readonly property bool isPrimaryScreen: (typeof primaryScreen === "undefined") ? true : primaryScreen

    readonly property string dateLocaleName: (typeof config !== "undefined" && config && config.dateLocale)
        ? String(config.dateLocale) : "en_US"
    readonly property string dateFormatStr: (typeof config !== "undefined" && config && config.dateFormat)
        ? String(config.dateFormat) : "dddd, MMMM d"
    readonly property string timeFormatStr: (typeof config !== "undefined" && config && config.timeFormat)
        ? String(config.timeFormat) : "HH:mm"
    readonly property var uiLocale: Qt.locale(dateLocaleName)

    readonly property string fontFamily: (typeof config !== "undefined" && config && config.fontFamily)
        ? String(config.fontFamily) : "Adwaita Sans"
    readonly property int cornerRadius: {
        var val = (typeof config !== "undefined" && config && config.cornerRadius !== undefined)
            ? parseInt(config.cornerRadius, 10) : 16
        return isNaN(val) ? 16 : Math.max(4, Math.min(32, val))
    }
    readonly property real configuredGlassOpacity: {
        var val = (typeof config !== "undefined" && config && config.glassOpacity !== undefined)
            ? Number(config.glassOpacity) : 0.78
        return isNaN(val) ? 0.78 : Math.max(0.2, Math.min(0.95, val))
    }

    function pickColor(paletteItem, propName, cfgKey, fallbackHex) {
        if (paletteItem && paletteItem[propName] !== undefined)
            return paletteItem[propName]
        if (typeof config !== "undefined" && config && config[cfgKey])
            return config[cfgKey]
        return fallbackHex
    }

    // Dynamic Noctalia palette with theme.conf defaults as fallback
    readonly property color surfaceColor: pickColor(paletteLoader.item, "surfaceColor", "surfaceColor", "#070707")
    readonly property color panelBaseColor: pickColor(paletteLoader.item, "panelBaseColor", "panelBaseColor", "#0d0d0d")
    readonly property color panelFocusBaseColor: pickColor(paletteLoader.item, "panelFocusBaseColor", "panelFocusBaseColor", "#151515")
    readonly property color panelHoverBaseColor: pickColor(paletteLoader.item, "panelHoverBaseColor", "panelHoverBaseColor", "#181818")
    readonly property color primaryColor: pickColor(paletteLoader.item, "primaryColor", "primaryColor", "#ff4d4d")
    readonly property color primaryForeground: pickColor(paletteLoader.item, "primaryForeground", "primaryForeground", "#090909")
    readonly property color tertiaryColor: pickColor(paletteLoader.item, "tertiaryColor", "tertiaryColor", "#b85c5c")
    readonly property color errorColor: pickColor(paletteLoader.item, "errorColor", "errorColor", "#ff5c5c")
    readonly property color textPrimary: pickColor(paletteLoader.item, "textPrimary", "textPrimary", "#eeeeee")
    readonly property color textSecondary: pickColor(paletteLoader.item, "textSecondary", "textSecondary", "#d8d8d8")
    readonly property color textMuted: pickColor(paletteLoader.item, "textMuted", "textMuted", "#7f7f7f")

    readonly property color panelColor: Qt.rgba(panelBaseColor.r, panelBaseColor.g, panelBaseColor.b, configuredGlassOpacity)
    readonly property color panelFocusColor: Qt.rgba(panelFocusBaseColor.r, panelFocusBaseColor.g, panelFocusBaseColor.b, 0.90)
    readonly property color panelHoverColor: Qt.rgba(panelHoverBaseColor.r, panelHoverBaseColor.g, panelHoverBaseColor.b, 0.88)

    property bool isAuthenticating: false
    property string statusText: ""
    property bool statusIsError: false
    property bool triedFallbackWallpaper: false
    property bool triedFallbackAvatar: false
    property bool triedFallbackPalette: false

    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel && sessionModel.lastIndex >= 0)
        ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel && userModel.lastIndex >= 0)
        ? userModel.lastIndex : 0

    readonly property bool capsLockOn: (typeof keyboard !== "undefined" && keyboard && keyboard.capsLock === true)

    function resolveAssetUrl(pathStr) {
        if (!pathStr || pathStr.length === 0)
            return ""
        if (pathStr.indexOf("file://") === 0 || pathStr.indexOf("qrc:/") === 0)
            return String(pathStr)
        if (pathStr.charAt(0) === "/")
            return "file://" + pathStr
        return String(Qt.resolvedUrl(pathStr))
    }

    function primaryWallpaperUrl() {
        var cfgBg = (typeof config !== "undefined" && config && config.background)
            ? String(config.background) : "/var/lib/noctalia-sddm/wallpaper.png"
        return resolveAssetUrl(cfgBg)
    }

    function fallbackWallpaperUrl() {
        var cfgFallback = (typeof config !== "undefined" && config && config.fallbackBackground)
            ? String(config.fallbackBackground) : "wallpaper.png"
        return resolveAssetUrl(cfgFallback)
    }

    function primaryPaletteUrl() {
        var cfgPal = (typeof config !== "undefined" && config && config.palette)
            ? String(config.palette) : "/var/lib/noctalia-sddm/Palette.qml"
        return resolveAssetUrl(cfgPal)
    }

    function fallbackPaletteUrl() {
        var cfgFallback = (typeof config !== "undefined" && config && config.fallbackPalette)
            ? String(config.fallbackPalette) : "Palette.qml"
        return resolveAssetUrl(cfgFallback)
    }

    function currentSessionName() {
        if (sessionRepeater.count > 0 && sessionIndex >= 0 && sessionIndex < sessionRepeater.count) {
            var item = sessionRepeater.itemAt(sessionIndex)
            if (item && item.entryName.length > 0)
                return item.entryName
        }
        return "Session"
    }

    function cycleSession() {
        if (sessionRepeater.count > 1) {
            sessionIndex = (sessionIndex + 1) % sessionRepeater.count
        }
    }

    function currentUsername() {
        if (userRepeater.count > 0 && userIndex >= 0 && userIndex < userRepeater.count) {
            var item = userRepeater.itemAt(userIndex)
            if (item && item.loginName.length > 0)
                return item.loginName
        }
        if (typeof userModel !== "undefined" && userModel && userModel.lastUser && userModel.lastUser.length > 0)
            return userModel.lastUser
        return "User"
    }

    function currentDisplayName() {
        if (userRepeater.count > 0 && userIndex >= 0 && userIndex < userRepeater.count) {
            var item = userRepeater.itemAt(userIndex)
            if (item) {
                if (item.displayName.length > 0)
                    return item.displayName
                if (item.loginName.length > 0)
                    return item.loginName
            }
        }
        return currentUsername()
    }

    function currentAvatarUrl() {
        if (userRepeater.count > 1 && userIndex >= 0 && userIndex < userRepeater.count) {
            var item = userRepeater.itemAt(userIndex)
            if (item && item.iconUrl.length > 0 && item.iconUrl.indexOf(".face.icon") === -1)
                return resolveAssetUrl(item.iconUrl)
        }
        var cfgAvatar = (typeof config !== "undefined" && config && config.avatar)
            ? String(config.avatar) : "/var/lib/noctalia-sddm/avatar.png"
        return resolveAssetUrl(cfgAvatar)
    }

    function fallbackAvatarUrl() {
        var cfgFallback = (typeof config !== "undefined" && config && config.fallbackAvatar)
            ? String(config.fallbackAvatar) : "avatar.png"
        return resolveAssetUrl(cfgFallback)
    }

    function cycleUser() {
        if (userRepeater.count > 1) {
            userIndex = (userIndex + 1) % userRepeater.count
            triedFallbackAvatar = false
            avatarImg.source = currentAvatarUrl()
            password.text = ""
            statusText = ""
            statusIsError = false
            password.forceActiveFocus()
        }
    }

    function currentLayoutLabel() {
        if (typeof keyboard !== "undefined" && keyboard && keyboard.enabled
                && keyboard.layouts && keyboard.layouts.length > 0) {
            var idx = Math.max(0, Math.min(keyboard.currentLayout, keyboard.layouts.length - 1))
            var layout = keyboard.layouts[idx]
            if (layout && layout.shortName)
                return String(layout.shortName).toUpperCase()
            if (layout && layout.longName)
                return String(layout.longName).slice(0, 3).toUpperCase()
        }
        return ""
    }

    function cycleKeyboardLayout() {
        if (typeof keyboard !== "undefined" && keyboard && keyboard.enabled
                && keyboard.layouts && keyboard.layouts.length > 1) {
            keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    function login() {
        if (isAuthenticating || password.text.length === 0)
            return

        isAuthenticating = true
        statusIsError = false
        statusText = "Signing in..."
        sddm.login(currentUsername(), password.text, sessionIndex)
    }

    // Dynamic Noctalia palette loader (falls back cleanly if Palette.qml is absent)
    Loader {
        id: paletteLoader
        active: true
        source: root.primaryPaletteUrl()

        function tryFallback() {
            if (status === Loader.Error && !root.triedFallbackPalette) {
                root.triedFallbackPalette = true
                var fb = String(root.fallbackPaletteUrl())
                if (fb.length > 0 && fb !== String(source))
                    source = fb
            }
        }

        onStatusChanged: tryFallback()
        Component.onCompleted: tryFallback()
    }

    // Hidden model repeaters for safe Qt6 lookups
    Repeater {
        id: sessionRepeater
        model: (typeof sessionModel !== "undefined") ? sessionModel : null
        delegate: Item {
            readonly property string entryName: (typeof model !== "undefined" && model && model.name)
                ? String(model.name) : ""
        }
    }

    Repeater {
        id: userRepeater
        model: (typeof userModel !== "undefined") ? userModel : null
        delegate: Item {
            readonly property string loginName: (typeof model !== "undefined" && model && model.name)
                ? String(model.name) : ""
            readonly property string displayName: (typeof model !== "undefined" && model && model.realName)
                ? String(model.realName) : ""
            readonly property string iconUrl: (typeof model !== "undefined" && model && model.icon)
                ? String(model.icon) : ""
        }
    }

    Connections {
        target: (typeof sddm !== "undefined") ? sddm : null

        function onLoginFailed() {
            root.isAuthenticating = false
            root.statusIsError = true
            root.statusText = "Incorrect password"
            password.text = ""
            shakeAnimation.restart()
            password.forceActiveFocus()
        }

        function onLoginSucceeded() {
            root.isAuthenticating = false
            root.statusIsError = false
            root.statusText = ""
            password.text = ""
        }

        function onInformationMessage(message) {
            if (message && message.length > 0) {
                root.isAuthenticating = false
                root.statusIsError = true
                root.statusText = message
            }
        }
    }

    // Subtle dark gradient backdrop if wallpaper has not been synced yet
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.surfaceColor, 1.8) }
            GradientStop { position: 0.55; color: root.surfaceColor }
            GradientStop { position: 1.0; color: Qt.darker(root.surfaceColor, 1.4) }
        }
    }

    // Pre-blurred Noctalia wallpaper (clean Gaussian blur rendered by noctalia-sddm-sync)
    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: root.primaryWallpaperUrl()
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: false
        visible: status === Image.Ready

        function tryFallback() {
            if (status === Image.Error && !root.triedFallbackWallpaper) {
                root.triedFallbackWallpaper = true
                var fallback = String(root.fallbackWallpaperUrl())
                if (fallback.length > 0 && fallback !== String(source))
                    source = fallback
            }
        }

        onStatusChanged: tryFallback()
        Component.onCompleted: tryFallback()
    }

    // Subtle legibility vignette (keeps dark artwork rich and clean)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, 0.12) }
            GradientStop { position: 0.5; color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, 0.22) }
            GradientStop { position: 1.0; color: Qt.rgba(root.surfaceColor.r * 0.5, root.surfaceColor.g * 0.5, root.surfaceColor.b * 0.5, 0.40) }
        }
    }

    // Click anywhere on background to restore password focus
    MouseArea {
        anchors.fill: parent
        enabled: root.isPrimaryScreen
        onClicked: password.forceActiveFocus()
    }

    // Top-right macOS-style status pills (Session + optional Keyboard Layout)
    Row {
        id: topBar
        visible: root.isPrimaryScreen
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 22
        anchors.rightMargin: 28
        spacing: 10
        z: 10

        Rectangle {
            id: layoutPill
            visible: typeof keyboard !== "undefined" && keyboard && keyboard.enabled
                     && keyboard.layouts && keyboard.layouts.length > 1
                     && root.currentLayoutLabel().length > 0
            height: 32
            width: layoutRow.implicitWidth + 24
            radius: root.cornerRadius
            color: layoutMouse.containsMouse ? root.panelHoverColor : root.panelColor
            border.width: 0

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                id: layoutRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: root.currentLayoutLabel()
                    color: root.textSecondary
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }

            MouseArea {
                id: layoutMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.cycleKeyboardLayout()
                    password.forceActiveFocus()
                }
            }
        }

        Rectangle {
            id: sessionPill
            height: 32
            width: sessionRow.implicitWidth + 26
            radius: root.cornerRadius
            color: sessionMouse.containsMouse ? root.panelHoverColor : root.panelColor
            border.width: 0

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.primaryColor
                }

                Text {
                    text: root.currentSessionName()
                    color: root.textSecondary
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: sessionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: sessionRepeater.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    root.cycleSession()
                    password.forceActiveFocus()
                }
            }
        }
    }

    // Upper-center macOS lock screen clock & date
    Column {
        id: clockBlock
        visible: root.isPrimaryScreen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(48, Math.round(parent.height * 0.10))
        spacing: 2

        property date now: new Date()

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: clockBlock.now = new Date()
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: dateText.implicitWidth
            height: dateText.implicitHeight

            Text {
                x: 0
                y: 2
                text: dateText.text
                color: Qt.rgba(0, 0, 0, 0.48)
                font: dateText.font
            }

            Text {
                id: dateText
                text: clockBlock.now.toLocaleDateString(root.uiLocale, root.dateFormatStr)
                color: Qt.rgba(root.textSecondary.r, root.textSecondary.g, root.textSecondary.b, 0.92)
                font.family: root.fontFamily
                font.pixelSize: 21
                font.weight: Font.Medium
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: timeText.implicitWidth
            height: timeText.implicitHeight

            Text {
                x: 0
                y: 4
                text: timeText.text
                color: Qt.rgba(0, 0, 0, 0.52)
                font: timeText.font
            }

            Text {
                id: timeText
                text: clockBlock.now.toLocaleTimeString(root.uiLocale, root.timeFormatStr)
                color: Qt.rgba(root.textPrimary.r, root.textPrimary.g, root.textPrimary.b, 0.97)
                font.family: root.fontFamily
                font.pixelSize: Math.max(76, Math.min(104, Math.round(root.height * 0.11)))
                font.weight: Font.Bold
                font.letterSpacing: -2
            }
        }
    }

    // Lower-center macOS user avatar + matte password capsule
    Column {
        id: loginBlock
        visible: root.isPrimaryScreen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: Math.max(54, Math.round(parent.height * 0.095))
        width: 300
        spacing: 14

        // Circular avatar with sleek hairline ring (monogram fallback if no avatar exists)
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 92
            height: 92

            Rectangle {
                id: avatarFrame
                anchors.centerIn: parent
                width: 92
                height: 92
                radius: 46
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: 46
                    color: root.panelFocusColor
                    visible: avatarImg.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var name = root.currentDisplayName().trim()
                            return name.length > 0 ? name.charAt(0).toUpperCase() : "U"
                        }
                        color: root.textPrimary
                        font.family: root.fontFamily
                        font.pixelSize: 34
                        font.weight: Font.DemiBold
                    }
                }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: root.currentAvatarUrl()
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: false
                    visible: status === Image.Ready

                    function tryFallback() {
                        if (status === Image.Error && !root.triedFallbackAvatar) {
                            root.triedFallbackAvatar = true
                            var fallback = String(root.fallbackAvatarUrl())
                            if (fallback.length > 0 && fallback !== String(source))
                                source = fallback
                        }
                    }

                    onStatusChanged: tryFallback()
                    Component.onCompleted: tryFallback()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 46
                    color: "transparent"
                    border.width: root.isAuthenticating ? 1.5 : 1
                    border.color: root.isAuthenticating
                        ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.80)
                        : Qt.rgba(1, 1, 1, 0.09)

                    Behavior on border.color { ColorAnimation { duration: 160 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: userRepeater.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.cycleUser()
                }
            }
        }

        // Display name
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: userLabel.implicitWidth
            height: userLabel.implicitHeight

            Text {
                x: 0
                y: 2
                text: userLabel.text
                color: Qt.rgba(0, 0, 0, 0.55)
                font: userLabel.font
            }

            Text {
                id: userLabel
                text: root.currentDisplayName()
                color: root.textPrimary
                font.family: root.fontFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
        }

        // Matte password capsule with horizontal shake container
        Item {
            id: passwordContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: 284
            height: 46

            property real shakeOffset: 0
            transform: Translate { x: passwordContainer.shakeOffset }

            SequentialAnimation {
                id: shakeAnimation
                NumberAnimation { target: passwordContainer; property: "shakeOffset"; to: -10; duration: 48 }
                NumberAnimation { target: passwordContainer; property: "shakeOffset"; to: 10; duration: 48 }
                NumberAnimation { target: passwordContainer; property: "shakeOffset"; to: -7; duration: 45 }
                NumberAnimation { target: passwordContainer; property: "shakeOffset"; to: 7; duration: 45 }
                NumberAnimation { target: passwordContainer; property: "shakeOffset"; to: -3; duration: 40 }
                NumberAnimation { target: passwordContainer; property: "shakeOffset"; to: 3; duration: 40 }
                NumberAnimation { target: passwordContainer; property: "shakeOffset"; to: 0; duration: 40 }
            }

            Rectangle {
                id: passwordBox
                anchors.fill: parent
                radius: root.cornerRadius
                color: password.activeFocus ? root.panelFocusColor : root.panelColor
                border.width: 1.5
                border.color: {
                    if (root.statusIsError)
                        return root.errorColor
                    if (password.activeFocus)
                        return Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.75)
                    return "transparent"
                }

                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on border.color { ColorAnimation { duration: 160 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: submitButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter Password"
                    color: root.textMuted
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    opacity: password.text.length === 0 ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                TextInput {
                    id: password
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: submitButton.left
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    color: root.textPrimary
                    selectionColor: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.45)
                    selectedTextColor: root.textPrimary
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    echoMode: TextInput.Password
                    passwordCharacter: "\u2022"
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    focus: true
                    enabled: !root.isAuthenticating

                    onTextChanged: {
                        if (root.statusIsError && text.length > 0) {
                            root.statusIsError = false
                            root.statusText = ""
                        }
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.login()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            password.text = ""
                            root.statusIsError = false
                            root.statusText = ""
                            event.accepted = true
                        } else if (event.key === Qt.Key_F2) {
                            root.cycleSession()
                            event.accepted = true
                        }
                    }
                }

                // Inline circular submit arrow button
                Rectangle {
                    id: submitButton
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    radius: 15

                    readonly property bool hasInput: password.text.length > 0
                    readonly property bool hovered: submitMouse.containsMouse

                    opacity: (hasInput || hovered) ? 1.0 : 0.38
                    color: {
                        if (hovered && hasInput)
                            return root.primaryColor
                        if (hasInput)
                            return Qt.rgba(1, 1, 1, 0.16)
                        return Qt.rgba(1, 1, 1, 0.07)
                    }

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Canvas {
                        id: arrowCanvas
                        anchors.centerIn: parent
                        width: 14
                        height: 14

                        property color strokeColor: (submitButton.hovered && submitButton.hasInput)
                            ? root.primaryForeground
                            : root.textPrimary
                        onStrokeColorChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = strokeColor
                            ctx.lineWidth = 1.8
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"

                            ctx.beginPath()
                            ctx.moveTo(2.5, 7)
                            ctx.lineTo(11.5, 7)
                            ctx.moveTo(7.5, 3)
                            ctx.lineTo(11.5, 7)
                            ctx.lineTo(7.5, 11)
                            ctx.stroke()
                        }
                    }

                    MouseArea {
                        id: submitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: submitButton.hasInput ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (submitButton.hasInput)
                                root.login()
                            else
                                password.forceActiveFocus()
                        }
                    }
                }
            }
        }

        // Fixed-height status line so layout never jumps
        Item {
            width: parent.width
            height: 22

            Text {
                anchors.centerIn: parent
                text: {
                    if (root.statusText.length > 0)
                        return root.statusText
                    if (root.capsLockOn)
                        return "Caps Lock is on"
                    return ""
                }
                color: {
                    if (root.statusIsError)
                        return root.errorColor
                    if (root.statusText.length > 0)
                        return root.textSecondary
                    return root.tertiaryColor
                }
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                visible: text.length > 0
            }
        }
    }

    // Bottom macOS power action bar
    Row {
        id: bottomBar
        visible: root.isPrimaryScreen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        spacing: 30

        Loader {
            visible: (typeof sddm === "undefined") ? true : sddm.canSuspend
            sourceComponent: powerActionButton
            onLoaded: {
                item.label = "Sleep"
                item.iconType = "sleep"
                item.destructive = false
                item.actionFn = function() {
                    if (typeof sddm !== "undefined")
                        sddm.suspend()
                }
            }
        }

        Loader {
            visible: (typeof sddm === "undefined") ? true : sddm.canReboot
            sourceComponent: powerActionButton
            onLoaded: {
                item.label = "Restart"
                item.iconType = "restart"
                item.destructive = false
                item.actionFn = function() {
                    if (typeof sddm !== "undefined")
                        sddm.reboot()
                }
            }
        }

        Loader {
            visible: (typeof sddm === "undefined") ? true : sddm.canPowerOff
            sourceComponent: powerActionButton
            onLoaded: {
                item.label = "Shut Down"
                item.iconType = "shutdown"
                item.destructive = true
                item.actionFn = function() {
                    if (typeof sddm !== "undefined")
                        sddm.powerOff()
                }
            }
        }
    }

    Component {
        id: powerActionButton

        Column {
            id: btnRoot
            spacing: 7
            width: 68

            property string label: ""
            property string iconType: "shutdown"
            property bool destructive: false
            property var actionFn: null

            readonly property bool hovered: btnMouse.containsMouse
            readonly property bool pressed: btnMouse.pressed

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44
                height: 44

                Rectangle {
                    id: circleBg
                    anchors.fill: parent
                    radius: 22
                    scale: btnRoot.pressed ? 0.95 : (btnRoot.hovered ? 1.06 : 1.0)
                    color: {
                        if (btnRoot.hovered && btnRoot.destructive)
                            return Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.22)
                        if (btnRoot.hovered)
                            return root.panelHoverColor
                        return root.panelColor
                    }
                    border.width: 0

                    Behavior on scale { NumberAnimation { duration: 130 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Canvas {
                        id: iconCanvas
                        anchors.centerIn: parent
                        width: 20
                        height: 20

                        property color iconColor: {
                            if (btnRoot.hovered && btnRoot.destructive)
                                return root.primaryColor
                            if (btnRoot.hovered)
                                return root.textPrimary
                            return root.textSecondary
                        }
                        onIconColorChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = iconColor
                            ctx.lineWidth = 1.65
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"

                            if (btnRoot.iconType === "sleep") {
                                ctx.beginPath()
                                ctx.arc(10, 10, 6.2, 0.35 * Math.PI, 1.65 * Math.PI, false)
                                ctx.arc(13.2, 7.6, 5.0, 1.38 * Math.PI, 0.62 * Math.PI, true)
                                ctx.closePath()
                                ctx.stroke()
                            } else if (btnRoot.iconType === "restart") {
                                ctx.beginPath()
                                ctx.arc(10, 10, 6.0, -0.35 * Math.PI, 1.35 * Math.PI, false)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(11.6, 2.7)
                                ctx.lineTo(13.8, 5.1)
                                ctx.lineTo(10.8, 5.8)
                                ctx.stroke()
                            } else {
                                ctx.beginPath()
                                ctx.arc(10, 10.6, 5.8, -0.32 * Math.PI, 1.32 * Math.PI, false)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(10, 3.2)
                                ctx.lineTo(10, 9.6)
                                ctx.stroke()
                            }
                        }
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (btnRoot.actionFn)
                            btnRoot.actionFn()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btnRoot.label
                color: {
                    if (btnRoot.hovered && btnRoot.destructive)
                        return root.primaryColor
                    if (btnRoot.hovered)
                        return root.textPrimary
                    return root.textSecondary
                }
                font.family: root.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    Component.onCompleted: {
        if (isPrimaryScreen)
            password.forceActiveFocus()
    }
}
