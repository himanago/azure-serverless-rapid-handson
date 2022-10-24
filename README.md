# Azure サーバーレスをササっと体験するハンズオン

## 概要
Bicep と GitHub Actions を使って Azure サーバーレステクノロジーを組み合わせた開発を高速で体験します。

手順に沿って作業すると、以下のテクノロジーを使用した簡易掲示板アプリがデプロイされます。

- Azure Static Web Apps
- Azure Functions
- Azure Cosmos DB
- Azure SignalR Service

環境も Gitpod 対応なので、ローカルの開発環境の準備は不要です。

Azure アカウント・サブスクリプションと GitHub アカウントを準備しておいてください。

※ 使用後はすぐにリソースグループを削除してください（課金が発生します）。

## 手順

### リポジトリの作成

本リポジトリをご自身の GitHub アカウントに、このテンプレートを使ったリポジトリを作成してください。

### Gitpod 起動

作成したリポジトリの URL を `https://gitpod.io/#` の後ろにつけ、アクセスしてください。

`https://gitpod.io/#https://github.com/<your account name>/<your repository name>`

起動には 10 分ほどかかります。

### コマンド実行

起動した Gitpod の画面で、以下のコマンドを順に実行します。

```
az upgrade

az bicep install

# Azure ログイン
az login --use-device-code

az account list \
   --refresh \
   --query "[].id" \
   --output table

az account set --subscription <your subscription id>

# リソースグループ名を決めます
group_name=<your resource group name>

# リソースグループを新規に作成する場合のみ実施
#az group create --name ${group_name} --location japaneast

# 使用するリソースグループを指定
az configure --defaults group=${group_name}

# 以下のページでランダムな文字列を生成し、<random>に置き換えます
# https://1password.com/jp/password-generator/
az deployment group create --name functions --template-file main.bicep \
  --parameters yourName=<your name in roman letters> \
  --parameters ramdom=<ramdom>

# Azure Functions リソース名の取得
az deployment group show \
  -g ${group_name} \
  -n functions \
  --query properties.outputs.functionAppName.value

# Functions のリソース名を埋めてから実行
cd functions
npm i
func azure functionapp publish <functionAppName> --build remote

```

### Static Web App の作成

フロントエンドの画面は Azure ポータルから作成します。

Azure ポータルから、Static Web Apps を作成してください。

- プランの種類: `Free`
- リージョン: `East Asia`
- デプロイの詳細
  - ソース: `GitHub`
  - アカウント: 自身のアカウント
- 組織: 自身のアカウントの組織
- リポジトリ: 自身が設定したリポジトリ名
- 分岐: `main`
- ビルドのプリセット: `Vue.js`
- アプリの場所: `/swa/client`
- API の場所: `/swa/api`
- 出力先: `dist`

作成できたら、Static Web App の構成＞アプリケーション設定に `COSMOSDB_CONNECTION_STRING` `SIGNALR_CONNECTION_STRING` を設定してください（Cosmos DB、SignalR Service のそれぞれの接続文字列です）。


## リソースの削除
動作確認ができたら、以下のコマンドでリソースグループごと削除します。

```
az group delete --name ${group_name}
```


## 参考
一部のコードは以下のリポジトリの内容を参考にしています。

https://github.com/mochan-tk/Handson-LINE-Bot-Azure-template