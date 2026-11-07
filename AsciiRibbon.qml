import QtQuick

Item {
  id: root
  property bool reverse: false
  property bool running: false
  property color accent: "#bfd630"
  // One logo every 360px at 28px/s; resolution independent and seamless.
  property real tileWidth: height * 560 / 480 + 64
  property real phase: 0
  NumberAnimation on phase {
    from: 0
    to: 1
    duration: Math.round(root.tileWidth / 28 * 1000)
    loops: Animation.Infinite
    running: root.running
  }
  Image {
    id: textureImage
    source: "assets/aphexascii.png"
    visible: false
    smooth: true
  }
  ShaderEffect {
    anchors.fill: parent
    property var source: textureImage
    property color ink: root.accent
    property real tiles: width / root.tileWidth
    property real phase: root.reverse ? -root.phase : root.phase
    property real contentFraction: (root.tileWidth - 64) / root.tileWidth
    fragmentShader: "assets/ribbon.frag.qsb"
    opacity: 0.7
  }
}
