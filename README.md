# genblog

`genblog` is a simple static site generator that converts plain text into HTML 3.2 compliant blog pages.

It avoids unnecessary styling, dependencies, and bloat, and aims to be lightweight, fast, and minimalistic for the web.

## Features

- Outputs pure HTML 3.2.
- Uses simple custom syntax.
- No CSS or JavaScript.
- Works with most 2000s browsers.

## How to use

To generate a blog page from a file with genblog syntax, run the following command:

```sh 
./genblog <filename> 
```

A file named `<filename>.html` will be generated.

### Command line options

```sh
# Generate HTML from a file
./genblog <filename>

# Create an empty genblog template file
./genblog -t, --template <filename>

# Use a custom html template
./genblog -w, --with-template <template html> <file>

# Show version information
./genblog -v, --version

# Show help message
./genblog -h, --help
```

## Supported syntax

```
. Heading → <h2>

... Subheading → <h3>

-- (single line) → <hr>

--small text → <small>

code blocks → use Markdown-style three back-quotes (rendered as <pre>)

Inline code (only one per line) → `code`

Images → ! [src="path" alt="description"]

Strikeout → --text--.
```

For more information on the syntax, please see this blog post.

## Installation

Zig is required.
```sh
zig build
```
Or, to build directly: 
```sh
zig build-exe src/main.zig
```

## License

Based on the MIT license.
See [LICENSE](./LICENSE) for details.

## License

Based on the MIT license.
See [LICENSE](./LICENSE) for details.
