pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property string placeholderText: "ENTER PASSWORD"
  readonly property color accent: "#bfd630"
  property date now: new Date()
  property real seconds: 0
  property double animationStarted: Date.now()
  readonly property bool wide: width / Math.max(1, height) >= 1.3
  readonly property real panelCenter: wide ? width * 0.74 : width * 0.5
  onLoadBackgroundChanged: if (loadBackground) animationStarted = Date.now()
  Timer {
    interval: 33
    running: root.loadBackground && root.visible
    repeat: true
    onTriggered: root.seconds = (Date.now() - root.animationStarted) / 1000
  }
  readonly property int fieldWidth: Math.min(381, width - 48)
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: Border.surfaceSpec("aphex-lock", "border-active",
    errorState ? "#f08070" : accent, 1, "border-alpha")

  Timer {
    interval: 1000
    running: root.loadBackground && root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  property string pendingPowerAction: ""
  signal powerActionRequested(string action)
  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  // Restore focus after a suspend/VT switch and after PAM re-enables input.
  function restorePasswordFocus() {
    if (inputEnabled && passwordInput.enabled && !passwordInput.activeFocus)
      forcePasswordFocus()
  }
  Window.onActiveFocusItemChanged: Qt.callLater(restorePasswordFocus)
  Window.onActiveChanged: if (Window.active) Qt.callLater(restorePasswordFocus)
  onAuthenticatingPasswordChanged: Qt.callLater(restorePasswordFocus)

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: "Iosevka"
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: "#0c1009"

    Image {
      id: logoTexture
      source: "assets/aphexascii.png"
      visible: false
    }
    ShaderEffect {
      anchors.fill: parent
      property var source: logoTexture
      property real seconds: root.seconds
      property real aspect: width / Math.max(1, height)
      property real pixelHeight: height
      property real heroX: root.wide ? -aspect * 0.235 : 0
      property real heroY: root.wide ? -0.04 : -0.22
      property real heroScale: root.wide ? 0.92 : 0.62
      fragmentShader: "assets/lock-crt.frag.qsb"
    }
    Text {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: Math.max(24, root.width * 0.035)
      text: "APHEX TWIN  /  SYRO\nSECURE TERMINAL"
      font.family: "Iosevka"
      font.pixelSize: 13
      font.letterSpacing: 3
      lineHeight: 1.6
      color: root.accent
      opacity: 0.6
    }
    Text {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Math.max(24, root.width * 0.035)
      text: "●  SESSION LOCKED  /  AUTH REQUIRED"
      font.family: "Iosevka"
      font.pixelSize: 11
      font.letterSpacing: 2
      color: root.accent
      opacity: 0.5
    }

    Column {
      x: root.panelCenter - width / 2
      anchors.bottom: inputField.top
      anchors.bottomMargin: 26
      spacing: 2
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(root.now, "HH:mm")
        font.family: "Iosevka"
        font.pixelSize: Math.min(100, root.height * 0.13)
        font.weight: Font.Light
        color: root.accent
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(root.now, "yyyy-MM-dd  ddd").toUpperCase()
        font.family: "Iosevka"
        font.pixelSize: 19
        font.letterSpacing: 2
        color: root.accent
        opacity: 0.8
      }
    }

    Text {
      anchors.horizontalCenter: inputField.horizontalCenter
      anchors.top: inputField.bottom
      anchors.topMargin: 20
      text: root.fingerprintConfigured ? "PASSWORD  /  TOUCH ID" : "ENCRYPTED SESSION  /  STANDBY"
      font.family: "Iosevka"
      font.pixelSize: 12
      font.letterSpacing: 3
      color: root.accent
      opacity: 0.45
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    BorderSurface {
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      x: root.panelCenter - width / 2
      y: parent.height * (root.wide ? 0.55 : 0.76)
      color: "#ed0b1209"
      borderSpec: root.inputBorderSpec
      radius: 2
      clip: true

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: root.accent
        selectionColor: Qt.alpha(root.accent, 0.25)
        selectedTextColor: root.accent
        font.family: "Iosevka"
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: root.accent
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.isAutoRepeat && event.key !== Qt.Key_Backspace && event.key !== Qt.Key_Delete) {
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? root.accent : (root.failureMessage.length > 0 ? "#f08070" : Qt.alpha(root.accent, 0.55))
        font.family: "Iosevka"
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      // Matches hyprlock, which draws its fingerprint icon in the same spot.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: Qt.alpha(root.accent, 0.55)
        font.family: "Iosevka"
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    Column {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: Math.max(24, root.width * 0.035)
      spacing: 12

      Text {
        textFormat: Text.PlainText
        text: root.pendingPowerAction === "" ? "" :
          (root.pendingPowerAction === "reboot" ? "Restart? Unsaved work may be lost." : "Shut down? Unsaved work may be lost.")
        visible: root.pendingPowerAction !== ""
        color: root.accent
        font.family: "Iosevka"
        font.pixelSize: 14
      }
      Row {
        spacing: 14
        Repeater {
          model: root.pendingPowerAction === "" ? ["Restart", "Shut down"] : ["Confirm", "Cancel"]
          delegate: Rectangle {
            id: powerButton
            required property string modelData
            width: powerLabel.implicitWidth + 30
            height: 42
            color: powerMouse.containsMouse ? "#33402a" : "#ed0b1209"
            border.color: root.accent
            radius: 2
            Text {
              id: powerLabel
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: powerButton.modelData
              color: root.accent
              font.family: "Iosevka"
              font.pixelSize: 14
            }
            MouseArea {
              id: powerMouse
              anchors.fill: parent
              hoverEnabled: true
              enabled: root.inputEnabled
              onEntered: root.wakeRequested()
              onClicked: {
                root.wakeRequested()
                if (powerButton.modelData === "Restart") root.pendingPowerAction = "reboot"
                else if (powerButton.modelData === "Shut down") root.pendingPowerAction = "poweroff"
                else if (powerButton.modelData === "Confirm") {
                  root.powerActionRequested(root.pendingPowerAction)
                  root.pendingPowerAction = ""
                } else root.pendingPowerAction = ""
                root.restorePasswordFocus()
              }
            }
          }
        }
      }
    }
  }
}
