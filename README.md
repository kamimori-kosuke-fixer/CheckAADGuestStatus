# Information

Azure ADのゲストが参加したか否かを確認するPowerShellのFunctionです。

まだゲストが参加していない場合は、参加が完了するまで処理し続け、参加後に通知します。

指定したメールが存在しない場合や、対象のメールの所有者がゲスト以外（メンバー）の場合は処理が中断されます。

# Prep

- Windows10 PC
- SlackのWebhook URL作成
- AzureADのユーザー参照権限取得

# How to Use

0. 二つのPS1ファイルを同一ディレクトリにコピーして、同じディレクトリパスでPowerShellを起動してください。
0. `CheckAADGuestStatus_config.ps1`の各パラメーターをエディタ（メモ帳やVSCodeなど）で更新してください。
0. `CheckAADGuestStatus.ps1`を実行してください。
0. CheckAADGuestStatus と入力してEnterを押下します。
0. メールアドレスの入力が求められるので、参加状況を検索したいゲストユーザーのメールアドレスを入力します。
0. 入力された情報をもとにAzureADを検索、ユーザーステータスがAcceptedになったら通知が発行されます。
0. 終わりです


# FYI

- 細かい使い方は`get-help CheckAADGuestStatus -full`で確認してください。
- WebhookのURLやループ待機時間は引数でも設定できます。
（CheckAADGuestStatus [-mail] <string> [[-waitSecond] <string>] [[-uri] <string>]  [<CommonParameters>]）
