import Foundation

/// カタカナで入力した外来語から、対応する英単語の綴りを候補に追加する。
///
/// 機械的なローマ字化ではなく、一般的な英語表記だけを明示的に登録する。
enum KatakanaEnglishCandidates {
    private static let primaryWords: [String: String] = [
        // 日常で使う物・場所
        "ベッド": "bed",
        "ボトル": "bottle",
        "カメラ": "camera",
        "カード": "card",
        "コーヒー": "coffee",
        "ドア": "door",
        "ドレス": "dress",
        "エレベーター": "elevator",
        "フード": "food",
        "ホテル": "hotel",
        "アイスクリーム": "ice cream",
        "ジャケット": "jacket",
        "キッチン": "kitchen",
        "ランチ": "lunch",
        "マップ": "map",
        "メニュー": "menu",
        "ミラー": "mirror",
        "オフィス": "office",
        "パスポート": "passport",
        "ペン": "pen",
        "ピザ": "pizza",
        "レストラン": "restaurant",
        "シャツ": "shirt",
        "ショップ": "shop",
        "ソファ": "sofa",
        "スーツ": "suit",
        "タクシー": "taxi",
        "チケット": "ticket",
        "トイレ": "toilet",
        "トレイン": "train",
        "バス": "bus",
        "ウォーター": "water",
        "ウィンドウ": "window",

        // デジタル作業
        "アクセス": "access",
        "アカウント": "account",
        "アプリ": "app",
        "アップデート": "update",
        "アップロード": "upload",
        "ブラウザ": "browser",
        "クリック": "click",
        "コード": "code",
        "コンテンツ": "content",
        "データ": "data",
        "デバッグ": "debug",
        "デバイス": "device",
        "ディスプレイ": "display",
        "ドキュメント": "document",
        "ダウンロード": "download",
        "エラー": "error",
        "ファイル": "file",
        "フォルダ": "folder",
        "インストール": "install",
        "インターフェース": "interface",
        "インターネット": "internet",
        "キーボード": "keyboard",
        "リンク": "link",
        "ログイン": "login",
        "マウス": "mouse",
        "ネットワーク": "network",
        "オプション": "option",
        "パスワード": "password",
        "プライバシー": "privacy",
        "プログラム": "program",
        "プロジェクト": "project",
        "リリース": "release",
        "セキュリティ": "security",
        "サーバー": "server",
        "サービス": "service",
        "ソフトウェア": "software",
        "スマートフォン": "smartphone",
        "システム": "system",
        "タブ": "tab",
        "テキスト": "text",
        "ユーザー": "user",
        "バージョン": "version",
        "ウェブ": "web",
        "ウェブサイト": "website",

        // 開発で使う概念・操作
        "アーキテクチャ": "architecture",
        "バックエンド": "backend",
        "フロントエンド": "frontend",
        "フルスタック": "full stack",
        "フレームワーク": "framework",
        "ライブラリ": "library",
        "ランタイム": "runtime",
        "リポジトリ": "repository",
        "コミット": "commit",
        "ブランチ": "branch",
        "マージ": "merge",
        "プルリクエスト": "pull request",
        "イシュー": "issue",
        "レビュー": "review",
        "デプロイ": "deploy",
        "デプロイメント": "deployment",
        "ステージング": "staging",
        "プロダクション": "production",
        "エンドポイント": "endpoint",
        "リクエスト": "request",
        "ペイロード": "payload",
        "スキーマ": "schema",
        "データベース": "database",
        "キャッシュ": "cache",
        "キュー": "queue",
        "ウェブフック": "webhook",
        "パイプライン": "pipeline",
        "ワークフロー": "workflow",
        "コンテナ": "container",
        "サーバーレス": "serverless",
        "クラウド": "cloud",
        "インフラ": "infrastructure",
        "モニタリング": "monitoring",
        "ロギング": "logging",
        "メトリクス": "metrics",
        "アラート": "alert",
        "インシデント": "incident",
        "オーセンティケーション": "authentication",
        "オーソライゼーション": "authorization",
        "トークン": "token",
        "クッキー": "cookie",
        "セッション": "session",
        "コンプライアンス": "compliance",
        "バルネラビリティ": "vulnerability",
        "デペンデンシー": "dependency",
        "パッケージ": "package",
        "モジュール": "module",
        "プラグイン": "plugin",
        "エクステンション": "extension",
        "テンプレート": "template",
        "スニペット": "snippet",

        // 技術略語・AI用語
        "エーピーアイ": "API",
        "エスディーケー": "SDK",
        "シーエルアイ": "CLI",
        "ユーアイ": "UI",
        "ユーエックス": "UX",
        "ユーアールエル": "URL",
        "ジェイソン": "JSON",
        "ワイエーエムエル": "YAML",
        "トムル": "TOML",
        "エスキューエル": "SQL",
        "ノーエスキューエル": "NoSQL",
        "シーアイ": "CI",
        "シーディー": "CD",
        "アイアム": "IAM",
        "エスエスオー": "SSO",
        "オーオース": "OAuth",
        "エーアイ": "AI",
        "ジーピーティー": "GPT",
        "エルエルエム": "LLM",
        "アールエージー": "RAG",
        "エムシーピー": "MCP",

        // よく使う開発サービス・ツール
        "エーダブリューエス": "AWS",
        "アジュール": "Azure",
        "ジーシーピー": "GCP",
        "グーグルクラウド": "Google Cloud",
        "ドッカー": "Docker",
        "クバネティス": "Kubernetes",
        "テラフォーム": "Terraform",
        "ギット": "Git",
        "ギットハブ": "GitHub",
        "ギットラボ": "GitLab",
        "ビットバケット": "Bitbucket",
        "ジェイラ": "Jira",
        "コンフルエンス": "Confluence",
        "スラック": "Slack",
        "ノーション": "Notion",
        "フィグマ": "Figma",
        "リニア": "Linear",
        "セントリー": "Sentry",
        "ベーセル": "Vercel",
        "ネットリファイ": "Netlify",
        "クラウドフレア": "Cloudflare",
        "スーパーベース": "Supabase",
        "ファイアベース": "Firebase",
        "ポストマン": "Postman",
        "ストライプ": "Stripe",
        "データドッグ": "Datadog",
        "ニューレリック": "New Relic",
        "スノーフレーク": "Snowflake",
        "ミクスパネル": "Mixpanel",
        "アンプリチュード": "Amplitude",
        "オープンエーアイ": "OpenAI",
        "アンソロピック": "Anthropic",
        "チャットジーピーティー": "ChatGPT",
        "コーデックス": "Codex",
        "クロード": "Claude",
        "ジェミニ": "Gemini",
        "コパイロット": "Copilot",
        "パープレキシティ": "Perplexity",

        // 仕事・コミュニケーション
        "アジェンダ": "agenda",
        "アポイントメント": "appointment",
        "ミーティング": "meeting",
        "メッセージ": "message",
        "メール": "email",
        "プレゼンテーション": "presentation",
        "レポート": "report",
        "スケジュール": "schedule",
        "タスク": "task",
        "チーム": "team",

        // よく使う一般語
        "アイデア": "idea",
        "アイコン": "icon",
        "イメージ": "image",
        "イベント": "event",
        "ゲーム": "game",
        "グループ": "group",
        "キーワード": "keyword",
        "ラベル": "label",
        "レイアウト": "layout",
        "リスト": "list",
        "モデル": "model",
        "ニュース": "news",
        "ページ": "page",
        "パターン": "pattern",
        "プラン": "plan",
        "ポイント": "point",
        "ポリシー": "policy",
        "レスポンス": "response",
        "ルール": "rule",
        "サンプル": "sample",
        "サイズ": "size",
        "スタイル": "style",
        "タイトル": "title",
        "トピック": "topic",
        "タイプ": "type",
        "ワーク": "work"
    ]

