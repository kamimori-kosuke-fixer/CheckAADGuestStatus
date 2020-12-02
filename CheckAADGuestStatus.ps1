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

.PARAMETER mail
Enter WebHook URI that will return a response.

.PARAMETER waitSecond
Guest status monitoring span
<CommonParameters> is not support.

.LINK
None
#>

#include config
. ".\CheckAADGuestStatus_config.ps1"

function global:CheckAADGuestStatus{
    Param(
        [parameter(mandatory,HelpMessage="�Ď��Ώۂ̃��[�U�[�̃��[���A�h���X����͂��Ă�������")][ValidateNotNullOrEmpty()][string]$mail,
        [parameter(HelpMessage="�Ď����J��Ԃ��^�C�~���O�i�b�j���w�肵�Ă�������")][ValidateNotNullOrEmpty()][string]$waitSecond,
        [parameter(HelpMessage="���ʂ�Ԃ�WebHook���w�肵�Ă�������")][ValidateNotNullOrEmpty()][string]$uri
    )
    $enc = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
    $message = "�m�F�˗��̂������Q�X�g���[�U�[���Q������܂����I" #�o�̓R�����g
    $errorFlag = 0
    
    #���[�v�̃^�C�~���O�i�����w�肪������΃f�t�H���g�l��ݒ�j
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

    if([string]::IsNullOrEmpty($uri)){
        if([string]::IsNullOrEmpty($Webhook_default)){
            Write-Host "Webhook_default is null or empty. please check config file.`r`nWebhook_default is required."
            Break
        }else{
            $uri = $Webhook_default
        }
    }

    #�ڑ�
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

    #���[�U�[���擾
    switch($user.count){
        {$_ -eq 0}{
            $message="���[�U�[��������܂���ł����B���[���A�h���X���������Ă�������`r`n"
            $errorFlag = 1
            break
        }
        {$_ -gt 1}{
            $message=$_+"���̃��[�U�[��������܂����B�Ώۂ�1���ɂȂ�悤���[���A�h���X���������Ă��������B`r`n"
            $message+=$user|ft DisplayName,mail,UserType
            $errorFlag = 1
            break
        }
        {$_ -eq 1}{
            "���L���[�U�[�̏����󋵂��`�F�b�N���܂�"
            $user|ft DisplayName,mail,UserType
            if($user.UserType -ne "Guest"){
                $message="�Ώۃ��[�U�[�̓Q�X�g�ł͂���܂���`r`n"
                $errorFlag = 1
                break
            }
            if($user.UserState -eq "Accepted"){
                $message="�Ώۂ̃Q�X�g���[�U�[�͊��ɎQ���ς݂ł�`r`n"
                $errorFlag = 1
                break
            }
        }
        default{
            $message="���[�U�[�����iGet-AzureADUser�j�ɂăC���M�����[���������Ă��܂�`r`n"
            $errorFlag = 1
            break
        }
    }

    if($errorFlag -eq 0){
        while(1) { 
            $user=Get-AzureADUser -Filter "mail eq '$mail'"
            $payload = @{
                "blocks" = @{
                    "type" = "section";
                    "text" = @{
                        type = "mrkdwn";
                        text = "User has joined!!"
                    }
                },
                @{
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

            if($user.UserState -eq "PendingAcceptance"){
                Write-Host ���F�܂��ł��B�B
            }elseif($user.UserType -ne "Guest"){
                Write-Host �Ώۃ��[�U�[�̓Q�X�g�ł͂���܂���
                break
            }elseif($user.UserState -eq "Accepted"){
                Invoke-RestMethod -Uri $uri -Method POST -Body (ConvertTo-Json $payload -Depth 4).Replace('\\n','\n')
                Get-Date -Format "yyyy/MM/dd HH:mm"
                Write-Host �Q�X�g���[�U�[�̃X�e�[�^�X��Accepted�ɍX�V����܂���
                break
            }else{
                Write-Host "���[�U�[�X�e�[�^�X�`�F�b�N�ɂăC���M�����[���������Ă��܂�`r`n"
                break
            }

            # �ҋ@
            Start-Sleep -Seconds $waitsecond
        }
    }else{
        $message+="���������́u"+$mail+"�v�ł�`r`n"
        $user =(Get-AzureADUser | `
        ?{
            $_.usertype -eq "Guest" `
            -and $_.userstate -eq "PendingAcceptance" `
            -and $_.RefreshTokensValidFromDateTime -ge (Get-Date).AddMonths(-3) 
        })
        switch($user.count){
            {$_ -ge 1}{
                $message+="���߂ł�Invite���ꂽ�Q�X�g�̂Ȃ��ŁA���Q���̃Q�X�g�͂�����ł�`r`n"

                $message+="-----`r`nMail`tUsertype`r`n"
                $user|foreach{
                    $message+= $_.mail+"`t"
                    $message+= $_.usertype+"`r`n"
                }
                $message+="-----`r`n"
            }default{
                $message+="���߂ł�Invite���ꂽ�Q�X�g�̂Ȃ��ŁA���Q���̃Q�X�g�͂��܂���ł���`r`n"
            }
        }
        $payload = 
        @{
            text = $enc.GetString([System.Text.Encoding]::UTF8.GetBytes($message));
        }
        Invoke-RestMethod -Uri $uri -Method POST -Body (ConvertTo-Json $payload -Depth 4).Replace('\\n','\n')
        Break
    }
}
