import QtQuick
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

// Output and input levels, which device each one uses, and a volume per app.
PanelBase {
  id: root

  title: "Audio"

  readonly property var nodes: Pipewire.nodes.values
  readonly property var sinks: nodes.filter(function(node) { return node.audio && node.isSink && !node.isStream })
  readonly property var sources: nodes.filter(function(node) { return node.audio && !node.isSink && !node.isStream })
  // A playback stream is one that sends audio out, so its isSink is false.
  readonly property var streams: nodes.filter(function(node) { return node.audio && node.isStream && !node.isSink })
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  function nodeLabel(node) {
    return node.description || node.nickname || node.name
  }

  function streamLabel(node) {
    var props = node.properties || {}
    return props["application.name"] || props["media.name"] || nodeLabel(node)
  }

  function volumeIcon(audio) {
    if (!audio || audio.muted || audio.volume <= 0) return String.fromCodePoint(0xF0581)
    if (audio.volume < 0.34) return String.fromCodePoint(0xF057F)
    if (audio.volume < 0.67) return String.fromCodePoint(0xF0580)
    return String.fromCodePoint(0xF057E)
  }

  PwObjectTracker { objects: root.sinks.concat(root.sources).concat(root.streams) }

  PanelSlider {
    label: root.sink ? root.nodeLabel(root.sink) : "No output"
    visible: !!root.sink
    icon: root.volumeIcon(root.sink ? root.sink.audio : null)
    value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
    dimmed: !!root.sink && !!root.sink.audio && root.sink.audio.muted
    onMoved: function(next) { root.sink.audio.volume = next }
    onIconClicked: root.sink.audio.muted = !root.sink.audio.muted
  }

  PanelSlider {
    label: root.source ? root.nodeLabel(root.source) : "No input"
    visible: !!root.source
    icon: String.fromCodePoint(root.source && root.source.audio && root.source.audio.muted ? 0xF036D : 0xF036C)
    value: root.source && root.source.audio ? root.source.audio.volume : 0
    dimmed: !!root.source && !!root.source.audio && root.source.audio.muted
    onMoved: function(next) { root.source.audio.volume = next }
    onIconClicked: root.source.audio.muted = !root.source.audio.muted
  }

  PanelHeading { text: "Apps"; visible: root.streams.length > 0 }

  Repeater {
    model: root.streams

    PanelSlider {
      required property var modelData
      label: root.streamLabel(modelData)
      icon: root.volumeIcon(modelData.audio)
      value: modelData.audio ? modelData.audio.volume : 0
      dimmed: !!modelData.audio && modelData.audio.muted
      onMoved: function(next) { modelData.audio.volume = next }
      onIconClicked: modelData.audio.muted = !modelData.audio.muted
    }
  }

  PanelHeading { text: "Output"; visible: root.sinks.length > 1 }

  Repeater {
    model: root.sinks.length > 1 ? root.sinks : []

    PanelRow {
      required property var modelData
      icon: String.fromCodePoint(0xF04C3)
      label: root.nodeLabel(modelData)
      selected: modelData === root.sink
      onClicked: Pipewire.preferredDefaultAudioSink = modelData
    }
  }

  PanelHeading { text: "Input"; visible: root.sources.length > 1 }

  Repeater {
    model: root.sources.length > 1 ? root.sources : []

    PanelRow {
      required property var modelData
      icon: String.fromCodePoint(0xF036C)
      label: root.nodeLabel(modelData)
      selected: modelData === root.source
      onClicked: Pipewire.preferredDefaultAudioSource = modelData
    }
  }
}
