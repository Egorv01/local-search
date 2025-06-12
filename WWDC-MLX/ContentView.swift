//
//  ContentView.swift
//  WWDC-MLX
//
//  Created by MollyCantillon on 6/11/25.
//

import SwiftUI
import Foundation
import MLX
import MLXEmbedders
import Hub
import SwiftSoup
import WebKit
internal import Tokenizers

// Simple in-memory search index
class InMemoryIndex<Item> {
    private var items: [Item]
    private let embeddingFor: (Item) -> [Float]
    
    init(items: [Item], embeddingFor: @escaping (Item) -> [Float]) {
        self.items = items
        self.embeddingFor = embeddingFor
    }
    
    func search(query: String, embeddingForQuery: () -> [Float], topK: Int) async -> [(item: Item, similarity: Float)] {
        print("Searching for query: \(query) with topK: \(topK)")
        let queryEmbedding = embeddingForQuery()
        
        return items.map { item in
            let similarity = cosineSimilarity(queryEmbedding, embeddingFor(item))
            return (item: item, similarity: similarity)
        }
        .sorted { $0.similarity > $1.similarity }
        .prefix(topK)
        .map { $0 }
    }
    
    private func cosineSimilarity(_ vec1: [Float], _ vec2: [Float]) -> Float {
        guard vec1.count == vec2.count && !vec1.isEmpty else { return 0.0 }
        let dotProduct = zip(vec1, vec2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vec1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vec2.map { $0 * $0 }.reduce(0, +))
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        return dotProduct / (magnitude1 * magnitude2)
    }
}

class Embedder {
    private let hubApi = HubApi(useOfflineMode: false)
    private var modelContainer: ModelContainer?
    
    private func getModel() async throws -> ModelContainer {
        if let modelContainer = modelContainer { return modelContainer }
        let config: ModelConfiguration = .bge_small
        let modelContainer = try await MLXEmbedders.loadModelContainer(hub: hubApi, configuration: config)
        self.modelContainer = modelContainer
        return modelContainer
    }
    
    func createEmbedding(for text: String) async throws -> [Float] {
        print("Creating embedding for text: \(text.prefix(100))")
        let model = try await getModel()
        return await model.perform { model, tokenizer, pooling -> [Float] in
            let encoded = tokenizer.encode(text: text, addSpecialTokens: true)
            let eosId = tokenizer.eosTokenId ?? 0
            let padded = encoded + Array(repeating: eosId, count: max(0, 16 - encoded.count))
            let input = stacked([MLXArray(padded)])
            let mask = (input .!= eosId)
            let tokenTypes = MLXArray.zeros(like: input)
            let modelOut = model(input, positionIds: nil, tokenTypeIds: tokenTypes, attentionMask: mask)
            let pooled = pooling(modelOut, normalize: true, applyLayerNorm: true)
            pooled.eval()
            return pooled.asArray(Float.self)
        }
    }
    
    func createEmbeddings(for texts: [String], batchSize: Int = 3) async throws -> [[Float]] {
        print("Creating embeddings for \(texts.count) texts with batch size \(batchSize)")
        var results: [[Float]] = []
        
        for i in stride(from: 0, to: texts.count, by: batchSize) {
            let batch = Array(texts[i..<min(i + batchSize, texts.count)])
            print("Processing batch \(i/batchSize + 1) of \(texts.count/batchSize + 1)")
            
            for text in batch {
                if let embedding = try? await createEmbedding(for: text) {
                    results.append(embedding)
                }
            }
            
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        return results
    }
}

struct Doc: Identifiable {
    let id = UUID()
    let text: String
    var embedding: [Float]?
    let source: String
}

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var docs: [Doc] = []
    @State private var results: [(doc: Doc, similarity: Float)] = []
    @State private var isLoading: Bool = true
    @State private var index: InMemoryIndex<Doc>?
    
