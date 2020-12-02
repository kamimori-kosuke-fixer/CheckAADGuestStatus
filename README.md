# Information

Azure ADのゲストが参加したか否かを確認するPowerShellのFunctionです。

まだゲストが参加していない場合は、参加が完了するまで処理し続け、参加後に通知します。

指定したメールが存在しない場合や、対象のメールの所有者がゲスト以外（メンバー）の場合は処理が中断されます。

# Prep

- Windows10 PC
- SlackのWebhook URL作成（https://slack.com/intl/ja-jp/help/articles/115005265063）
- AzureADのユーザー参照権限取得

# How to Use

1. 二つのPS1ファイルをダウンロードして、任意のフォルダに配置してください
0. `CheckAADGuestStatus_config.ps1`の各パラメーターをエディタ（メモ帳やVSCodeなど）で更新してください。**※補足1**
0. PS1をダウンロードした同じフォルダでPowerShellを起動してください。**※補足2**
0. PowerShellの画面上で`.\CheckAADGuestStatus.ps1`と入力してEnterを押下してください。
0. 「CheckAADGuestStatusのコマンドが実行できるようになりました。」のメッセージが表示されることを確認してください。
0. PowerShellの画面上で`CheckAADGuestStatus`と入力してEnterを押下します。
0. メールアドレスの入力が求められるので、参加状況を検索したいゲストユーザーのメールアドレスを入力します。
0. 結果を確認します。（Slackの通知またはPowerShell画面を確認）
0. 終わり

## 補足1
- 必須
 > $Webhook_default
 
  事前準備で用意したSlackアプリのWebhook URLを登録します。
 
 EX）$Webhook_default = "https://hooks.slack.com/services/[tenantID]/.../...."
 
 ※上記URLは利用できません

- 任意
 > $waitSecond_default
 
 ループの待機時間を設定します。デフォルトは60秒です。
 
 > $image
 
 Slack通知に表示するイメージを選択します。任意項目のため編集は省略しても良いです。
 
 入力する場合はファイルの直接リンクを指定します。

## 補足2
- ファイルを保存したフォルダを開き、ファイルがない場所でShift＋右クリック
- 「PowerShellウィンドウをここで開く」をクリック

# FYI

- 細かい使い方は`get-help CheckAADGuestStatus -full`で確認してください。
- WebhookのURLやループ待機時間は引数でも設定できます。

EX）CheckAADGuestStatus [-mail] <string> [[-waitSecond] <string>] [[-uri] <string>]