    /// 英語にそのまま直すと意味が変わる和製英語を、一般的な英語表現で補う。
    private static let correctedWords: [String: [String]] = [
        "コンセント": ["power outlet", "electrical outlet"]
    ]

    /// JMdict の一般語から、カタカナの名詞と英語候補を読み込む。
    ///
    /// 個人用機能のため、ネットワークには接続せずアプリに同梱した辞書だけを使う。
    private static let importedWords: [String: [String]] = {
        guard let url = Bundle.module.url(forResource: "katakana-english-jmdict", withExtension: "tsv"),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            return [:]
        }

        var words: [String: [String]] = [:]
        for line in content.split(whereSeparator: \.isNewline) where !line.hasPrefix("#") {
            let columns = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard columns.count == 2 else {
                continue
            }

            let reading = String(columns[0])
            let word = String(columns[1])
            guard Self.isValidReading(reading), Self.isValidWord(word) else {
                continue
            }

            var candidates = words[reading, default: []]
            guard !candidates.contains(word), candidates.count < 3 else {
                continue
            }
            candidates.append(word)
            words[reading] = candidates
        }
        return words
    }()

    static func variants(for reading: String) -> [String] {
        var words = Self.correctedWords[reading, default: []]
        if let primaryWord = Self.primaryWords[reading] {
            words.append(primaryWord)
        }
        words.append(contentsOf: Self.importedWords[reading, default: []])

        var seen = Set<String>()
        return words
            .filter { seen.insert($0).inserted }
            .flatMap { word in
                let title = word.prefix(1).uppercased() + word.dropFirst()
                return title == word ? [word] : [word, title]
            }
    }

    private static func isValidReading(_ reading: String) -> Bool {
        !reading.isEmpty && reading.unicodeScalars.allSatisfy { scalar in
            ("ァ"..."ヶ").contains(Character(String(scalar))) || scalar == "ー"
        }
    }

    private static func isValidWord(_ word: String) -> Bool {
        !word.isEmpty && word.count <= 40 && word.unicodeScalars.allSatisfy { scalar in
            ("a"..."z").contains(Character(String(scalar))) || scalar == " " || scalar == "-"
        }
    }
}
