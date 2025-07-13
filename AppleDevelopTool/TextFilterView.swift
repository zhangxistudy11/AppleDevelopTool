import SwiftUI
import UniformTypeIdentifiers

struct TextFilterView: View {
    @State private var originalText = ""
    @State private var includeKeywords = ""
    @State private var includeLogic: FilterLogic = .or
    @State private var filteredResults: [FilteredLine] = []
    @State private var isFiltering = false
    @State private var showingFilePicker = false
    @State private var showingExportSheet = false
    
    enum FilterLogic: String, CaseIterable {
        case and = "与关系 (AND)"
        case or = "或关系 (OR)"
        
        var description: String {
            switch self {
            case .and: return "必须包含所有关键词"
            case .or: return "包含任一关键词即可"
            }
        }
        
        var icon: String {
            switch self {
            case .and: return "checkmark.circle.fill"
            case .or: return "plus.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .and: return .green
            case .or: return .blue
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
                VStack(spacing: 20) {
                    // 标题区域
                    HStack {
                        Text("筛选条件")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("清除条件") {
                            includeKeywords = ""
                            includeLogic = .or
                            filteredResults = []
                        }
                        .buttonStyle(.bordered)
                        .disabled(includeKeywords.isEmpty)
                    }
                    
                    // 筛选逻辑选择区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("筛选逻辑")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 16) {
                            ForEach(FilterLogic.allCases, id: \.self) { logic in
                                LogicCard(
                                    logic: logic,
                                    isSelected: includeLogic == logic,
                                    action: { includeLogic = logic }
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    
                    // 关键词输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundColor(.orange)
                                .font(.title3)
                            Text("关键词设置")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("请输入要筛选的关键词（每行一个）")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $includeKeywords)
                                .font(.system(size: 13))
                                .frame(height: 100)
                                .padding(12)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    
                    // 操作按钮区域
                    VStack(spacing: 12) {
                        Button(action: startFiltering) {
                            HStack(spacing: 8) {
                                if isFiltering {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text("开始筛选")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(originalText.isEmpty || includeKeywords.isEmpty)
                        
                        HStack(spacing: 12) {
                            Button("导出结果") {
                                showingExportSheet = true
                            }
                            .buttonStyle(.bordered)
                            .disabled(filteredResults.isEmpty)
                            
                            Spacer()
                            
                            if !filteredResults.isEmpty {
                                Text("找到 \(filteredResults.count) 行匹配")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
                            
                            Text("请输入文本和关键词，然后点击开始筛选")
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
    
    private func startFiltering() {
        isFiltering = true
        
        // 模拟筛选过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            filteredResults = filterText()
            isFiltering = false
        }
    }
    
    private func filterText() -> [FilteredLine] {
        let lines = originalText.components(separatedBy: .newlines)
        let includeKeywordsList = includeKeywords.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var results: [FilteredLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            var shouldInclude = true
            var matchedKeywords: [String] = []
            
            // 检查包含关键词
            if !includeKeywordsList.isEmpty {
                shouldInclude = checkIncludeKeywords(trimmedLine, keywords: includeKeywordsList, logic: includeLogic)
                if shouldInclude {
                    matchedKeywords = getMatchedKeywords(trimmedLine, keywords: includeKeywordsList)
                }
            }
            
            if shouldInclude {
                results.append(FilteredLine(
                    lineNumber: index + 1,
                    content: line,
                    matchedKeywords: matchedKeywords
                ))
            }
        }
        
        return results
    }
    
    private func checkIncludeKeywords(_ line: String, keywords: [String], logic: FilterLogic) -> Bool {
        switch logic {
        case .and:
            // 与关系：必须包含所有关键词
            return keywords.allSatisfy { keyword in
                let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmedKeyword.isEmpty && line.localizedCaseInsensitiveContains(trimmedKeyword)
            }
        case .or:
            // 或关系：包含任一关键词即可
            return keywords.contains { keyword in
                let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmedKeyword.isEmpty && line.localizedCaseInsensitiveContains(trimmedKeyword)
            }
        }
    }
    
    private func getMatchedKeywords(_ line: String, keywords: [String]) -> [String] {
        return keywords.filter { keyword in
            let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedKeyword.isEmpty && line.localizedCaseInsensitiveContains(trimmedKeyword)
        }
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
            VStack(alignment: .leading, spacing: 4) {
                Text(highlightedText)
                    .font(.system(size: 13, design: .monospaced))
                    .textSelection(.enabled)
                
                if !line.matchedKeywords.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(line.matchedKeywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
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

// 逻辑选择卡片
struct LogicCard: View {
    let logic: TextFilterView.FilterLogic
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: logic.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : logic.color)
                
                VStack(spacing: 4) {
                    Text(logic.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(logic.description)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? logic.color : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? logic.color : Color(NSColor.separatorColor), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
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
