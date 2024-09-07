const std = @import("std");
const log = std.log;
const net = std.net;
const network = @import("network");

const allocator = std.heap.page_allocator;
var interrupted = std.atomic.Value(bool).init(false);
// var mutex = std.Thread.Mutex{};

const Session = struct {
    server: *TcpServer,
    conn: net.Server.Connection,
    thread: ?std.Thread = null,

    fn deinit(self: *Session) void {
        self.conn.stream.close();
    }

    fn run(self: *Session) !void {
        self.thread = try std.Thread.spawn(.{}, doRun, .{self});
    }

    fn doRun(self: *Session) !void {
        while (!interrupted.load(.acquire)) {
            var buf: [1024]u8 = undefined;
            const amt = self.conn.stream.read(&buf) catch 0;
            if (amt == 0) {
                self.server.closeSession(self);
                break;
            }
            const msg = buf[0..amt];
            std.log.debug("received {any}", .{msg});
        }
    }
};

const TcpServer = struct {
    server: ?net.Server = null,
    arr: ?std.ArrayList(*Session) = null,
    mutex: std.Thread.Mutex = .{},

    fn deinit(self: *TcpServer) void {
        if (self.arr) |arr| {
            arr.deinit();
        }
        if (self.server) |server| {
            server.deinit();
        }
    }

    fn run(self: *TcpServer, ip: []const u8, port: u16) !void {
        if (self.server != null) {
            return;
        }
        self.server = try net.Address.listen(try net.Address.parseIp(ip, port), .{});
        self.arr = std.ArrayList(*Session).init(allocator);

        while (!interrupted.load(.acquire)) {
            const client = try allocator.create(Session);
            client.* = Session{ .server = self, .conn = try self.server.?.accept() };
            {
                self.mutex.lock();
                defer self.mutex.unlock();
                try self.arr.?.append(client);
            }
            try client.run();
        }
    }

    pub fn closeSession(self: *TcpServer, client: *Session) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        for (self.arr.?.items, 0..) |item, i| {
            if (item == client) {
                _ = self.arr.?.swapRemove(i);
                client.deinit();
                allocator.destroy(client);
                break;
            }
        }
    }
};

pub fn main() !void {
    var server = TcpServer{};
    try server.run("0.0.0.0", 3070);
}