    private let embedder = Embedder()
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, onSearchButtonClicked: search)
            if isLoading {
                ProgressView("Indexing...").padding()
            } else {
                List(results, id: \ .doc.id) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.doc.text).font(.body).lineLimit(3)
                        HStack {
                            Text("Similarity: \(String(format: "%.1f", result.similarity * 100))%")
                                .font(.caption2).foregroundColor(.blue)
                            Spacer()
                            if let url = URL(string: result.doc.source) {
                                Link("Source", destination: url)
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }.padding(.vertical, 2)
                }
            }
        }
        .task { await loadDocuments() }
    }
    
    func loadDocuments() async {
        docs = await crawlWWDCDocumentation()
        let texts = docs.map { $0.text }
        if let embeddings = try? await embedder.createEmbeddings(for: texts, batchSize: 3) {
            print("Created \(embeddings.count) embeddings")
            for (index, doc) in docs.enumerated() {
                if index < embeddings.count {
                    docs[index].embedding = embeddings[index]
                }
            }
        }
        let validDocs = docs.filter { $0.embedding != nil }
        if !validDocs.isEmpty {
            index = InMemoryIndex(items: validDocs, embeddingFor: { $0.embedding! })
        }
        results = docs.map { (doc: $0, similarity: 1.0) }
        isLoading = false
    }
    
    private func crawlWWDCDocumentation() async -> [Doc] {
        let startingUrls = ["https://developer.apple.com/documentation/updates/wwdc2025/"]
        var allDocs: [Doc] = []
        let processedUrls = Set<String>()
        for startUrl in startingUrls {
            let docs = await crawlPage(url: startUrl, processedUrls: processedUrls, maxDepth: 2)
            allDocs.append(contentsOf: docs)
        }
        return allDocs
    }
    
    private func crawlPage(url: String, processedUrls: Set<String>, maxDepth: Int) async -> [Doc] {
        guard maxDepth > 0, !processedUrls.contains(url) else { return [] }
        var processedUrls = processedUrls
        processedUrls.insert(url)
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard let pageURL = URL(string: url), let html = await fetchWithWebView(url: pageURL) else { return [] }
        var docs: [Doc] = []
        do {
            let document = try SwiftSoup.parseBodyFragment(html)
            docs.append(contentsOf: extractContentFromPage(document: document, url: url))
            let links = try document.select("a[href]")
            var foundLinks: [String] = []
            for link in links {
                let href = try link.attr("href")
                let fullUrl: String
                if href.starts(with: "/") {
                    fullUrl = "https://developer.apple.com" + href
                } else if href.starts(with: "https://developer.apple.com") {
                    fullUrl = href
                } else { continue }

                // Skip all videos
                if fullUrl.contains("/videos") || fullUrl.contains("/video/") || fullUrl.contains(".mp4") || fullUrl.contains(".mov") || fullUrl.contains("media/") { continue }

                // Only include documentation links
                if fullUrl.contains("/documentation/") || fullUrl.contains("topics") || fullUrl.contains("/wwdc2025/") {
                    foundLinks.append(fullUrl)
                }
            }
            for linkUrl in foundLinks {
                let subDocs = await crawlPage(url: linkUrl, processedUrls: processedUrls, maxDepth: maxDepth - 1)
                docs.append(contentsOf: subDocs)
                if docs.count > 200 && maxDepth <= 2 { break }
            }
        } catch { return [] }
        return docs
    }

    private func fetchWithWebView(url: URL) async -> String? {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        defer { webView.navigationDelegate = nil }
        do {
            let request = URLRequest(url: url, timeoutInterval: 15)
            _ = try await webView.load(request)
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            if let result = try? await webView.evaluateJavaScript("document.body.innerHTML") as? String,
               !result.isEmpty, result.count > 100 {
                return result
            }

            if let fallback = try? await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String,
               !fallback.isEmpty {
                return fallback
            }
            
            return nil
        } catch { return nil }
    }
    
    private func extractContentFromPage(document: Document, url: String) -> [Doc] {
        var docs: [Doc] = []
        guard let links = try? document.select("a[href]") else { return docs }
        for link in links {
            let href = (try? link.attr("href")) ?? ""
            let text = (try? link.text().trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
            guard !text.isEmpty else { continue }
            let fullUrl: String
            if href.starts(with: "/documentation/") {
                fullUrl = "https://developer.apple.com" + href
            } else if href.starts(with: "https://developer.apple.com/documentation/") {
                fullUrl = href
            } else { continue }
            docs.append(Doc(text: text, source: fullUrl))
        }
        var seen = Set<String>()
        return docs.filter { doc in
            let normalized = doc.text.lowercased()
            if seen.contains(normalized) { return false }
            seen.insert(normalized)
            return true
        }
    }
    
    func search(_ text: String) {
        if text.isEmpty {
            results = docs.map { (doc: $0, similarity: 1.0) }
            return
        }
        guard let index = index else {
            results = []
            return
        }
        Task {
            if let queryEmbedding = try? await embedder.createEmbedding(for: text) {
                let found = await index.search(
                    query: text,
                    embeddingForQuery: { queryEmbedding },
                    topK: 20
                )
                
                await MainActor.run {
                    results = found.map { (doc: $0.item, similarity: $0.similarity) }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: (String) -> Void
    var body: some View {
        HStack {
            TextField("Search WWDC 2025 docs...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit { onSearchButtonClicked(text) }
            Button("Search") { onSearchButtonClicked(text) }
        }.padding()
    }
}

#Preview {
    ContentView()
}
