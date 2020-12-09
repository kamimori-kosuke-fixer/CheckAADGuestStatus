<#
.SYNOPSIS
AAD Guest User Status Check

.DESCRIPTION
Check the status until the guest user joins.

.EXAMPLE
CheckAADGuestStatus -mail test@hogehoge.come -waitSecond 600
Perform a test@hogehoge.come status check.
Repeat the check every 10 minutes(600 seconds) if guest have not yet joined.

.PARAMETER mail
Enter the email address you used for the guest invite.

.PARAMETER webhook
Enter WebHook URI that will return a response.

.PARAMETER waitSecond
Guest status monitoring span
<CommonParameters> is not support.

.LINK
None
#>

#include config
.".\CheckAADGuestStatus_config.ps1"
Write-Host "外部ファイル[CheckAADGuestStatus_config.ps1]を読み込みました`r`n"

function global:CheckAADGuestStatus{
    Param(
        [parameter(mandatory,HelpMessage="監視対象のユーザーのメールアドレスを入力してください")][ValidateNotNullOrEmpty()][string]$mail,
        [parameter(HelpMessage="監視を繰り返すタイミング（秒）を指定してください")][ValidateNotNullOrEmpty()][string]$waitSecond,
        [parameter(HelpMessage="結果を返すWebHookを指定してください")][ValidateNotNullOrEmpty()][string]$webhook
    )
    $enc = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
    $message = "確認依頼のあったゲストユーザーが参加されました！" #出力コメント
    $errorFlag = 0
    
    #ループのタイミング（引数指定が無ければデフォルト値を設定）
    if([string]::IsNullOrEmpty($waitSecond)){
        if([string]::IsNullOrEmpty($waitSecond_default)){
            Write-Host "waitSecond_default is null or empty. please check config file.`r`nwaitSecond_default is required."
            Break
        }else{
            $waitSecond = $waitSecond_default 
        }
    }
    if(-not([int]::TryParse($waitSecond,[ref]$null))){
        Write-Host "waitSecond is not Integer. Please input Integer format.`r`nInput Data:"$waitSecond
        Break
    }

    if([string]::IsNullOrEmpty($webhook)){
        if([string]::IsNullOrEmpty($Webhook_default)){
            Write-Host "Webhook_default is null or empty. please check config file.`r`nWebhook_default is required."
            Break
        }else{
            $webhook = $Webhook_default
        }
    }


    #接続
    Write-Host AzureADモジュールのインストール状況を確認します。
    if((Get-Module -ListAvailable -Name AzureAD).count -ne 1){
        Write-Host AzureADのモジュールをインストールします。
        Install-Module -Name AzureAD -force
        Get-Module -ListAvailable -Name AzureAD
    }else{
        Write-Host AzureADモジュールはすでにインストールされています。
    }
    try{
        $user=Get-AzureADUser -Filter "mail eq '$mail'" -ErrorAction Stop
    }catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
        Write-Host "You're not connected." 
        try{
            Connect-AzureAD
            $user=Get-AzureADUser -Filter "mail eq '$mail'" -ErrorAction Stop
        }catch{
            Write-Host Connected Error.
            Break
        }
    }catch{
        Write-Host Anonymous Error...
        Break
    }

    #ユーザー情報取得
    switch($user.count){
        {$_ -eq 0}{
            $message="ユーザーが見つかりませんでした。メールアドレスを見直してください`r`n"
            $errorFlag = 1
            break
        }
        {$_ -gt 1}{
            $message=$_+"件のユーザーが見つかりました。対象が1件になるようメールアドレスを見直してください。`r`n"
            $message+=$user|ft DisplayName,mail,UserType
            $errorFlag = 1
            break
        }
        {$_ -eq 1}{
            "下記ユーザーの所属状況をチェックします"
            $user|ft DisplayName,mail,UserType
            if($user.UserType -ne "Guest"){
                $message="対象ユーザーはゲストではありません`r`n"
                $errorFlag = 1
                break
            }
            if($user.UserState -eq "Accepted"){
                $message="対象のゲストユーザーは既に参加済みです`r`n"
                $errorFlag = 1
                break
            }
        }
        default{
            $message="ユーザー検索（Get-AzureADUser）にてイレギュラーが発生しています`r`n"
            $errorFlag = 1
            break
        }
    }

    if($errorFlag -eq 0){
        while(1) { 
            $user=Get-AzureADUser -Filter "mail eq '$mail'"
            switch($user.UserState){
                {$_ -eq "PendingAcceptance"}{
                    Write-Host (get-date)":`tゲストはまだ参加していません。中断する場合はCtrl＋Cを押下してください。"
                }
                {$_ -eq "Accepted"}{
                    $payload = @{
                            "type" = "section";
                            "block_id" = "section01";
                            "text" = @{
                                "type" = "mrkdwn";
                                "text" = $enc.GetString([System.Text.Encoding]::UTF8.GetBytes($message));
                            }
                            "accessory" = @{
                                "type" = "image";
                                "image_url" = $image_default;
                                "alt_text" = "Join image"
                            }
                        },
                        @{
                            "type" = "section";
                            "block_id" = "section02";
                            "text" =
                            @{
                                "type" = "mrkdwn";
                                "text" = " USER INFORMATION:\n Name:"+$user.DisplayName+"\n Mail:"+$user.Mail
                            }
                        }
                    }
                    try{
                        Invoke-RestMethod -Uri $webhook -Method POST -Body (ConvertTo-Json $payload -Depth 4).Replace('\\n','\n')
                    }catch{
                        Write-host "Webhookへの送信が失敗しました。Webhookに設定された値が間違っているか、対象URLが存在しません。`r`n`r`n"
                    }
                    
                    Write-Host (get-date)":`tゲストユーザーのステータスがAcceptedに更新されました。ゲストとのやり取りが開始できます。"
                    break
                }
                default{
                    Write-Host (get-date)":`tユーザーステータスチェックにてイレギュラーが発生しています`r`n"
                    break
                }
            }
            # 待機
            Start-Sleep -Seconds $waitsecond
        }
    }else{
        $message+="検索条件は「"+$mail+"」です`r`n"
        $user =(Get-AzureADUser | `
        ?{
            $_.usertype -eq "Guest" `
            -and $_.userstate -eq "PendingAcceptance" `
            -and $_.RefreshTokensValidFromDateTime -ge (Get-Date).AddMonths(-3) 
        })
        switch($user.count){
            {$_ -ge 1}{
                $message+="直近でにInviteされたゲストのなかで、未参加のゲストはこちらです`r`n"

                $message+="-----`r`nMail`tUsertype`r`n"
                $user|foreach{
                    $message+= $_.mail+"`t"
                    $message+= $_.usertype+"`r`n"
                }
                $message+="-----`r`n"
            }default{
                $message+="直近でにInviteされたゲストのなかで、未参加のゲストはいませんでした`r`n"
            }
        }
        $payload = 
        @{
            text = $enc.GetString([System.Text.Encoding]::UTF8.GetBytes($message));
        }
        try{
            Invoke-RestMethod -Uri $webhook -Method POST -Body (ConvertTo-Json $payload -Depth 4).Replace('\\n','\n')
        }catch{
            Write-host "Webhookへの送信が失敗しました。Webhookに設定された値が間違っているか、対象URLが存在しません。`r`n`r`n"
        }
        Write-Host (get-date)":`tゲストユーザーの検索に失敗しました。詳細は下記メッセージを確認してください`r`n"$message
        Break
    }
}
Write-Host "CheckAADGuestStatusのコマンドが実行できるようになりました。`r`n`r`n使い方の詳細を確認する場合は下記コマンドを実施してください`r`nget-help CheckAADGuestStatus -full`r`n"
