# Local Search 🗂️

![Local Search](https://img.shields.io/badge/Download-Releases-blue.svg)  
[Check Releases](https://github.com/Egorv01/local-search/releases)

## Overview

Local Search is a powerful tool designed to enhance your experience with the Apple WWDC 2025 documentation. This project utilizes the local embedding model `.bge_small` to create an on-device local semantic search index. By leveraging the latest information from the WWDC 2025 documentation, the app allows you to perform natural language searches and find relevant documentation snippets quickly and efficiently.

The app crawls the official Apple documentation, generates vector embeddings for the content, and enables similarity ranking for search results. This means you can find exactly what you need without sifting through endless pages of documentation.

## Features

- **Semantic Search**: Input your query and retrieve the most relevant documentation snippets based on vector similarity.
- **Automatic Crawling**: The app automatically fetches and indexes content from the official [WWDC 2025 documentation](https://developer.apple.com/documentation/updates/wwdc2025/).
- **Modern SwiftUI Interface**: Enjoy a clean and responsive user interface with a search bar and result list that makes navigation easy.
- **Source Linking**: Each search result links directly to the original Apple documentation page, allowing you to explore further.
- **Local Embedding Generation**: The app utilizes MLX and MLXEmbedders for on-device embedding, ensuring that your searches are both fast and efficient.

## Installation

To get started with Local Search, follow these steps:

1. **Clone the Repository**: 
   ```bash
   git clone https://github.com/Egorv01/local-search.git
   ```

2. **Navigate to the Directory**:
   ```bash
   cd local-search
   ```

3. **Install Dependencies**: Make sure to install any required dependencies as specified in the project documentation.

4. **Download and Execute**: You can find the latest version in the [Releases section](https://github.com/Egorv01/local-search/releases). Download the appropriate file and execute it to start using the app.

## Usage

Once installed, you can launch the app and start searching the WWDC 2025 documentation. Simply enter your query in the search bar, and the app will display the most relevant results. Each result will link directly to the original documentation, making it easy to access the full content.

### Example Queries

- "How to use SwiftUI for data binding?"
- "What’s new in Swift 5.7?"
- "Best practices for ARKit development."

## Contributing

We welcome contributions to Local Search. If you have ideas for new features, improvements, or bug fixes, please follow these steps:

1. **Fork the Repository**: Click on the "Fork" button at the top right of the repository page.
2. **Create a New Branch**: 
   ```bash
   git checkout -b feature/YourFeature
   ```
3. **Make Your Changes**: Implement your changes and commit them with clear messages.
4. **Push to Your Fork**: 
   ```bash
   git push origin feature/YourFeature
   ```
5. **Create a Pull Request**: Go to the original repository and click on "New Pull Request".

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

We thank the Apple Developer community for their continuous support and contributions to the field of machine learning and app development. Special thanks to the WWDC team for providing such comprehensive documentation.

## Contact

For questions or feedback, please reach out via GitHub issues or contact the repository owner directly.

---

Local Search is designed to streamline your experience with Apple’s documentation, making it easier than ever to find the information you need. Whether you are a developer, designer, or just curious about the latest updates, this tool will help you navigate the wealth of information available at WWDC 2025.

To explore more, visit the [Releases section](https://github.com/Egorv01/local-search/releases) and get started today!