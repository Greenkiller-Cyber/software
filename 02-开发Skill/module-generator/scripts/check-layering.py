#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""四层架构依赖方向校验。

规则（对应设计说明书 §3.3 的 R-01 ~ R-04）：
    controller     -> application, domain, common
    application    -> domain, common
    domain         -> common
    infrastructure -> domain, common

禁止：
    - 跨层反向依赖（如 domain 依赖 infrastructure）
    - controller 直接依赖 repository/infrastructure（R-01）
    - domain 层引用 Spring / MyBatis / Servlet（R-02）
    - infrastructure 反向依赖 application（R-04）

用法：
    python check-layering.py <代码根目录> [--base-package com.example.project] [--verbose]

退出码：0 = 通过；1 = 存在违规；2 = 参数或路径错误。
"""
import argparse
import os
import re
import sys

LAYERS = ("controller", "application", "domain", "infrastructure")
ALLOWED = {
    "controller": {"application", "domain", "common"},
    "application": {"domain", "common"},
    "domain": {"common"},
    "infrastructure": {"domain", "common"},
}
# 这些包出现在 import 里即视为对相应层的依赖
LAYER_ALIASES = {
    "repository": "infrastructure",
    "dao": "infrastructure",
    "mapper": "infrastructure",
    "service": "application",
    "impl": "infrastructure",
}
FORBIDDEN_IMPORT = {
    "domain": ["org.springframework", "com.baomidou", "javax.servlet",
               "jakarta.servlet", "org.apache.ibatis"],
}
IMPORT_RE = re.compile(r"^\s*import\s+(?:static\s+)?([\w.]+(?:\.\*)?)\s*;")


def layer_of(path):
    """按目录名识别文件所属层，支持 /controller/... 形式。"""
    parts = [p.lower() for p in path.replace("\\", "/").split("/")]
    for layer in LAYERS:
        if layer in parts:
            return layer
    return None


def target_layer(import_path, base_package):
    """从 import 全名推断被依赖的层。"""
    name = import_path
    if base_package and name.startswith(base_package + "."):
        name = name[len(base_package) + 1:]
    segments = name.split(".")
    if not segments:
        return None
    # 取第一段与末段分别匹配层名
    for seg in (segments[0], segments[-1]):
        seg = seg.lower()
        if seg in LAYERS:
            return seg
        if seg in LAYER_ALIASES:
            return LAYER_ALIASES[seg]
    return None


def check_file(path, base_package, verbose):
    layer = layer_of(path)
    if layer is None:
        return []
    errors = []
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            source = f.read()
    except OSError as exc:
        return ["%s: 读取失败（%s）" % (path, exc)]

    for line in source.splitlines():
        m = IMPORT_RE.match(line)
        if not m:
            continue
        imp = m.group(1)
        tgt = target_layer(imp, base_package)
        if tgt and tgt not in ALLOWED[layer]:
            errors.append("%s: 层 %s 不允许依赖 %s（import %s）" % (path, layer, tgt, imp))

    for bad in FORBIDDEN_IMPORT.get(layer, []):
        if bad in source:
            errors.append("%s: 层 %s 禁止引入 %s（规则 R-02）" % (path, layer, bad))

    if verbose:
        print("  ok  %s (%s)" % (path, layer))
    return errors


def main():
    parser = argparse.ArgumentParser(description="四层架构依赖方向校验")
    parser.add_argument("root", help="代码根目录，如 backend/src/main/java")
    parser.add_argument("--base-package", default="", help="基础包名，如 com.example.project")
    parser.add_argument("--verbose", action="store_true", help="逐个文件输出检查结果")
    args = parser.parse_args()

    if not os.path.isdir(args.root):
        print("错误：目录不存在 -> %s" % args.root)
        return 2

    checked, errors, layer_stat = 0, [], {}
    for base, _, files in os.walk(args.root):
        for name in files:
            if not name.endswith(".java"):
                continue
            path = os.path.join(base, name)
            layer = layer_of(path)
            if layer is None:
                continue
            checked += 1
            layer_stat[layer] = layer_stat.get(layer, 0) + 1
            errors.extend(check_file(path, args.base_package, args.verbose))

    print("已检查 %d 个分层文件：%s" % (
        checked, "、".join("%s=%d" % (k, v) for k, v in sorted(layer_stat.items())) or "无"))

    if checked == 0:
        print("警告：未找到任何 controller/application/domain/infrastructure 目录下的 .java 文件。")
        print("      请确认 --root 指向源码根目录（如 backend/src/main/java）。")
        return 0

    if errors:
        print("❌ 架构约束校验未通过，共 %d 处：" % len(errors))
        for e in errors:
            print("  -", e)
        return 1

    print("✅ 架构约束校验通过：无反向依赖、无禁止引用。")
    return 0


if __name__ == "__main__":
    sys.exit(main())