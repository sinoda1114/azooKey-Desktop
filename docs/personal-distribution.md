# 自分用あずきの配布

このブランチは、個別のコントリビュート用PRとは別に、普段使う機能をまとめるためのブランチです。

## 新しい機能を追加した後

機能を統合し、テストが通った状態で `Tools/personal-release.sh` を実行します。ローカルのApple Development署名でApple Silicon向けのアプリをビルドし、GitHub Releasesへ `azooKeyPersonal.zip` を公開します。

## 別のMacでの初回

Releaseから `azooKeyPersonal.zip` を展開し、展開された `release` フォルダ内の `personal-install-as-admin.sh` を実行します。管理者認証後、必要ならログアウトして再ログインし、入力ソースにあずきを追加します。

## 2回目以降の更新

展開した `personal-update.sh` を実行します。最新版をダウンロードし、管理者認証後に `/Library/Input Methods/azooKeyMac.app` を安全に入れ替えます。前の版は日時付きの `azooKeyMac.app.before-personal-update-*` として同じフォルダに残るため、問題があれば戻せます。古いバックアップは、動作確認後に整理してください。

Apple Development署名のため、初回はmacOSが開発元の確認を求める場合があります。これはこのMacのApple IDで署名した自分用配布物であり、公式リリースではありません。
