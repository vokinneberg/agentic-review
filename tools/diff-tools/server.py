import json
import re
from typing import Any

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("diff-tools", host="0.0.0.0", port=8000)


def _parse(diff: str) -> list[dict[str, Any]]:
    files: list[dict[str, Any]] = []
    current_file: dict[str, Any] | None = None
    current_hunk: dict[str, Any] | None = None
    new_line_num = 0

    for line in diff.splitlines():
        if line.startswith("diff --git"):
            if current_file is not None:
                if current_hunk is not None:
                    current_file["hunks"].append(current_hunk)
                    current_hunk = None
                files.append(current_file)
            current_file = {"file": None, "hunks": []}

        elif line.startswith("+++ b/") and current_file is not None:
            current_file["file"] = line[6:]

        elif line.startswith("+++ /dev/null") and current_file is not None:
            # deleted file — name already set from --- line
            pass

        elif (
            line.startswith("--- b/") and current_file is not None and current_file["file"] is None
        ):
            current_file["file"] = line[6:]

        elif line.startswith("@@"):
            if current_hunk is not None and current_file is not None:
                current_file["hunks"].append(current_hunk)
            match = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
            if match:
                new_line_num = int(match.group(1))
                current_hunk = {"start_line": new_line_num, "changes": []}

        elif current_hunk is not None:
            if line.startswith("+"):
                current_hunk["changes"].append(line)
                new_line_num += 1
            elif line.startswith("-"):
                current_hunk["changes"].append(line)
            elif line.startswith(" "):
                current_hunk["changes"].append(line)
                new_line_num += 1

    if current_file is not None:
        if current_hunk is not None:
            current_file["hunks"].append(current_hunk)
        files.append(current_file)

    return [
        {
            "file": f["file"],
            "hunks": [
                {"start_line": h["start_line"], "changes": "\n".join(h["changes"])}
                for h in f["hunks"]
                if h["changes"]
            ],
        }
        for f in files
        if f.get("file") and f["hunks"]
    ]


@mcp.tool()
def github_diff_parser(diff: str) -> str:
    """Parse a raw GitHub patch-format diff into a structured list of files and hunks.

    Each hunk includes the new-file start line and the raw change lines (+/-/ ).
    Use this before code_chunker to prepare a diff for LLM review.

    Args:
        diff: Raw unified diff string (e.g. from GitHub API patch field).

    Returns:
        JSON array of {file, hunks: [{start_line, changes}]}.
    """
    return json.dumps(_parse(diff), indent=2)


@mcp.tool()
def code_chunker(parsed_diff: str, max_lines: int = 200) -> str:
    """Split parsed diff hunks into LLM-sized chunks.

    Accepts the JSON output of github_diff_parser and emits a flat list of
    chunks, each small enough for a single LLM context window.  File path
    and approximate start-line offset are preserved on every chunk so
    review comments can be mapped back to exact locations.

    Args:
        parsed_diff: JSON string produced by github_diff_parser.
        max_lines:   Maximum number of diff lines per chunk (default 200).

    Returns:
        JSON array of {file, start_line, chunk}.
    """
    try:
        files: list[dict[str, Any]] = json.loads(parsed_diff)
    except json.JSONDecodeError as exc:
        return json.dumps({"error": f"Invalid parsed_diff JSON: {exc}"})

    chunks: list[dict[str, Any]] = []

    for file_diff in files:
        path = file_diff.get("file", "unknown")
        for hunk in file_diff.get("hunks", []):
            base_line: int = hunk.get("start_line", 0)
            lines = hunk.get("changes", "").splitlines()
            for i in range(0, max(len(lines), 1), max_lines):
                slice_ = lines[i : i + max_lines]
                if slice_:
                    chunks.append(
                        {
                            "file": path,
                            "start_line": base_line + i,
                            "chunk": "\n".join(slice_),
                        }
                    )

    return json.dumps(chunks, indent=2)


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
