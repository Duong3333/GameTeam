import os
import shutil
import subprocess
import tempfile
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(title="HCMUS CSLT Online Judge API", version="1.0.0")

# Cho phép Web export của Godot gọi API từ trình duyệt
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)

MAX_SOURCE_CHARS = 50000
MAX_STDIN_CHARS = 100000
COMPILE_TIMEOUT_SEC = 10
RUN_TIMEOUT_SEC = 5
MAX_OUTPUT_CHARS = 65536


import re


def _clean_compiler_stderr(raw: str, workdir: str = "") -> str:
    """Strip file paths from compiler/linker stderr, keep only useful info."""
    if not raw:
        return raw
    lines = raw.splitlines()
    out: list[str] = []
    for line in lines:
        s = line.strip()
        if not s:
            continue
        # Remove collect2.exe line
        if "collect2.exe" in s or "collect2" == s.split(":")[0].strip():
            continue
        # Remove standalone ld.exe path
        if s.endswith("ld.exe:") or s.endswith("ld:"):
            continue
        # Linker: undefined reference
        if "undefined reference to" in s:
            m = re.search(r"undefined reference to [`']([^'`]+)[`']", s)
            if m:
                out.append(f"Lỗi liên kết: Hàm '{m.group(1)}' chưa được định nghĩa.")
            else:
                out.append("Lỗi liên kết: " + s.split("undefined reference to", 1)[1].strip())
            continue
        # Compiler error/warning: submission.cpp:LINE:COL: ...
        m2 = re.search(r"submission\.cpp:(\d+):(\d+):\s*(.*)", s)
        if m2:
            out.append(f"Dòng {m2.group(1)}: {m2.group(3)}")
            continue
        # Code snippet lines (e.g. "  27 | QuadraticSolution...") or caret lines
        if re.match(r"\s*\d+\s*\|", s) or re.match(r"\s*\|", s):
            out.append(s)
            continue
        # Any line starting with a path - try to extract useful tail
        if re.match(r"[A-Za-z]:[/\\]", s) or s.startswith("/"):
            colon_pos = s.rfind(": ")
            if colon_pos >= 0:
                useful = s[colon_pos + 2:].strip()
                if useful:
                    out.append(useful)
            continue
        out.append(s)
    return "\n".join(out)


class JudgeRequest(BaseModel):
    task_id: str = ""
    language: str = "cpp"
    standard: str = "c++17"
    action: str = "run"
    source_code: str = ""
    compiled_source: str = ""
    stdin: str = Field(default="")


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "compiler": shutil.which("g++") is not None}


@app.post("/api/judge")
def judge(req: JudgeRequest) -> dict:
    code = req.compiled_source if req.compiled_source.strip() else req.source_code
    if not code.strip():
        return {
            "success": False,
            "stage": "validation",
            "message": "Mã nguồn trống.",
            "stdout": "",
            "stderr": "",
            "exit_code": -1,
        }
    if len(code) > MAX_SOURCE_CHARS or len(req.stdin) > MAX_STDIN_CHARS:
        return {
            "success": False,
            "stage": "validation",
            "message": "Mã nguồn hoặc input vượt quá giới hạn cho phép.",
            "stdout": "",
            "stderr": "",
            "exit_code": -1,
        }

    with tempfile.TemporaryDirectory(prefix="oj_") as workdir:
        src_path = os.path.join(workdir, "submission.cpp")
        bin_path = os.path.join(workdir, "submission.exe" if os.name == "nt" else "submission")
        with open(src_path, "w", encoding="utf-8") as f:
            f.write(code)

        # 1. Biên dịch C++17
        try:
            comp = subprocess.run(
                ["g++", "-std=c++17", "-O2", src_path, "-o", bin_path],
                cwd=workdir,
                capture_output=True,
                text=True,
                timeout=COMPILE_TIMEOUT_SEC,
            )
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "stage": "compile",
                "message": "Biên dịch quá thời gian quy định.",
                "stdout": "",
                "stderr": "Compile timeout",
                "exit_code": -1,
            }
        except FileNotFoundError:
            return {
                "success": False,
                "stage": "server_config",
                "message": "Server chưa cài đặt g++.",
                "stdout": "",
                "stderr": "g++ not found",
                "exit_code": -1,
            }

        if comp.returncode != 0:
            return {
                "success": False,
                "stage": "compile",
                "message": "Lỗi biên dịch C++17.",
                "stdout": "",
                "stderr": _clean_compiler_stderr(comp.stderr[:MAX_OUTPUT_CHARS], workdir),
                "exit_code": comp.returncode,
            }

        # 2. Thực thi chương trình trong thư mục tạm riêng
        try:
            run = subprocess.run(
                [bin_path],
                cwd=workdir,
                input=req.stdin,
                capture_output=True,
                text=True,
                timeout=RUN_TIMEOUT_SEC,
            )
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "stage": "runtime",
                "message": f"Chương trình chạy quá thời gian ({RUN_TIMEOUT_SEC}s).",
                "stdout": "",
                "stderr": "Time Limit Exceeded",
                "exit_code": -1,
            }

        ok = run.returncode == 0
        return {
            "success": ok,
            "stage": "completed" if ok else "runtime",
            "message": "Chấm bài hoàn tất." if ok else f"Chương trình kết thúc với mã lỗi {run.returncode}.",
            "stdout": run.stdout[:MAX_OUTPUT_CHARS],
            "stderr": run.stderr[:MAX_OUTPUT_CHARS],
            "exit_code": run.returncode,
        }
