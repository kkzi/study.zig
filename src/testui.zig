const capy = @import("capy");
const std = @import("std");

pub fn main() !void {
    try capy.backend.init();

    var window = try capy.Window.init();
    try window.set(capy.Column(.{ .spacing = 10 }, .{ // have 10px spacing between each column's element
        capy.Row(.{ .spacing = 5 }, .{ // have 5px spacing between each row's element
            capy.Button(.{ .label = "Save", .onclick = buttonClicked }),
            capy.Button(.{ .label = "Run", .onclick = buttonClicked }),
        }),
        // Expanded means the widget will take all the space it can
        // in the parent container
        capy.Expanded(capy.TextArea(.{ .text = "Hello World!" })),
    }));

    window.resize(800, 600);
    window.show();
    capy.runEventLoop();
}

fn buttonClicked(button: *capy.Button_Impl) !void {
    std.log.info("You clicked button with text {s}", .{button.getLabel()});
}
