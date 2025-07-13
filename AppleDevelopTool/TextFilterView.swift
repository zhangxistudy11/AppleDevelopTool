import SwiftUI
import UniformTypeIdentifiers

struct TextFilterView: View {
    @State private var originalText = ""
    @State private var keywordGroups: [KeywordGroup] = [KeywordGroup()]
    @State private var filteredResults: [FilteredLine] = []
    @State private var isFiltering = false
    @State private var showingFilePicker = false
    @State private var showingExportSheet = false
    
    struct KeywordGroup: Identifiable {
        let id = UUID()
        var keywords: String = ""
        var logic: FilterLogic = .or
    }
    
    enum FilterLogic: String, CaseIterable {
        case and = "AND"
        case or = "OR"
        
        var description: String {
            switch self {
            case .and: return "必须包含所有关键词"
            case .or: return "包含任一关键词即可"
            }
        }
        
        var color: Color {
            switch self {
            case .and: return .green
            case .or: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .and: return "checkmark.circle.fill"
            case .or: return "plus.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：原始文本输入区域
            VStack(spacing: 16) {
                HStack {
                    Text("原始文本")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button("上传文件") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("清空文本") {
                            originalText = ""
                            filteredResults = []
                        }
                        .buttonStyle(.bordered)
                        .disabled(originalText.isEmpty)
                    }
                }
                
                TextEditor(text: $originalText)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                
                Spacer()
            }
            .padding(20)
            .frame(width: 400)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 右侧：筛选条件和结果
            VStack(spacing: 0) {
                // 筛选条件设置区域
                VStack(spacing: 16) {
                    HStack {
                        Text("筛选条件")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("添加条件组") {
                            keywordGroups.append(KeywordGroup())
                        }
                        .buttonStyle(.bordered)
                        
                        Button("清空条件") {
                            keywordGroups = [KeywordGroup()]
                            filteredResults = []
                        }
                        .buttonStyle(.bordered)
                        .disabled(keywordGroups.count <= 1)
                    }
                    
                    // 逻辑说明
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("筛选逻辑说明")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• AND：必须包含该组中的所有关键词")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• OR：包含该组中任一关键词即可")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• 多个条件组之间为AND关系")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 20)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(6)
                    
                    // 关键词组列表
                    VStack(spacing: 16) {
                        ForEach(Array(keywordGroups.enumerated()), id: \.element.id) { index, group in
                            KeywordGroupView(
                                group: $keywordGroups[index],
                                onDelete: {
                                    if keywordGroups.count > 1 {
                                        keywordGroups.remove(at: index)
                                    }
                                }
                            )
                            
                            // 在组之间显示逻辑选择器（除了最后一个）
                            if index < keywordGroups.count - 1 {
                                LogicSelectorView(logic: $keywordGroups[index].logic)
                            }
                        }
                    }
                    
                    // 操作按钮
                    HStack(spacing: 12) {
                        Button(action: startFiltering) {
                            HStack(spacing: 6) {
                                if isFiltering {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text("开始筛选")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(originalText.isEmpty || !hasValidGroups())
                        
                        Button("导出结果") {
                            showingExportSheet = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(filteredResults.isEmpty)
                        
                        Spacer()
                        
                        if !filteredResults.isEmpty {
                            Text("\(filteredResults.count) 行匹配")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(20)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // 结果展示区域
                VStack(spacing: 0) {
                    HStack {
                        Text("筛选结果")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if !filteredResults.isEmpty {
                            Text("共找到 \(filteredResults.count) 行匹配")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    if filteredResults.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("暂无筛选结果")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            Text("请输入文本和筛选条件，然后点击开始筛选")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredResults) { line in
                                    FilteredLineView(line: line)
                                }
                            }
                        }
                    }
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(maxWidth: .infinity)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    loadTextFromFile(file)
                }
            case .failure(let error):
                print("文件选择错误: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(results: filteredResults)
        }
    }
    
    private func hasValidGroups() -> Bool {
        return keywordGroups.contains { group in
            !group.keywords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func startFiltering() {
        isFiltering = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            filteredResults = filterText()
            isFiltering = false
        }
    }
    
    private func filterText() -> [FilteredLine] {
        let lines = originalText.components(separatedBy: .newlines)
        let validGroups = keywordGroups.filter { !$0.keywords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var results: [FilteredLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            if shouldIncludeLine(trimmedLine, groups: validGroups) {
                let matchedKeywords = getMatchedKeywords(trimmedLine, groups: validGroups)
                results.append(FilteredLine(
                    lineNumber: index + 1,
                    content: line,
                    matchedKeywords: matchedKeywords
                ))
            }
        }
        
        return results
    }
    
    private func shouldIncludeLine(_ line: String, groups: [KeywordGroup]) -> Bool {
        guard !groups.isEmpty else { return true }
        
        // 所有组之间都是AND关系
        return groups.allSatisfy { group in
            let keywords = group.keywords.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            if keywords.isEmpty { return true }
            
            switch group.logic {
            case .and:
                // 必须包含所有关键词
                return keywords.allSatisfy { keyword in
                    line.localizedCaseInsensitiveContains(keyword.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case .or:
                // 包含任一关键词即可
                return keywords.contains { keyword in
                    line.localizedCaseInsensitiveContains(keyword.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }
    
    private func getMatchedKeywords(_ line: String, groups: [KeywordGroup]) -> [String] {
        var matchedKeywords: [String] = []
        
        for group in groups {
            let keywords = group.keywords.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            for keyword in keywords {
                let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if line.localizedCaseInsensitiveContains(trimmedKeyword) {
                    matchedKeywords.append(trimmedKeyword)
                }
            }
        }
        
        return matchedKeywords
    }
    
    private func loadTextFromFile(_ file: URL) {
        do {
            let text = try String(contentsOf: file, encoding: .utf8)
            originalText = text
        } catch {
            print("读取文件错误: \(error.localizedDescription)")
        }
    }
}

// 关键词组视图
struct KeywordGroupView: View {
    @Binding var group: TextFilterView.KeywordGroup
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("关键词组")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 删除按钮
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            // 关键词输入
            TextField("输入关键词（每行一个）", text: $group.keywords, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

// 逻辑选择器视图
struct LogicSelectorView: View {
    @Binding var logic: TextFilterView.FilterLogic
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 8) {
                // 逻辑选择器
                Picker("逻辑", selection: $logic) {
                    ForEach(TextFilterView.FilterLogic.allCases, id: \.self) { logic in
                        HStack {
                            Image(systemName: logic.icon)
                                .foregroundColor(logic.color)
                            Text(logic.rawValue)
                                .foregroundColor(logic.color)
                        }
                        .tag(logic)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                
                // 逻辑说明
                Text(logic.description)
                    .font(.caption)
                    .foregroundColor(logic.color)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(logic.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(logic.color.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
        }
    }
}

// 筛选结果行模型
struct FilteredLine: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let content: String
    let matchedKeywords: [String]
}

// 筛选结果行视图
struct FilteredLineView: View {
    let line: FilteredLine
    @State private var showingCopyMenu = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 行号
            Text("\(line.lineNumber)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
                .padding(.top, 2)
            
            // 内容
            Text(highlightedText)
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
            
            Spacer()
            
            // 复制按钮
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(line.content, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
        
        Divider()
            .padding(.leading, 72)
    }
    
    private var highlightedText: AttributedString {
        var attributedString = AttributedString(line.content)
        
        for keyword in line.matchedKeywords {
            if let range = attributedString.range(of: keyword, options: .caseInsensitive) {
                attributedString[range].backgroundColor = .blue.opacity(0.2)
                attributedString[range].foregroundColor = .blue
            }
        }
        
        return attributedString
    }
}



// 导出视图
struct ExportView: View {
    let results: [FilteredLine]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat = ExportFormat.plainText
    @State private var showingSavePanel = false
    
    enum ExportFormat: String, CaseIterable {
        case plainText = "纯文本"
        case withLineNumbers = "带行号"
        case csv = "CSV格式"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导出筛选结果")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("导出格式")
                    .font(.headline)
                
                Picker("格式", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("预览")
                    .font(.headline)
                
                ScrollView {
                    Text(exportContent)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                .frame(height: 200)
            }
            
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("导出") {
                    showingSavePanel = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 500, height: 400)
        .fileExporter(
            isPresented: $showingSavePanel,
            document: TextDocument(content: exportContent),
            contentType: .plainText,
            defaultFilename: "筛选结果.txt"
        ) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                print("导出错误: \(error.localizedDescription)")
            }
        }
    }
    
    private var exportContent: String {
        switch exportFormat {
        case .plainText:
            return results.map { $0.content }.joined(separator: "\n")
        case .withLineNumbers:
            return results.map { "\($0.lineNumber): \($0.content)" }.joined(separator: "\n")
        case .csv:
            let header = "行号,内容,匹配关键词\n"
            let rows = results.map { line in
                let keywords = line.matchedKeywords.joined(separator: ";")
                return "\(line.lineNumber),\"\(line.content)\",\"\(keywords)\""
            }.joined(separator: "\n")
            return header + rows
        }
    }
}

// 文本文档
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        content = ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(content.utf8)
        return .init(regularFileWithContents: data)
    }
}

#Preview {
    TextFilterView()
} 
