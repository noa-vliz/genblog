const std = @import("std");
const parse = @import("parse.zig");
const gen_html = @import("gen_html.zig");
const util = @import("utils.zig");
const read_file = @import("read_file.zig");

const template = @embedFile("include/templates/template");
const license = @embedFile("include/LICENSE");
const version_info = @embedFile("include/genblog_version");

const Command = enum {
    generate,
    create_template,
    use_template,
    show_version,
    show_help,
    show_license,
};

const Options = struct {
    command: Command,
    input_file: ?[]const u8,
    template_file: ?[]const u8,
    output_file: ?[]const u8,
};

fn print_version() !void {
    const v = try util.trim(version_info);
    std.debug.print("genblog {s}\n", .{v});
    std.debug.print("Copyright (C) 2025 noa-vliz.\n", .{});
    std.debug.print("Licensed under the MIT License\n", .{});
    std.debug.print("Source: https://github.com/noa-vliz/genblog\n", .{});
}

fn print_usage(program_name: []const u8) !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("Usage:\n", .{});
    try stderr.print("  {s} <file>                    Convert Markdown to HTML\n", .{program_name});
    try stderr.print("  {s} -t, --template <file>     Create template file\n", .{program_name});
    try stderr.print("  {s} -w, --with-template <template> <file>  Use custom template\n", .{program_name});
    try stderr.print("  {s} -v, --version             Show version information\n", .{program_name});
    try stderr.print("  {s} -l, --license             View full license\n", .{program_name});
    try stderr.print("  {s} -h, --help                Show this help message\n", .{program_name});
}

fn parse_args(args: []const []const u8) !Options {
    const stderr = std.io.getStdErr().writer();

    if (args.len < 2) {
        try stderr.print("{s}: No file specified.\n", .{args[0]});
        try stderr.print("For usage instructions, run {s} -h or --help\n", .{args[0]});
        std.process.exit(1);
    }

    // デフォルトオプション
    var options = Options{
        .command = .generate,
        .input_file = null,
        .template_file = null,
        .output_file = null,
    };

    // 最初の引数をチェック
    const first_arg = args[1];

    // テンプレート作成オプション
    if (std.mem.eql(u8, first_arg, "--template") or std.mem.eql(u8, first_arg, "-t")) {
        options.command = .create_template;
        if (args.len < 3) {
            try stderr.print("Please specify a file for template creation\n", .{});
            try print_usage(args[0]);
            std.process.exit(1);
        }
        options.output_file = args[2];
        return options;
    }

    // カスタムテンプレート使用オプション
    if (std.mem.eql(u8, first_arg, "--with-template") or std.mem.eql(u8, first_arg, "-w")) {
        options.command = .use_template;
        if (args.len < 4) {
            try stderr.print("{s}: Not enough arguments for template usage\n", .{args[0]});
            try print_usage(args[0]);
            std.process.exit(1);
        }
        options.template_file = args[2];
        options.input_file = args[3];
        return options;
    }

    // バージョン表示オプション
    if (std.mem.eql(u8, first_arg, "--version") or std.mem.eql(u8, first_arg, "-v")) {
        options.command = .show_version;
        return options;
    }

    if (std.mem.eql(u8, first_arg, "--license") or std.mem.eql(u8, first_arg, "-l")) {
        options.command = .show_license;
        return options;
    }

    // ヘルプ表示オプション
    if (std.mem.eql(u8, first_arg, "--help") or std.mem.eql(u8, first_arg, "-h")) {
        options.command = .show_help;
        return options;
    }

    // デフォルトは入力ファイルとして扱う
    options.input_file = first_arg;
    return options;
}

fn create_template_file(file_path: []const u8) !void {
    const file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    try file.writeAll(template);
    std.debug.print("Template created to {s}\n", .{file_path});
}

fn generate_html_file(alc: std.mem.Allocator, input_file: []const u8, custom_template: ?[]const u8) !void {
    const output_file = try std.fmt.allocPrint(alc, "{s}.html", .{input_file});
    defer alc.free(output_file);

    const parsed_info = try parse.parse_file(input_file);
    std.debug.print("title: {s}\ndate: {s}\n", .{ parsed_info.title, parsed_info.date });

    const generated_html = try gen_html.gen_html(parsed_info, custom_template);
    defer alc.free(generated_html);

    const file = try std.fs.cwd().createFile(output_file, .{});
    defer file.close();

    try file.writeAll(generated_html);
    std.debug.print("HTML file created to {s}\n", .{output_file});
}

pub fn main() !void {
    const alc = std.heap.page_allocator;

    const args = std.process.argsAlloc(alc) catch |err| {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Failed to get args: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
    defer std.process.argsFree(alc, args);

    // コマンドライン引数を解析
    const options = try parse_args(args);

    switch (options.command) {
        .create_template => {
            try create_template_file(options.output_file.?);
        },
        .use_template => {
            const template_content = try read_file.read_file(options.template_file.?);
            try generate_html_file(alc, options.input_file.?, template_content);
        },
        .show_version => {
            try print_version();
        },
        .show_help => {
            try print_usage(args[0]);
        },
        .show_license => {
            std.debug.print("{s}\n", .{license});
        },
        .generate => {
            // 複数ファイルの処理をサポート
            if (args.len > 2) {
                // 最初の引数以降のすべてのファイルを処理
                for (args[1..]) |input_file| {
                    try generate_html_file(alc, input_file, null);
                }
            } else {
                // 単一ファイルの処理
                try generate_html_file(alc, options.input_file.?, null);
            }
        },
    }
}
