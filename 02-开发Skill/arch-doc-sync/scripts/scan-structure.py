#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""扫描源码目录，输出模块 / 分层 / 文件数清单（Markdown），供架构文档回填。

用法：
    python scan-structure.py <代码根目录> [-o structure.md] [--base-package com.example.project]

输出示例：

    | 模块 | controller | application | domain | infrastructure | 合计 |
    |------|-----------|-------------|--------|---------------|------|
    | order | 3 | 2 | 5 | 2 | 12 |
"""
import argparse
import os
import sys

LAYERS = ("controller", "application", "domain", "infrastructure")
SKIP_DIRS = {".git", "node_modules", "target", "build", "dist", ".idea", ".vscode"}


def module_of(rel_path):
    """取相对路径中层目录之后的下一个目录作为模块名；没有则归入 (root)。"""
    parts = rel_path.replace("\\", "/").split("/")
    for i, p in enumerate(parts):
        if p in LAYERS:
            if i + 1 < len(parts) - 1:
                return parts[i + 1]
            return "(root)"
    return "(未分层)"


def main():
    parser = argparse.ArgumentParser(description="扫描源码结构并输出 Markdown 清单")
    parser.add_argument("root", help="代码根目录")
    parser.add_argument("-o", "--output", default="", help="输出文件，缺省打印到 stdout")
    parser.add_argument("--base-package", default="", help="基础包名（仅用于说明）")
    args = parser.parse_args()

    if not os.path.isdir(args.root):
        print("错误：目录不存在 -> %s" % args.root)
        return 2

    stats = {}
    total = 0
    for base, dirs, files in os.walk(args.root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if not name.endswith((".java", ".kt", ".ts", ".vue", ".js", ".py", ".go")):
                continue
            full = os.path.join(base, name)
            rel = os.path.relpath(full, args.root)
            layer = next((p for p in rel.replace("\\", "/").split("/") if p in LAYERS), "(未分层)")
            module = module_of(rel)
            cell = stats.setdefault(module, {L: 0 for L in LAYERS})
            cell["(未分层)"] = cell.get("(未分层)", 0)
            cell["(未分层)" if layer == "(未分层)" else layer] += 1
            total += 1

    columns = list(LAYERS) + ["(未分层)"]
    lines = []
    lines.append("# 代码结构清单")
    lines.append("")
    lines.append("- 代码根目录：`%s`" % args.root)
    if args.base_package:
        lines.append("- 基础包名：`%s`" % args.base_package)
    lines.append("- 源文件总数：%d" % total)
    lines.append("")
    header = "| 模块 | " + " | ".join(columns) + " | 合计 |"
    lines.append(header)
    lines.append("|" + "---|" * (len(columns) + 2))
    for module in sorted(stats):
        cells = stats[module]
        row_total = sum(cells.get(c, 0) for c in columns)
        lines.append("| %s | %s | %d |" % (
            module, " | ".join(str(cells.get(c, 0)) for c in columns), row_total))
    text = "\n".join(lines) + "\n"

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(text)
        print("已写出 %s（%d 个源文件，%d 个模块）" % (args.output, total, len(stats)))
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())