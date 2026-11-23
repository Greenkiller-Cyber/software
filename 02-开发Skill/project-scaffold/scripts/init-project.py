#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""【项目名】项目脚手架初始化 / 结构自检（project-scaffold Skill 的可执行资产）。

用法：
    # 预览将创建的目录（不落盘）
    python init-project.py --name 校园圈 --package com.example.campus --dry-run

    # 实际创建
    python init-project.py --name 校园圈 --package com.example.campus

    # 对现有目录做结构自检（四层是否齐全、domain 是否引用框架）
    python init-project.py --verify

退出码：0 成功 / 1 自检未通过 / 2 参数或路径错误。
"""
import argparse
import os
import sys

LAYERS = ("controller", "application", "domain", "infrastructure")
SKIP_DIRS = {".git", "node_modules", "target", "build", "dist", ".idea", ".vscode"}

ENV_EXAMPLE = """# 复制为 .env 后填入真实值；.env 必须写进 .gitignore
DB_HOST=localhost
DB_PORT=3306
DB_NAME=
DB_USER=
DB_PASSWORD=
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=
MQ_HOST=localhost
"""


def package_path(pkg):
    return pkg.replace(".", "/")


def expected_dirs(pkg):
    pp = package_path(pkg)
    dirs = []
    for layer in LAYERS:
        dirs.append("backend/src/main/java/%s/%s" % (pp, layer))
        dirs.append("backend/src/test/java/%s/%s" % (pp, layer))
    dirs += ["backend/src/main/resources", "frontend/src", "docs/api", "scripts"]
    return dirs


def do_create(args):
    root = os.path.abspath(args.target)
    dirs = expected_dirs(args.package)
    print("项目：%s    基础包：%s" % (args.name, args.package))
    print("将创建 %d 个目录：" % len(dirs))
    for d in dirs:
        print("  ", d)

    if args.dry_run:
        print("\n（dry-run 模式，未实际创建。去掉 --dry-run 执行。）")
        return 0

    for d in dirs:
        full = os.path.join(root, d)
        os.makedirs(full, exist_ok=True)
        keep = os.path.join(full, ".gitkeep")
        if not os.path.exists(keep):
            open(keep, "w", encoding="utf-8").close()

    env_example = os.path.join(root, ".env.example")
    if not os.path.exists(env_example):
        with open(env_example, "w", encoding="utf-8") as f:
            f.write(ENV_EXAMPLE)
        print("已生成 .env.example（只含键名，无真实密钥）")

    print("\n✅ 脚手架生成完成，运行 `python init-project.py --verify` 自检。")
    return 0


def do_verify(args):
    root = os.path.abspath(args.target)
    problems = []

    for d in expected_dirs(args.package):
        if not os.path.isdir(os.path.join(root, d)):
            problems.append("缺少目录：%s" % d)

    # domain 层不得引用框架（规则 R-02）
    domain_dir = os.path.join(root, "backend/src/main/java", package_path(args.package), "domain")
    if os.path.isdir(domain_dir):
        for base, _, files in os.walk(domain_dir):
            for name in files:
                if not name.endswith((".java", ".kt")):
                    continue
                path = os.path.join(base, name)
                with open(path, encoding="utf-8", errors="replace") as f:
                    src = f.read()
                for bad in ("org.springframework", "com.baomidou", "javax.servlet", "jakarta.servlet"):
                    if bad in src:
                        problems.append("domain 层禁止引用 %s：%s" % (bad, path))

    if problems:
        print("❌ 结构自检未通过，共 %d 项：" % len(problems))
        for p in problems:
            print("  -", p)
        return 1

    print("✅ 结构自检通过：四层目录齐全，domain 层无框架依赖。")
    return 0


def main():
    parser = argparse.ArgumentParser(description="项目脚手架初始化 / 结构自检")
    parser.add_argument("--name", default="project", help="项目名称（仅用于输出）")
    parser.add_argument("--package", default="com.example.project",
                        help="后端基础包名，如 com.example.project")
    parser.add_argument("--target", default=".", help="生成位置，默认当前目录")
    parser.add_argument("--dry-run", action="store_true", help="只预览，不落盘")
    parser.add_argument("--verify", action="store_true", help="只做结构自检")
    args = parser.parse_args()

    if args.verify:
        return do_verify(args)
    return do_create(args)


if __name__ == "__main__":
    sys.exit(main())