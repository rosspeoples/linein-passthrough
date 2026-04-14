log = Log.open_topic("linein-passthrough")

local om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "node.name", "matches", "linein_passthrough.playback" },
  }
}

om:connect("object-added", function (_, node)
  log:info("tagging loopback playback node")
  node:update_properties({
    ["node.nick"] = "Line-In Passthrough",
    ["node.description"] = "Line-In Passthrough",
    ["media.name"] = "Line-In Passthrough",
  })
end)

om:activate()
