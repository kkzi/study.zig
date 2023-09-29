const std = @import("std");
const log = std.log;
const mem = std.mem;
const net = std.net;
const fmt = std.fmt;
const Atomic = std.atomic.Atomic;

const STI_HEAD: i32 = 1234567890;
const STI_TAIL: i32 = -STI_HEAD;
const STI_DATA_FLOW_OFFSET: i32 = 5;

const ServerConfig = struct {
    tm_port: u16,
    time_port: u16,
    input_file: []const u8,
    frame_len: u16,
    fps: u32,

    fn init(filepath: []const u8) !ServerConfig {
        return ServerConfig{
            .tm_port = 3070,
            .time_port = 3071,
            .input_file = filepath,
            .frame_len = 263,
            .fps = 2,
        };
    }
};

var server_config: ServerConfig = undefined;

const Channel = struct {
    index: usize,
    conn: net.StreamServer.Connection,
    conn_thread: std.Thread,

    interrupted: Atomic(bool),

    fn init(index: usize, conn: net.StreamServer.Connection, conn_thread: std.Thread) Channel {
        return Channel{
            .index = index,
            .conn = conn,
            .conn_thread = conn_thread,
            .interrupted = Atomic(bool).init(false),
        };
    }

    fn deinit(self: *Channel) void {
        self.interrupted.storeUnchecked(true);
        self.conn_thread.join();
        self.* = undefined;
    }
};

var mutex = std.Thread.Mutex{};
var channels = std.AutoHashMap(usize, Channel).init(std.heap.page_allocator);

fn close_channel(chan: *Channel) void {
    const index = chan.index;
    chan.deinit();
    _ = channels.remove(index);
}

fn start_tm_channel(chan: *Channel) !void {
    log.info("start tm data flow", .{});
    // while (!chan.interrupted.loadUnchecked()) {
    var file = try std.fs.openFileAbsolute(server_config.input_file, .{});
    defer file.close();
    var buf: [2048]u8 = undefined;
    var count: i64 = 0;
    var t0 = std.time.microTimestamp();
    var last = t0;
    const gap: u32 = std.time.us_per_s / server_config.fps;

    while (!chan.interrupted.loadUnchecked()) {
        const now = std.time.microTimestamp();
        if (now - last < gap) continue;
        last = now;

        var n = try file.read(buf[0..server_config.frame_len]);
        _ = try chan.conn.stream.write(buf[0..n]);
        count += 1;
    }

    log.info("fps = {}", .{@divExact(count * std.time.us_per_s, last - t0)});
}

fn handle_data_flow(index: usize, data_flow: i32) !void {
    mutex.lock();
    defer mutex.unlock();

    var chan = channels.getPtr(index).?;
    switch (data_flow) {
        0, 1, 2, 4, 5, 6 => {
            try start_tm_channel(chan);
            // if (std.Thread.spawn(.{}, start_tm_channel, .{chan})) |t| {
            //     chan.tm_thread = t;
            // } else |e| {
            //     log.err("{}", .{e});
            // }
        },
        0x80 => {
            log.info("stop tm data flow", .{});
            close_channel(chan);
        },
        else => {
            log.err("unknown data flow {X}", .{data_flow});
            close_channel(chan);
        },
    }
}

fn handle_client_connection(index: usize, conn: net.StreamServer.Connection) !void {
    log.info("new connection from {}", .{conn.address});
    var buffer: [1024]u8 = undefined;
    while (true) {
        if (conn.stream.readAtLeast(&buffer, 64)) |n| {
            if (n <= 0) break;

            log.debug("received {}", .{fmt.fmtSliceHexUpper(buffer[0..n])});
            const head = mem.readIntSliceBig(i32, buffer[0..4]);
            if (head != STI_HEAD) break;

            const data_flow = mem.readIntSliceBig(i32, buffer[STI_DATA_FLOW_OFFSET * 4 .. (STI_DATA_FLOW_OFFSET + 1) * 4]);
            try handle_data_flow(index, data_flow) ;
            log.info("received data flow {X} from {}", .{ data_flow, conn.address });
        } else |e| {
            log.err("connection lost {}", .{e});
            break;
        }
    }
    log.info("disconnect from {}", .{conn.address});

    {
        mutex.lock();
        defer mutex.unlock();
        if (channels.getPtr(index)) |chan| {
            close_channel(chan);
            conn.stream.close();
        }
        log.debug("total {} channels", .{channels.count()});
    }
}

pub fn main() !void {
    const filepath = "C:/Users/kizi/desktop/input.dat";
    if (ServerConfig.init(filepath)) |cfg| {
        server_config = cfg;
    } else |e| {
        log.err("open file {s} failed: {}", .{ filepath, e });
        return;
    }

    const addr = try net.Address.parseIp("0.0.0.0", server_config.tm_port);
    var server = net.StreamServer.init(.{});
    defer server.deinit();
    try server.listen(addr);

    log.info("running at {}", .{addr});

    var client_index: usize = 0;
    while (true) {
        const conn = try server.accept();

        client_index += 1;
        if (std.Thread.spawn(.{}, handle_client_connection, .{ client_index, conn })) |t| {
            mutex.lock();
            defer mutex.unlock();
            try channels.put(client_index, Channel.init(client_index, conn, t));
        } else |_| {
            log.err("error", .{});
        }
    }
}
