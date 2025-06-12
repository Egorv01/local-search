# WWDC-MLX

## Overview

Code Walkthrough for `Real-World Applications of MLX` in WWDC OMT 2025. We use the local embedding model `.bge_small` to create an on-device local semantic search index, pulling in from the latest Apple WWDC 2025 documentation using local embeddings and a fast in-memory search index. The app crawls the official Apple documentation, generates vector embeddings for the content, and enables natural language search with similarity ranking.

## Features

- **Semantic Search:** Enter a query and find the most relevant documentation snippets using vector similarity.
- **Automatic Crawling:** The app fetches and indexes content from the official [WWDC 2025 documentation](https://developer.apple.com/documentation/updates/wwdc2025/).
- **Modern SwiftUI Interface:** Clean, responsive UI with search bar and result list.
- **Source Linking:** Each result links directly to the original Apple documentation page.
- **Local Embedding Generation:** Uses MLX and MLXEmbedders for on-device embedding computation.

## Dependencies

This project uses Swift Package Manager and includes the following dependencies (see `Package.resolved` for exact versions):

- [MLX Swift](https://github.com/ml-explore/mlx-swift)
- [MLX Swift Examples](https://github.com/ml-explore/mlx-swift-examples/)
- [Swift Transformers](https://github.com/huggingface/swift-transformers)
- [SwiftSoup](https://github.com/scinfu/SwiftSoup)

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone https://github.com/mcantillon21/local-search.git
   cd WWDC-MLX
   ```

2. **Open in Xcode:**
   - Open `WWDC-MLX.xcodeproj` in Xcode (version 15 or later recommended).

3. **Build and Run:**
   - Select the `WWDC-MLX` scheme and run the app on your Mac.

4. **Search:**
   - Wait for the initial indexing to complete, then enter your search query in the search bar.

## Notes

- The app requires network access to crawl and fetch documentation. But once indexed, works without internet.
- Note: Embedding generation and crawling may take some time on first launch.
- This is just an unoptimized demo, but you could replicate this process for any website, any of your data. 