import os
import sys


def scan_files(path):
    folder_name = os.path.basename(os.path.normpath(path))
    entries = sorted(os.listdir(path))
    file_list = []

    for entry in entries:
        full_path = os.path.join(path, entry)
        if not os.path.isfile(full_path):
            continue
        name, ext = os.path.splitext(entry)
        new_name = f"{folder_name}{name}{ext}"
        file_list.append((entry, new_name))

    return folder_name, file_list


def preview(folder_name, file_list):
    if not file_list:
        print("\n  文件夹内没有文件")
        return

    print(f"\n  文件夹: {folder_name}  |  共 {len(file_list)} 个文件\n")
    print(f"  {'原文件名':<30s}  →  {'新文件名'}")
    print(f"  {'-'*30}     {'-'*30}")
    for old_name, new_name in file_list:
        print(f"  {old_name:<30s}  →  {new_name}")


def rename(path, file_list):
    success = 0
    errors = []

    for old_name, new_name in file_list:
        old_path = os.path.join(path, old_name)
        new_path = os.path.join(path, new_name)
        try:
            os.rename(old_path, new_path)
            success += 1
        except Exception as e:
            errors.append(f"  {old_name} -> {new_name}: {e}")

    return success, errors


def main():
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        print("批量文件重命名工具")
        print("=" * 50)
        path = input("\n请输入文件夹路径: ").strip()

    path = os.path.expanduser(path)
    path = os.path.normpath(path)

    if not os.path.isdir(path):
        print(f"\n错误: \"{path}\" 不是有效的文件夹路径")
        sys.exit(1)

    folder_name, file_list = scan_files(path)
    preview(folder_name, file_list)

    if not file_list:
        sys.exit(0)

    confirm = input(f"\n确认重命名以上 {len(file_list)} 个文件? (y/n): ").strip().lower()
    if confirm not in ("y", "yes"):
        print("已取消")
        sys.exit(0)

    success, errors = rename(path, file_list)

    if errors:
        print(f"\n完成: 成功 {success} 个，失败 {len(errors)} 个:")
        for err in errors:
            print(err)
    else:
        print(f"\n全部 {success} 个文件重命名成功!")

    folder_name, file_list = scan_files(path)
    preview(folder_name, file_list)


if __name__ == "__main__":
    main()
