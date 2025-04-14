# quash()/quash.sh 

`quash.sh` and the *(`quash` shell function)*  is a Bash utility designed to enhance shell debugging and command execution with advanced tracing and terminal management features.

## Usage

**Interactive:**
```bash
quash  [options] [command]
```

**External:**
```bash
quash.sh [options] [command]
```

Interactive mode is generally more useful: it turns the current shell into a debugger, in a sense -- multiple calls to `quash [option]` change the state of the current shell and quash behavior, and any number of calls to `quash 'command <args>'` can be used to run commands in the context of options provided.

External use is of interest when you do not wish to alter the state of the current shell or change quash options on the fly.

## Setup

[Install `bashics`](https://github.com/sanekits/bashics?tab=readme-ov-file#setup) or source `bin/quash.bashrc` from shell init.

## Options

| Option                  | Description                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| `--tty` \| `-t <path>`  | Specify trace output terminal (e.g., `/dev/pts/2`).                         |
| `-p <N>`                | Shortcut for `--tty /dev/pts/<N>`.                                          |
| `--notty` \| `-n`       | Use the current terminal for trace output.                                 |
| `--findtty` \| `-f`     | Find available terminals for trace output.                                 |
| `--help` \| `-h`        | Display a brief usage message.                                             |
| `--loadrc` \| `-l`      | Load `~/.bashrc` before executing the command.                             |
| `--clear` \| `-e`       | Clear the trace output terminal.                                           |
| `--completions` \| `-c` | Enable (`on`) or disable (`off`) tab completions.                          |
| `--noexit`              | Disable `exit` to preserve the shell session.                              |
| `--ps1_disable` \| `-d` | Disable PS1 hook functions to reduce noise.                                |
| `--ps4 <style>`         | Set PS4 debug prompt style (`color`, `plain`, or `off`).                   |
| `--`                    | End of options; pass remaining arguments as the command to execute.        |

## Features

### Trace Output Management
- Redirects trace output to a specified terminal or file.
- Automatically identifies available terminals for tracing.

### Command Execution
- Executes commands with optional loading of `~/.bashrc`.
- Provides detailed execution context, including timestamps, working directory, and process ID.

### Debugging Enhancements
- Customizable PS4 debug prompt for enhanced trace readability.
- Supports enabling/disabling tab completions dynamically.

### Shell Preservation
- `--noexit` mode prevents accidental shell termination, requiring explicit use of `builtin exit`.

## Examples

### Redirect Trace Output to a Specific Terminal
```bash
quash --tty /dev/pts/2 -- ls -l
```

### Use the Current Terminal for Trace Output
```bash
quash --notty -- ps aux
```

### Find Available Terminals for Trace Output
```bash
quash --findtty
```

### Execute a Command with `~/.bashrc` Loaded
```bash
quash --loadrc -- echo "Hello, world!"
```

### Disable PS1 Hooks and Use a Plain PS4 Debug Prompt
```bash
quash --ps1_disable --ps4 plain -- bash -x script.sh
```

## Notes
- Ensure the specified terminal or file for trace output is writable.
- Use `--` to separate `quash.sh` options from the command to execute.
