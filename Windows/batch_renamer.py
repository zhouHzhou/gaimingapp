import os
import tkinter as tk
from tkinter import filedialog, messagebox, ttk


class BatchRenamerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("批量重命名")
        self.root.geometry("680x520")
        self.root.resizable(True, True)

        self.selected_folder = tk.StringVar()
        self.name_prefix = tk.StringVar()
        self.folder_name = ""
        self.file_list = []

        self._build_ui()

    def _build_ui(self):
        main = ttk.Frame(self.root, padding=0)
        main.pack(fill=tk.BOTH, expand=True)

        header = ttk.Frame(main, padding=(16, 12))
        header.pack(fill=tk.X)

        ttk.Label(header, text="📁", font=("", 18)).pack(side=tk.LEFT, padx=(0, 8))
        info_frame = ttk.Frame(header)
        info_frame.pack(side=tk.LEFT, fill=tk.X, expand=True)

        self.folder_label = ttk.Label(info_frame, text="未选择文件夹", font=("", 10))
        self.folder_label.pack(anchor=tk.W)
        self.prefix_label = ttk.Label(info_frame, text="", font=("", 9), foreground="gray")
        self.prefix_label.pack(anchor=tk.W)

        ttk.Button(header, text="选择文件夹", command=self._select_folder).pack(side=tk.RIGHT)

        ttk.Separator(main, orient=tk.HORIZONTAL).pack(fill=tk.X)

        content = ttk.Frame(main)
        content.pack(fill=tk.BOTH, expand=True, padx=16, pady=8)

        self.empty_label = ttk.Label(content, text="选择一个文件夹以预览重命名结果", foreground="gray", font=("", 11))
        self.empty_label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)

        cols_frame = ttk.Frame(content)
        cols_frame.pack(fill=tk.BOTH, expand=True)

        col_header = ttk.Frame(cols_frame)
        col_header.pack(fill=tk.X, pady=(0, 4))
        ttk.Label(col_header, text="原文件名", font=("", 9, "bold"), foreground="gray").pack(side=tk.LEFT)
        ttk.Label(col_header, text="新文件名", font=("", 9, "bold"), foreground="gray").pack(side=tk.RIGHT)

        tree_frame = ttk.Frame(cols_frame)
        tree_frame.pack(fill=tk.BOTH, expand=True)

        self.tree = ttk.Treeview(tree_frame, columns=("original", "arrow", "new"), show="tree", selectmode="none", height=15)
        self.tree.column("#0", width=0, stretch=False)
        self.tree.column("original", width=250, anchor=tk.W)
        self.tree.column("arrow", width=40, anchor=tk.CENTER)
        self.tree.column("new", width=250, anchor=tk.W)

        scrollbar = ttk.Scrollbar(tree_frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)
        self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.tree.tag_configure("row", font=("Consolas", 10))
        self.tree.tag_configure("new_name", font=("Consolas", 10), foreground="#0066CC")

        ttk.Separator(main, orient=tk.HORIZONTAL).pack(fill=tk.X)

        footer = ttk.Frame(main, padding=(16, 10))
        footer.pack(fill=tk.X)

        self.count_label = ttk.Label(footer, text="", font=("", 9), foreground="gray")
        self.count_label.pack(side=tk.LEFT)

        btn_frame = ttk.Frame(footer)
        btn_frame.pack(side=tk.RIGHT)

        self.edit_btn = ttk.Button(btn_frame, text="✏ 修改前缀", command=self._edit_prefix, state=tk.DISABLED)
        self.edit_btn.pack(side=tk.LEFT, padx=(0, 8))

        self.rename_btn = ttk.Button(btn_frame, text="▶ 执行重命名", command=self._confirm_rename, state=tk.DISABLED)
        self.rename_btn.pack(side=tk.LEFT)

    def _select_folder(self):
        path = filedialog.askdirectory(title="选择要重命名的文件夹")
        if not path:
            return

        self.selected_folder.set(path)
        self.folder_name = os.path.basename(os.path.normpath(path))
        self.name_prefix.set(self.folder_name)
        self.folder_label.config(text=path)

        self._show_prefix_dialog()

    def _show_prefix_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("设置文件名前缀")
        dialog.geometry("400x180")
        dialog.resizable(False, False)
        dialog.transient(self.root)
        dialog.grab_set()

        dialog.update_idletasks()
        x = self.root.winfo_x() + (self.root.winfo_width() - 400) // 2
        y = self.root.winfo_y() + (self.root.winfo_height() - 180) // 2
        dialog.geometry(f"+{x}+{y}")

        ttk.Label(dialog, text="设置文件名前缀", font=("", 12, "bold")).pack(pady=(20, 8))

        input_frame = ttk.Frame(dialog)
        input_frame.pack(fill=tk.X, padx=24)

        ttk.Label(input_frame, text=f'前缀将添加到每个文件名前，例如 "01.jpg" → "前缀01.jpg"', font=("", 9), foreground="gray").pack(anchor=tk.W, pady=(0, 4))

        entry = ttk.Entry(input_frame, textvariable=self.name_prefix, font=("Consolas", 11))
        entry.pack(fill=tk.X)
        entry.select_range(0, tk.END)
        entry.focus_set()

        btn_frame = ttk.Frame(dialog)
        btn_frame.pack(pady=(16, 0))

        def on_cancel():
            dialog.destroy()
            self.selected_folder.set("")
            self.folder_name = ""
            self.name_prefix.set("")
            self.folder_label.config(text="未选择文件夹")
            self.prefix_label.config(text="")
            self.file_list = []
            self._refresh_tree()

        def on_confirm():
            if not self.name_prefix.get().strip():
                messagebox.showwarning("提示", "前缀不能为空", parent=dialog)
                return
            dialog.destroy()
            self.prefix_label.config(text=f"命名前缀: {self.name_prefix.get()}")
            self._scan_files()

        ttk.Button(btn_frame, text="取消", command=on_cancel).pack(side=tk.LEFT, padx=(0, 12))
        ttk.Button(btn_frame, text="确认", command=on_confirm).pack(side=tk.LEFT)

        entry.bind("<Return>", lambda e: on_confirm())
        entry.bind("<Escape>", lambda e: on_cancel())

        dialog.protocol("WM_DELETE_WINDOW", on_cancel)

    def _edit_prefix(self):
        self._show_prefix_dialog()

    def _scan_files(self):
        self.file_list = []
        path = self.selected_folder.get()
        prefix = self.name_prefix.get()

        if not path or not os.path.isdir(path):
            return

        entries = sorted(os.listdir(path))
        for entry in entries:
            full_path = os.path.join(path, entry)
            if not os.path.isfile(full_path):
                continue
            name, ext = os.path.splitext(entry)
            new_name = f"{prefix}{name}{ext}"
            self.file_list.append((entry, new_name))

        self._refresh_tree()

    def _refresh_tree(self):
        self.tree.delete(*self.tree.get_children())

        if not self.file_list:
            self.empty_label.place(relx=0.5, rely=0.5, anchor=tk.CENTER)
            self.count_label.config(text="")
            self.edit_btn.config(state=tk.DISABLED)
            self.rename_btn.config(state=tk.DISABLED)
            return

        self.empty_label.place_forget()

        for old_name, new_name in self.file_list:
            self.tree.insert("", tk.END, values=(old_name, "→", new_name), tags=("row",))

        self.count_label.config(text=f"共 {len(self.file_list)} 个文件")
        self.edit_btn.config(state=tk.NORMAL)
        self.rename_btn.config(state=tk.NORMAL)

    def _confirm_rename(self):
        if not self.file_list:
            return

        count = len(self.file_list)
        confirm = messagebox.askyesno("确认重命名", f"即将重命名 {count} 个文件，此操作不可撤销。\n是否继续？")
        if not confirm:
            return

        self._perform_rename()

    def _perform_rename(self):
        path = self.selected_folder.get()
        if not path:
            return

        success = 0
        errors = []

        for old_name, new_name in self.file_list:
            old_path = os.path.join(path, old_name)
            new_path = os.path.join(path, new_name)
            try:
                os.rename(old_path, new_path)
                success += 1
            except Exception as e:
                errors.append(f"{old_name} -> {new_name}: {e}")

        if errors:
            detail = "\n".join(errors[:10])
            messagebox.showerror("部分失败", f"成功: {success}\n失败:\n{detail}")
        else:
            messagebox.showinfo("重命名完成", f"全部 {success} 个文件重命名成功！")

        self._scan_files()


def main():
    root = tk.Tk()
    try:
        root.iconbitmap(default="")
    except Exception:
        pass
    BatchRenamerApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
