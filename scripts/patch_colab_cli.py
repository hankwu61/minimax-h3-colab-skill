import os
import sys

target = os.path.expandvars(r"%APPDATA%\uv\tools\google-colab-cli\Lib\site-packages\colab_cli\console.py")
if not os.path.isfile(target):
    sys.exit(0)

with open(target, "r", encoding="utf-8") as f:
    lines = f.readlines()

if any("# WINDOWS_COMPAT_PATCH" in line for line in lines):
    print("Already patched for Windows.")
    sys.exit(0)

new_lines = []
for line in lines:
    if line.strip() == "import termios":
        new_lines.append("# WINDOWS_COMPAT_PATCH\n")
        new_lines.append("try:\n")
        new_lines.append("    import termios\n")
        new_lines.append("except ImportError:\n")
        new_lines.append("    termios = None\n")
    elif line.strip() == "import tty":
        new_lines.append("try:\n")
        new_lines.append("    import tty\n")
        new_lines.append("except ImportError:\n")
        new_lines.append("    tty = None\n")
    elif "is_tty = sys.stdin.isatty()" in line:
        new_lines.append(line.replace("is_tty = sys.stdin.isatty()", "is_tty = sys.stdin.isatty() and (termios is not None) and (tty is not None)"))
    elif "signal.signal(signal.SIGWINCH, handle_sigwinch)" in line:
        indent = line[:line.find("signal.signal")]
        new_lines.append(f"{indent}if hasattr(signal, 'SIGWINCH'):\n{indent}    signal.signal(signal.SIGWINCH, handle_sigwinch)\n")
    elif "signal.signal(signal.SIGWINCH, signal.SIG_DFL)" in line:
        indent = line[:line.find("signal.signal")]
        new_lines.append(f"{indent}if hasattr(signal, 'SIGWINCH'):\n{indent}    signal.signal(signal.SIGWINCH, signal.SIG_DFL)\n")
    else:
        new_lines.append(line)

with open(target, "w", encoding="utf-8", newline="\n") as f:
    f.writelines(new_lines)

print("Successfully applied Windows compatibility patch!")
