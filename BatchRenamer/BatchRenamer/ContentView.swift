import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    let originalName: String
    let newName: String
}

struct PrefixInputView: View {
    @Binding var prefix: String
    let defaultPrefix: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("设置文件名前缀")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("前缀将添加到每个文件名前，例如 \"01.jpg\" → \"\(sanitize(prefix))01.jpg\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("请输入前缀", text: $prefix)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit { onConfirm() }
            }

            HStack(spacing: 12) {
                Button("取消") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button("确认") { onConfirm() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(prefix.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 380)
    }
}

struct ContentView: View {
    @State private var selectedFolder: String?
    @State private var folderName: String = ""
    @State private var namePrefix: String = ""
    @State private var fileItems: [FileItem] = []
    @State private var isProcessing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showConfirm: Bool = false
    @State private var showPrefixInput: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            if fileItems.isEmpty {
                emptyState
            } else {
                fileListSection
            }
            Divider()
            footerSection
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("好的") {}
        } message: {
            Text(alertMessage)
        }
        .alert("确认重命名", isPresented: $showConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认") { performRename() }
        } message: {
            Text("即将重命名 \(fileItems.count) 个文件，此操作不可撤销。")
        }
        .sheet(isPresented: $showPrefixInput) {
            PrefixInputView(
                prefix: $namePrefix,
                defaultPrefix: folderName,
                onConfirm: {
                    showPrefixInput = false
                    if let path = selectedFolder {
                        scanFiles(at: path)
                    }
                },
                onCancel: {
                    showPrefixInput = false
                    selectedFolder = nil
                    folderName = ""
                    namePrefix = ""
                    fileItems = []
                }
            )
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedFolder ?? "未选择文件夹")
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !namePrefix.isEmpty {
                    Text("命名前缀: \(namePrefix)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                selectFolder()
            } label: {
                Label("选择文件夹", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("选择一个文件夹以预览重命名结果")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileListSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("原文件名")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("新文件名")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(fileItems.enumerated()), id: \.element.id) { _, item in
                        HStack {
                            Text(item.originalName)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text(item.newName)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .padding(.horizontal, 8)
                        )
                    }
                }
            }
        }
    }

    private var footerSection: some View {
        HStack {
            if !fileItems.isEmpty {
                Text("共 \(fileItems.count) 个文件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !fileItems.isEmpty {
                Button(action: { showPrefixInput = true }) {
                    Label("修改前缀", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .padding(.trailing, 8)

                Button(action: { showConfirm = true }) {
                    Label("执行重命名", systemImage: "pencil.line")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .disabled(isProcessing)
            }
        }
        .padding(16)
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "选择要重命名的文件夹"
        panel.prompt = "选择"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        selectedFolder = url.path
        folderName = url.lastPathComponent
        namePrefix = folderName
        showPrefixInput = true
    }

    private func scanFiles(at path: String) {
        fileItems.removeAll()
        let fm = FileManager.default

        guard let entries = try? fm.contentsOfDirectory(atPath: path) else { return }

        let sorted = entries.sorted()
        for entry in sorted {
            let fullPath = path + "/" + entry
            var isDir: ObjCBool = false
            fm.fileExists(atPath: fullPath, isDirectory: &isDir)
            guard isDir.boolValue == false else { continue }

            let ext = (entry as NSString).pathExtension
            let nameWithoutExt = (entry as NSString).deletingPathExtension
            let cleanedPrefix = sanitize(namePrefix)
            let cleanedName = sanitize(nameWithoutExt)
            let cleanedExt = sanitize(ext)
            let newName = cleanedPrefix + cleanedName + (cleanedExt.isEmpty ? "" : "." + cleanedExt)
            fileItems.append(FileItem(originalName: entry, newName: newName))
        }
    }

    private func performRename() {
        guard let path = selectedFolder else { return }
        isProcessing = true

        var success = 0
        var errors: [String] = []

        for item in fileItems {
            let oldPath = path + "/" + item.originalName
            let newPath = path + "/" + item.newName
            do {
                try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
                success += 1
            } catch {
                errors.append("\(item.originalName) → \(item.newName): \(error.localizedDescription)")
            }
        }

        isProcessing = false

        if errors.isEmpty {
            alertTitle = "重命名完成"
            alertMessage = "全部 \(success) 个文件重命名成功！"
        } else {
            alertTitle = "部分失败"
            alertMessage = "成功: \(success)\n失败:\n" + errors.joined(separator: "\n")
        }
        showAlert = true

        scanFiles(at: path)
    }
}

func sanitize(_ text: String) -> String {
    var result = ""
    for scalar in text.unicodeScalars {
        let ch = Character(scalar)
        if isForbidden(scalar) {
            result.append("_")
        } else {
            result.append(ch)
        }
    }
    while result.hasPrefix("/") || result.hasPrefix("\\") {
        result.removeFirst()
    }
    if result.isEmpty { result = "_" }
    return result
}

func isForbidden(_ scalar: Unicode.Scalar) -> Bool {
    let value = scalar.value
    if value == 0x20 || value == 0xA0 || value == 0x3000 {
        return true
    }
    if value == 0x09 || value == 0x0A || value == 0x0B || value == 0x0C || value == 0x0D {
        return true
    }
    if value == 0x23 || value == 0x25 || value == 0x26 || value == 0x5C || value == 0x22
        || value == 0x3C || value == 0x3E || value == 0x3F || value == 0x24 || value == 0x2B
        || value == 0x2C || value == 0x2F || value == 0x2A || value == 0x3A || value == 0x7C {
        return true
    }
    if value == 0xFF0C {
        return true
    }
    return false
}
