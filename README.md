# Information

Azure ADのゲストが参加したか否かを確認するPowerShellのFunctionです。

まだゲストが参加していない場合は、参加が完了するまで処理し続け、参加後に通知します。

指定したメールが存在しない場合や、対象のメールの所有者がゲスト以外（メンバー）の場合は処理が中断されます。

## Prep

- Windows10 PC
- SlackのWebhook URL作成（例えば[Incoming-Webhook](https://slack.com/services/new/incoming-webhook)など）※[参考Qiita](https://qiita.com/vmmhypervisor/items/18c99624a84df8b31008)
- AzureADのユーザー参照権限取得

## How to Use

1. 二つのPS1ファイルをダウンロードして、任意のフォルダに配置してください [**※補足1**](#補足1)
![ファイルのダウンロード](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/blob/image/file%20download.png)
1. `CheckAADGuestStatus_config.ps1`の各パラメーターをエディタ（メモ帳やVSCodeなど）で編集します。 [**※補足2**](#補足2)
1. PowerShell(管理者権限)を起動し、PS1をダウンロードした同じフォルダに移動します。[**※補足3**](#補足3)
1. PowerShellの画面上で`.\CheckAADGuestStatus.ps1`と入力してEnterを押下します。
1. 「CheckAADGuestStatusのコマンドが実行できるようになりました。」のメッセージが表示されることを確認します。
![Functionのインストール](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/blob/image/installFunction.png)
1. PowerShellの画面上で`CheckAADGuestStatus`と入力してEnterを押下します。 [**※補足4**](#補足4)
1. メールアドレスの入力が求められるため、参加状況を確認したいゲストユーザーのメールアドレスを入力します。
![Functionの実行](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/blob/image/StartFunction.png)
1. ユーザー認証が求められるため、招待者（または招待者が所属する組織アカウント）のメールアドレスで認証を行います。
![アカウントサインイン](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/blob/image/AccountSignIn.png)
1. 結果を確認します。（Slackの通知またはPowerShell画面を確認）
1. 終わり

### 補足1

ファイルのダウンロードは例えばこのように実施してください。右クリ保存でも〇です。

1. [本ページ](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/)の緑色のCodeボタンをクリック
1. Download ZIPをクリック
1. ZIPを解凍

### 補足2

- 必須

 > $Webhook_default

  事前準備で用意したSlackアプリのWebhook URLを登録します。

 EX）$Webhook_default = "https://hooks.slack.com/services/xxxx/yyyy/zzzz"

 ※上記URLは利用できません

- 任意

 > $waitSecond_default

 ループの待機時間を設定します。デフォルトは60秒です。

 > $image

 Slack通知に表示するイメージを選択します。任意項目のため編集は省略しても良いです。

 入力する場合はファイルの直接リンクを指定します。

### 補足3

- 管理者権限でPowerShellを開く

![PowreShellAdminOpen](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/blob/image/Open-PowerShell-with-Administrator-Role.gif)

- ファイルを保存したフォルダに移動

※画像は「C:\temp\CheckAADGuestStatus-main」にファイルを配置した場合の例

![ChangeDirectory](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/blob/image/ChangeDirectory.png)

### 補足4

UnauthorizedAccessが発生する場合はPS1ファイルのプロパティを修正してください。

![UnauthorizedAccess](https://github.com/kamimori-kosuke-fixer/CheckAADGuestStatus/blob/image/UnauthorizedAccess.png)

### FYI

- 細かい使い方は`get-help CheckAADGuestStatus -full`で確認してください。
- WebhookのURLやループ待機時間は引数でも設定できます。
- Webhookの作り方は[Slack公式](https://slack.com/intl/ja-jp/help/articles/115005265063)を参照するのも良いです。
- PS1ファイルを実行したPowerShellプロセスのみで動きます。コマンドを利用する機会が多い人は[この記事](https://www.vwnet.jp/Windows/PowerShell/2016100401/UseFunctionInPsPrompt.htm#profile)などを参考に設定してみてください。
