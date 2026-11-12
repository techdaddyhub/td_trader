"""Applies unified TechDaddy TD AI Robot icons and branding to generated Flutter platform scaffolding."""

import os
import re
import shutil
import sys


def copy_tree_contents(src_dir: str, dst_dir: str):
    os.makedirs(dst_dir, exist_ok=True)
    for root, dirs, files in os.walk(src_dir):
        rel = os.path.relpath(root, src_dir)
        target_root = dst_dir if rel == "." else os.path.join(dst_dir, rel)
        os.makedirs(target_root, exist_ok=True)
        for d in dirs:
            os.makedirs(os.path.join(target_root, d), exist_ok=True)
        for fname in files:
            shutil.copy2(os.path.join(root, fname), os.path.join(target_root, fname))


def apply_android(root: str = "."):
    src = os.path.join(root, "android_res")
    dst = os.path.join(root, "android", "app", "src", "main", "res")
    if os.path.isdir(src) and os.path.isdir(dst):
        print("Injecting custom TD Robot icons into Android mipmap directories...")
        copy_tree_contents(src, dst)

    manifest = os.path.join(root, "android", "app", "src", "main", "AndroidManifest.xml")
    if os.path.isfile(manifest):
        with open(manifest, "r", encoding="utf-8") as f:
            xml = f.read()
        xml = xml.replace('android:label="td_trader"', 'android:label="TD TRADER"')
        if "android.permission.INTERNET" not in xml:
            xml = xml.replace(
                "<application",
                '    <uses-permission android:name="android.permission.INTERNET"/>\n'
                '    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>\n'
                "    <application",
                1,
            )
        elif "android.permission.ACCESS_NETWORK_STATE" not in xml:
            xml = xml.replace(
                "<application",
                '    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>\n'
                "    <application",
                1,
            )
        if "android:usesCleartextTraffic" not in xml:
            xml = xml.replace(
                "<application",
                '<application\n        android:usesCleartextTraffic="true"',
                1,
            )
        with open(manifest, "w", encoding="utf-8") as f:
            f.write(xml)


def apply_web(root: str = "."):
    web_src = os.path.join(root, "desktop_res", "web")
    web_dst = os.path.join(root, "web")
    if os.path.isdir(web_src) and os.path.isdir(web_dst):
        print("Injecting custom TD Robot favicon and PWA icons into Web app...")
        fav = os.path.join(web_src, "favicon.png")
        if os.path.isfile(fav):
            shutil.copy2(fav, os.path.join(web_dst, "favicon.png"))
        icons_src = os.path.join(web_src, "icons")
        if os.path.isdir(icons_src):
            copy_tree_contents(icons_src, os.path.join(web_dst, "icons"))

    index_html = os.path.join(web_dst, "index.html")
    if os.path.isfile(index_html):
        with open(index_html, "r", encoding="utf-8") as f:
            html = f.read()
        html = html.replace(
            "<title>td_trader</title>",
            "<title>TD TRADER - TechDaddy AI Trading Ecosystem</title>",
        )
        with open(index_html, "w", encoding="utf-8") as f:
            f.write(html)


def apply_linux(root: str = "."):
    app_cc = os.path.join(root, "linux", "runner", "my_application.cc")
    if os.path.isfile(app_cc):
        print("Injecting TD TRADER title and GTK window icon into Linux runner...")
        with open(app_cc, "r", encoding="utf-8") as f:
            src = f.read()
        src = src.replace('"td_trader"', '"TD TRADER - TechDaddy"')
        hook = 'gtk_window_set_title(window, "TD TRADER - TechDaddy");'
        icon_snippet = hook + """
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path != nullptr) {
    g_autofree gchar* exe_dir = g_path_get_dirname(exe_path);
    g_autofree gchar* icon_path = g_build_filename(
        exe_dir, "data", "flutter_assets", "assets", "images", "app_icon.png", nullptr);
    if (g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
      gtk_window_set_icon_from_file(window, icon_path, nullptr);
    }
  }"""
        if hook in src and "gtk_window_set_icon_from_file" not in src:
            src = src.replace(hook, icon_snippet, 1)
        with open(app_cc, "w", encoding="utf-8") as f:
            f.write(src)


def apply_windows(root: str = "."):
    ico_src = os.path.join(root, "desktop_res", "windows", "app_icon.ico")
    ico_dst = os.path.join(root, "windows", "runner", "resources", "app_icon.ico")
    if os.path.isfile(ico_src) and os.path.isdir(os.path.dirname(ico_dst)):
        print("Injecting multi-resolution TD Robot .ico into Windows executable...")
        shutil.copy2(ico_src, ico_dst)

    main_cpp = os.path.join(root, "windows", "runner", "main.cpp")
    if os.path.isfile(main_cpp):
        with open(main_cpp, "r", encoding="utf-8") as f:
            cpp = f.read()
        cpp = cpp.replace('L"td_trader"', 'L"TD TRADER - TechDaddy"')
        with open(main_cpp, "w", encoding="utf-8") as f:
            f.write(cpp)

    runner_rc = os.path.join(root, "windows", "runner", "Runner.rc")
    if os.path.isfile(runner_rc):
        with open(runner_rc, "r", encoding="utf-8") as f:
            rc = f.read()
        replacements = [
            (r'VALUE\s+"CompanyName",\s+"[^"]*"', 'VALUE "CompanyName", "TechDaddy"'),
            (
                r'VALUE\s+"FileDescription",\s+"[^"]*"',
                'VALUE "FileDescription", "TD TRADER - AI Trading Ecosystem"',
            ),
            (r'VALUE\s+"ProductName",\s+"[^"]*"', 'VALUE "ProductName", "TD TRADER"'),
            (
                r'VALUE\s+"LegalCopyright",\s+"[^"]*"',
                'VALUE "LegalCopyright", "Copyright (C) 2026 TechDaddy. All rights reserved."',
            ),
        ]
        for pattern, repl in replacements:
            rc = re.sub(pattern, repl, rc)
        with open(runner_rc, "w", encoding="utf-8") as f:
            f.write(rc)


def apply_macos(root: str = "."):
    src_set = os.path.join(root, "desktop_res", "macos", "AppIcon.appiconset")
    dst_set = os.path.join(root, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if os.path.isdir(src_set) and os.path.isdir(os.path.dirname(dst_set)):
        print("Injecting custom TD Robot AppIcon.appiconset into macOS bundle...")
        if os.path.isdir(dst_set):
            shutil.rmtree(dst_set)
        copy_tree_contents(src_set, dst_set)

    xcconfig = os.path.join(root, "macos", "Runner", "Configs", "AppInfo.xcconfig")
    if os.path.isfile(xcconfig):
        with open(xcconfig, "r", encoding="utf-8") as f:
            lines = f.read().splitlines()
        updated = []
        for line in lines:
            if line.startswith("PRODUCT_NAME"):
                updated.append("PRODUCT_NAME = TDTrader")
            elif line.startswith("PRODUCT_COPYRIGHT"):
                updated.append("PRODUCT_COPYRIGHT = Copyright © 2026 TechDaddy. All rights reserved.")
            else:
                updated.append(line)
        with open(xcconfig, "w", encoding="utf-8") as f:
            f.write("\n".join(updated) + "\n")


HANDLERS = {
    "android": apply_android,
    "web": apply_web,
    "linux": apply_linux,
    "windows": apply_windows,
    "macos": apply_macos,
}


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in HANDLERS:
        print(f"Usage: {sys.argv[0]} <{'|'.join(HANDLERS.keys())}>")
        sys.exit(1)
    HANDLERS[sys.argv[1]](".")
