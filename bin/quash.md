# Quash: Shell Script Trace Wrapper

## Overview
Quash is a utility script designed to facilitate debugging and tracing of shell scripts. It provides options to send trace output to a specified terminal, run scripts in REPL or source mode, and manage environment configurations.

## Usage 

### In child shell:
```
quash.sh <--tty|-t /path/to/tty> <-p [N]> <-r|--repl> <-s|--source> [--] <script-name> [script args]
```
### In current shell:
```
quash [options]
```
Running in current-shell is useful for interacting with the shell or the elements defined in the script.  *(It also pollutes the current shell with whatever is done there, naturally.)*

`quash` is a thin wrapper defined in `quash.bashrc`, which is loaded with shell init typically.

## Options

### `--tty|-t /path/to/tty`
Specifies the terminal, pipe, or file to which trace output will be sent. The path must be valid and writable.

### `-p [N]`
Specifies the short form of the terminal path. For example, `-p 1` is equivalent to `--tty /dev/pts/1`.

If neither `--tty` nor `-p` is provided, the current terminal is used.

### `--query-tty|-1`
Print the tty paths for each active terminal so they can be easily identified.

### `--`
Indicates the end of Quash-specific arguments. Any remaining arguments are passed directly to `<script-name>`.

### `--repl|-r`
Enables REPL (Read-Eval-Print Loop) mode. In this mode, commands are read and evaluated one line at a time from standard input.

### `--source|-s`
Enables SOURCE mode. In this mode, `<script-name>` is sourced directly into the current shell environment without starting a child shell.

### `--loadrc|-l`
Loads the `~/.bashrc` file before processing commands. This option is only applicable in REPL or SOURCE mode.

### `<script-name>`
Specifies the path to the script to be executed or evaluated. This argument is mandatory unless REPL or SOURCE mode is enabled.

### `[script args]`
Additional arguments to be forwarded to the script or the REPL environment.

## Examples

### Example 1: Run a script with trace output to a specific terminal
```
quash.sh --tty /dev/pts/1 ./my-script.sh --foo
```

### Example 2: Use REPL mode
```
quash.sh --repl
```

### Example 3: Source a script with `.bashrc` loaded
```
quash.sh --source --loadrc ./my-script.sh
```

### Example 4: Display available terminals for trace output
Run Quash without `--tty` or `-p`:
```
quash.sh
```
This will list available terminals and provide instructions for selecting one.

## Notes
- Ensure the specified terminal or file for trace output is writable.
- Use `--help` or `-h` for additional guidance.
