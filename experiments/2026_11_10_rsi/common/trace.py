#!/usr/bin/env python3
"""Turn a generator agent's JSONL transcript into a readable Markdown trace.

The transcript path is the `output_file` reported when the agent is spawned
(it may be a symlink). Thinking blocks are included when the transcript
stores their text; often they are stored empty, in which case the reasoning
must be read from the agent's text messages, its tool calls (every Write/Edit
of the checker, in order), the tool results it reacted to, and its final
report.

usage: common/trace.py <transcript.jsonl> <out.md> [--max-result N]
"""
import argparse, json

ap = argparse.ArgumentParser()
ap.add_argument("transcript")
ap.add_argument("out")
ap.add_argument("--max-result", type=int, default=3000,
                help="truncate each tool result to N characters (default 3000)")
a = ap.parse_args()

def clip(s, n):
    s = s if isinstance(s, str) else json.dumps(s, indent=1)
    return s if len(s) <= n else s[:n] + f"\n... [{len(s) - n} more chars]"

out, step, empty_thinking = [], 0, 0
for line in open(a.transcript, errors="replace"):
    try:
        e = json.loads(line)
    except ValueError:
        continue
    t, msg = e.get("type"), e.get("message") or {}
    content = msg.get("content")
    if t == "assistant" and isinstance(content, list):
        for b in content:
            bt = b.get("type")
            if bt == "thinking":
                txt = b.get("thinking", "")
                if txt.strip():
                    out.append(f"### thinking\n\n{txt}\n")
                else:
                    empty_thinking += 1
            elif bt == "text" and b.get("text", "").strip():
                out.append(f"### assistant\n\n{b['text']}\n")
            elif bt == "tool_use":
                step += 1
                inp = b.get("input", {})
                name = b.get("name")
                if name == "Write":
                    body = f"file: {inp.get('file_path')}\n\n```\n{inp.get('content', '')}\n```"
                elif name == "Edit":
                    body = (f"file: {inp.get('file_path')}\n\nold:\n```\n{inp.get('old_string', '')}\n```\n"
                            f"new:\n```\n{inp.get('new_string', '')}\n```")
                elif name == "Bash":
                    body = f"```\n{inp.get('command', '')}\n```"
                elif name == "SubagentHandback":
                    body = inp.get("message", "")
                else:
                    body = f"```\n{clip(inp, 2000)}\n```"
                out.append(f"### step {step}: {name}\n\n{body}\n")
    elif t == "user" and isinstance(content, list):
        for b in content:
            if b.get("type") == "tool_result":
                c = b.get("content")
                if isinstance(c, list):
                    c = "\n".join(x.get("text", "") for x in c if isinstance(x, dict))
                out.append(f"#### result\n\n```\n{clip(c or '', a.max_result)}\n```\n")

head = [f"# Generator trace\n\nsource: {a.transcript}\n"]
if empty_thinking:
    head.append(f"note: {empty_thinking} thinking block(s) were stored without text.\n")
open(a.out, "w").write("\n".join(head + out))
print(f"{a.out}: {step} tool calls, {len(out)} entries, {empty_thinking} empty thinking blocks")
