import json

import pytest

from server import _parse, code_chunker, github_diff_parser

# ── fixtures ──────────────────────────────────────────────────────────────────

SINGLE_FILE_DIFF = """\
diff --git a/src/foo.py b/src/foo.py
index abc1234..def5678 100644
--- a/src/foo.py
+++ b/src/foo.py
@@ -10,6 +10,7 @@ def existing():
     context 1
-    old line
+    new line
     context 2
"""

MULTI_FILE_DIFF = """\
diff --git a/src/foo.py b/src/foo.py
index abc1234..def5678 100644
--- a/src/foo.py
+++ b/src/foo.py
@@ -1,3 +1,4 @@
+import os
 import sys
 import re
diff --git a/src/bar.py b/src/bar.py
index 111..222 100644
--- a/src/bar.py
+++ b/src/bar.py
@@ -5,3 +5,3 @@
-    x = 1
+    x = 2
 return x
"""

MULTI_HUNK_DIFF = """\
diff --git a/main.py b/main.py
index 000..111 100644
--- a/main.py
+++ b/main.py
@@ -1,3 +1,4 @@
+# header comment
 def foo():
-    pass
+    return 1
@@ -20,3 +21,4 @@
 def bar():
-    pass
+    return 2
+    # extra
"""

DELETED_FILE_DIFF = """\
diff --git a/old.py b/old.py
deleted file mode 100644
--- a/old.py
+++ /dev/null
@@ -1,3 +0,0 @@
-line 1
-line 2
-line 3
"""


def _make_parsed_json(file: str, start_line: int, changes: str) -> str:
    return json.dumps([{"file": file, "hunks": [{"start_line": start_line, "changes": changes}]}])


# ── github_diff_parser ────────────────────────────────────────────────────────


@pytest.mark.unit
def test_parser_single_file_returns_one_entry() -> None:
    result = json.loads(github_diff_parser(SINGLE_FILE_DIFF))
    assert len(result) == 1
    assert result[0]["file"] == "src/foo.py"


@pytest.mark.unit
def test_parser_single_file_hunk_count() -> None:
    result = json.loads(github_diff_parser(SINGLE_FILE_DIFF))
    assert len(result[0]["hunks"]) == 1


@pytest.mark.unit
def test_parser_single_file_start_line() -> None:
    result = json.loads(github_diff_parser(SINGLE_FILE_DIFF))
    assert result[0]["hunks"][0]["start_line"] == 10


@pytest.mark.unit
def test_parser_single_file_changes_contain_added_line() -> None:
    result = json.loads(github_diff_parser(SINGLE_FILE_DIFF))
    assert "+    new line" in result[0]["hunks"][0]["changes"]


@pytest.mark.unit
def test_parser_single_file_changes_contain_removed_line() -> None:
    result = json.loads(github_diff_parser(SINGLE_FILE_DIFF))
    assert "-    old line" in result[0]["hunks"][0]["changes"]


@pytest.mark.unit
def test_parser_multi_file_count() -> None:
    result = json.loads(github_diff_parser(MULTI_FILE_DIFF))
    assert len(result) == 2


@pytest.mark.unit
def test_parser_multi_file_names() -> None:
    result = json.loads(github_diff_parser(MULTI_FILE_DIFF))
    names = [f["file"] for f in result]
    assert "src/foo.py" in names
    assert "src/bar.py" in names


@pytest.mark.unit
def test_parser_multi_hunk_count() -> None:
    result = json.loads(github_diff_parser(MULTI_HUNK_DIFF))
    assert len(result[0]["hunks"]) == 2


@pytest.mark.unit
def test_parser_multi_hunk_start_lines() -> None:
    result = json.loads(github_diff_parser(MULTI_HUNK_DIFF))
    start_lines = [h["start_line"] for h in result[0]["hunks"]]
    assert start_lines == [1, 21]


@pytest.mark.unit
def test_parser_empty_diff_returns_empty_list() -> None:
    result = json.loads(github_diff_parser(""))
    assert result == []


@pytest.mark.unit
def test_parser_deleted_file_excluded() -> None:
    # +++ /dev/null has no b/ path — file should be excluded since name is None
    result = json.loads(github_diff_parser(DELETED_FILE_DIFF))
    assert result == []


@pytest.mark.unit
def test_parser_output_is_valid_json() -> None:
    raw = github_diff_parser(SINGLE_FILE_DIFF)
    parsed = json.loads(raw)
    assert isinstance(parsed, list)


@pytest.mark.unit
def test_parse_internal_matches_tool_output() -> None:
    internal = _parse(SINGLE_FILE_DIFF)
    tool_output = json.loads(github_diff_parser(SINGLE_FILE_DIFF))
    assert internal == tool_output


# ── code_chunker ──────────────────────────────────────────────────────────────


@pytest.mark.unit
def test_chunker_small_hunk_single_chunk() -> None:
    changes = "\n".join(f"+line {i}" for i in range(10))
    result = json.loads(code_chunker(_make_parsed_json("a.py", 1, changes), max_lines=200))
    assert len(result) == 1


@pytest.mark.unit
def test_chunker_splits_large_hunk() -> None:
    changes = "\n".join(f"+line {i}" for i in range(300))
    result = json.loads(code_chunker(_make_parsed_json("a.py", 1, changes), max_lines=100))
    assert len(result) == 3


@pytest.mark.unit
def test_chunker_exact_boundary() -> None:
    changes = "\n".join(f"+line {i}" for i in range(200))
    result = json.loads(code_chunker(_make_parsed_json("a.py", 1, changes), max_lines=200))
    assert len(result) == 1


@pytest.mark.unit
def test_chunker_preserves_file_path() -> None:
    changes = "\n".join(f"+line {i}" for i in range(5))
    result = json.loads(code_chunker(_make_parsed_json("src/target.py", 1, changes)))
    assert all(c["file"] == "src/target.py" for c in result)


@pytest.mark.unit
def test_chunker_start_line_offset() -> None:
    changes = "\n".join(f"+line {i}" for i in range(250))
    result = json.loads(code_chunker(_make_parsed_json("a.py", 50, changes), max_lines=100))
    assert result[0]["start_line"] == 50
    assert result[1]["start_line"] == 150
    assert result[2]["start_line"] == 250


@pytest.mark.unit
def test_chunker_multi_file_chunk_count() -> None:
    parsed = json.dumps(
        [
            {"file": "a.py", "hunks": [{"start_line": 1, "changes": "+line"}]},
            {"file": "b.py", "hunks": [{"start_line": 1, "changes": "+other"}]},
        ]
    )
    result = json.loads(code_chunker(parsed))
    assert len(result) == 2
    assert {c["file"] for c in result} == {"a.py", "b.py"}


@pytest.mark.unit
def test_chunker_empty_input_returns_empty_list() -> None:
    result = json.loads(code_chunker("[]"))
    assert result == []


@pytest.mark.unit
def test_chunker_invalid_json_returns_error() -> None:
    result = json.loads(code_chunker("not-json"))
    assert "error" in result


@pytest.mark.unit
def test_chunker_output_is_valid_json() -> None:
    changes = "\n".join(f"+line {i}" for i in range(5))
    raw = code_chunker(_make_parsed_json("a.py", 1, changes))
    assert isinstance(json.loads(raw), list)


@pytest.mark.unit
def test_chunker_chunk_content_preserved() -> None:
    changes = "+added line\n-removed line\n context line"
    result = json.loads(code_chunker(_make_parsed_json("a.py", 1, changes)))
    assert result[0]["chunk"] == changes
