const std = @import("std");
const http = @import("http.zig");

pub const Request = struct {
    method: []const u8,
    path: []const u8,
    protocol: []const u8,
    body: []const u8,
    close: bool,

    bodyBuffer: [1024]u8,

    headers: [32]http.Header,
    headerCount: usize,

    queryParams: [16]http.QueryParam,
    queryParamCount: usize,

    lowerKey: [64]u8, // Pre-allocated buffer for lowercased keys

    pub fn reset(self: *Request) void {
        self.method = undefined;
        self.path = undefined;
        self.protocol = undefined;
        self.body = undefined;
        self.close = false;
        self.headerCount = 0;
        self.queryParamCount = 0;
    }

    const ParseError = error{
        InvalidRequest,
        InvalidHeader,
        InvalidQueryParam,
        RequestTooLarge,
    };

    pub fn parse(self: *Request, br: *std.Io.Reader) !void {
        var line = try br.takeDelimiter('\n') orelse {
            return ParseError.InvalidRequest;
        };

        // Fast paht for line ending removal
        if (line.len >= 2 and line[line.len - 2] == '\r') {
            line = line[0 .. line.len - 2];
        } else if (line.len >= 1 and line[line.len - 1] == '\n') {
            line = line[0 .. line.len - 1];
        }

        // Parse request line with bounds checking
        if (line.len < 14) {
            return ParseError.InvalidRequest;
        }

        // Single pass parsing
        var space1: ?usize = null;
        var space2: ?usize = null;
        for (line, 0..) |character, index| {
            if (character == ' ') {
                if (space1 == null) {
                    space1 = index;
                } else if (space2 == null) {
                    space2 = index;
                    break;
                }
            }
        }

        if (space1 == null or space2 == null) {
            return ParseError.InvalidRequest;
        }

        self.method = line[0..space1.?];
        self.path = line[space1.? + 1 .. space2.?];
        self.protocol = line[space2.? + 1 ..];

        // Path parse
        const questionIndexOpt = std.mem.find(u8, self.path, "?");
        if (questionIndexOpt) |questionIndex| {
            // Split path and query string
            const actualPath = self.path[0..questionIndex];
            const queryString = self.path[questionIndex + 1 ..];
            self.path = actualPath;

            // Parse query parameters
            try self.parseQueryParameters(queryString);
        }

        // Fast protocol check
        if (self.protocol.len == 8) {
            if (std.mem.eql(u8, self.protocol, http.protocol_http10)) {
                self.close = true;
            } else if (std.mem.eql(u8, self.protocol, http.protocol_http11)) {
                self.close = false;
            } else {
                return ParseError.InvalidRequest;
            }
        } else {
            return ParseError.InvalidRequest;
        }

        // Parse headers
        try self.parseHeaders(br);
    }

    pub fn parseQueryParameters(self: *Request, queryString: []const u8) !void {
        if (queryString.len == 0) {
            return;
        }

        var start: usize = 0;
        var i: usize = 0;
        while (i <= queryString.len) : (i += 1) {
            if (i == queryString.len or queryString[i] == '&') {
                if (i > start and self.queryParamCount < self.queryParams.len) {
                    const paramSlice = queryString[start..i];
                    try self.parseQueryParameter(paramSlice);
                }
                start = i + 1;
            }
        }
    }

    pub fn parseQueryParameter(self: *Request, param: []const u8) !void {
        if (self.queryParamCount >= self.queryParams.len) {
            return; // Ignore if we've reached max capacity
        }

        var qp = &self.queryParams[self.queryParamCount];

        // Find '=' separator
        const equalIndexOpt = std.mem.find(u8, param, "=");
        if (equalIndexOpt) |equalIndex| {
            // Split name and value
            const name = param[0..equalIndex];
            const value = param[equalIndex + 1 ..];

            // URL decode name and value
            const nameDecoded = std.Uri.percentDecodeBackwards(&qp.name, name); // todo maybe replace with backwards version
            const valueDecoded = std.Uri.percentDecodeBackwards(&qp.value, value);
            qp.name_len = nameDecoded.len;
            qp.value_len = valueDecoded.len;
            // qp.name = @memcpy(qp.name[0..nameDecoded.len], nameDecoded);
            // qp.name_len = nameDecoded.len;
            // qp.value = @memcpy(qp.value[0..valueDecoded.len], valueDecoded);
            // qp.value_len = valueDecoded.len;
        } else {
            // No value, treat entire param as name with empty value
            qp.name_len = @min(param.len, qp.name.len);
            @memcpy(qp.name[0..qp.name_len], param);
            qp.value_len = 0;
        }

        self.queryParamCount += 1;
    }

    pub fn parseHeaders(self: *Request, br: *std.Io.Reader) !void {
        var content_length: usize = 0;
        var has_content_length: bool = false;
        var has_transfer_encoding: bool = false;
        var is_chunked: bool = false;

        var lowerNameBuf: [64]u8 = undefined;

        while (true) {
            var line = try br.takeDelimiter('\n') orelse {
                return ParseError.InvalidHeader;
            };

            // Fast path for line ending removal
            if (line.len >= 2 and line[line.len - 2] == '\r') {
                line = line[0 .. line.len - 2];
            } else if (line.len >= 1 and line[line.len - 1] == '\n') {
                line = line[0 .. line.len - 1];
            }

            // Empty line indicates end of headers
            if (line.len == 0) {
                break;
            }

            // Find ':' separator
            const colonIndexOpt = std.mem.find(u8, line, ":");
            if (colonIndexOpt == null) {
                return ParseError.InvalidHeader;
            }
            const colonIndex = colonIndexOpt.?;

            // Extract name and value
            const name = line[0..colonIndex];
            var value = line[colonIndex + 1 ..];

            // Trim whitespace from value
            const trimmedValue = @constCast(std.mem.trim(u8, value, " "));
            value = trimmedValue;

            // Store header if we have space
            if (self.headerCount < self.headers.len) {
                var header = &self.headers[self.headerCount];

                // Store name in lower case for easy comparison
                const nameLen = @min(name.len, header.name.len);
                for (name[0..nameLen], 0..) |c, idx| {
                    header.name[idx] = std.ascii.toLower(c);
                }

                // Store value as is
                const valueLen = @min(value.len, header.value.len);
                @memcpy(header.value[0..valueLen], value);
                header.value_len = valueLen;

                self.headerCount += 1;
            }

            // Check for specific headers
            if (name.len <= 20 and name.len <= lowerNameBuf.len) {
                // Lowercase the name for comparison
                for (name, 0..) |c, idx| {
                    lowerNameBuf[idx] = std.ascii.toLower(c);
                }
                const lowerName = lowerNameBuf[0..name.len];

                // Header matching
                switch (lowerName.len) {
                    10 => { // connection
                        if (std.mem.eql(u8, lowerName, http.header_connection)) {
                            if (std.mem.eql(u8, value, http.header_close)) {
                                self.close = true;
                            } else if (std.mem.eql(u8, value, http.header_keep_alive)) {
                                self.close = false;
                            }
                        }
                    },
                    14 => { // content-length
                        if (std.mem.eql(u8, lowerName, http.header_content_type)) {
                            if (has_transfer_encoding and is_chunked) {
                                return ParseError.InvalidHeader; // potential request smuggling
                            }
                            has_content_length = true;
                            content_length = try std.fmt.parseInt(usize, value, 10);
                        }
                    },
                    17 => { // transfer-encoding
                        if (std.mem.eql(u8, lowerName, http.header_transfer_encoding)) {
                            has_transfer_encoding = true;
                            if (std.mem.eql(u8, value, "chunked")) {
                                is_chunked = true;
                            }
                        }
                    },
                    else => {},
                }

                // Read body
                if (is_chunked) {
                    @panic("not implemented");
                } else if (content_length > 0) {
                    if (content_length > self.bodyBuffer.len) {
                        return ParseError.RequestTooLarge; // Body too large for buffer
                    }

                    self.body = self.bodyBuffer[0..content_length];
                } else {
                    self.body = undefined;
                }
            }
        }
    }
};
