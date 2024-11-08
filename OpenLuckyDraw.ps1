# 開源抽獎程式 Ver 1.0.0 (以台股交易資料統計作為亂數種子) 2024-11-07
# 作者：黑暗執行緒 https://blog.darkthread.net

# 適用平台：Windows, Linux, macOS ([在 Windows、Linux 和 macOS 上安裝 PowerShell](https://learn.microsoft.com/zh-tw/powershell/scripting/install/installing-powershell?view=powershell-7.4))

# 亂數種子來源為台灣證交所之台股交易資料統計(當日 14:30 盤後產生)，將日期、成交股數、成交金額、成交筆數、發行量加權股價指數、漲跌點數等欄位組合成字串後，以 SHA256 雜湊值作為亂數種子
# 特色：執行邏輯公開、程式碼開源，亂數種子無法操控，確保抽獎結果公平公正公開，且可反覆驗證

# 種子來源網頁：https://www.twse.com.tw/zh/trading/historical/fmtqik.html 
# 種子來源 API：https://openapi.twse.com.tw/v1/exchangeReport/FMTQIK

# 使用範例：
# 1. 使用台股當日(或最新)成交統計作為亂數種子抽出前 10 名
# ./OpenLuckyDraw.ps1 RunnerList.csv 

# 2. 使用指定亂數種子抽出前 5 名
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -DrawSeed "113/11/06|8,013,368,499|409,279,637,442|2,608,905|23,217.38|110.58"

# 3. 使用指定亂數種子及抽樣檢查種子抽出前 10 名
# ./OpenLuckyDraw.ps1 RunnerList.csv -SampleSeed "2021-11-06 12:34:56" -DrawSeed "113/11/06|8,013,368,499|409,279,637,442|2,608,905|23,217.38|110.58"

# 4. 使用台股當日(或最新)成交統計作為亂數種子抽出前 10 名，並顯示指定欄位
# ./OpenLuckyDraw.ps1 RunnerList.csv -DisplayFields Name,Bibnr,Category

# 5. 使用指定亂數種子抽出前 5 名，並將幸運兒自CSV名單移除 (原 CSV 檔案會備份後覆寫)
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -DrawSeed "113/11/06|8,013,368,499|409,279,637,442|2,608,905|23,217.38|110.58" -RemoveWinners

# 6. 使用主亂數種子源及附加亂數種子源分別抽出 5 名三獎, 3 名二獎, 1 名頭獎(允許重複中獎)
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -DrawSeed "<主要種子>" -ExtraSeed "<三獎附加種子>"
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 3 -DrawSeed "<主要種子>" -ExtraSeed "<二獎附加種子>"
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 1 -DrawSeed "<主要種子>" -ExtraSeed "<頭獎附加種子>"

# 7. 使用台股當日(或最新)成交統計亂數種子分別抽出 5 名三獎, 3 名二獎, 1 名頭獎，得獎者不再參加後續抽獎
#    做法：每次抽獎後會中獎者自 CSV 名單移除 (原 CSV 檔案備份後覆寫)
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -RemoveWinners
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 3 -RemoveWinners
# ./OpenLuckyDraw.ps1 RunnerList.csv -Top 1 -RemoveWinners

param (
    [Parameter(Mandatory = $true)]
    [string]$CandidatesCsv, # 抽獎名單 CSV 檔案
    [int]$Top = 10, # 抽出名額
    [string]$SampleSeed, # 抽樣檢查亂數種子
    [string]$DrawSeed, # 抽獎亂數種子
    [string]$ExtraSeed, # 附加亂數種子
    [string[]]$DisplayFields = @(), # 顯示欄位
    [switch]$RemoveWinners # 移除中獎者
)
$ErrorActionPreference = "Stop"

[string]$RandomSeed = ''
[UInt64]$CurrentRandomNumber = 0
# 產生 SHA256 雜湊值
Function ComputeSha256Hash([string]$anyText) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($anyText))
    $hashString = [System.BitConverter]::ToString($hash) -replace "-", ""
    return $hashString
}
# 設定亂數種子
Function SetRandomSeed([string]$seed) {
    $hash = ComputeSha256Hash($seed)
    $global:RandomSeed = $hash
    $global:CurrentRandomNumber = 0
}
# 取得下一個亂數
Function GetNextRandomNumber() {
    if ($global:RandomSeed -eq '') {
        throw "請先設定亂數種子"
    }
    $hash = ComputeSha256Hash($global:RandomSeed + '+' + $global:CurrentRandomNumber)
    $global:CurrentRandomNumber = [UInt64]::Parse($hash.Substring(0, 16), [System.Globalization.NumberStyles]::HexNumber)
    return $global:CurrentRandomNumber
}
# 取得台股當日(或最新)成交統計
Function GetLatestTWSEAfterTradingStatsString() {
    $url = "https://openapi.twse.com.tw/v1/exchangeReport/FMTQIK"
    $entry = (Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "curl/7.68.0" }) | Select-Object -Last 1
    return "{0}/{1}/{2}|{3:n0}|{4:n0}|{5:n0}|{6}|{7}" -f $entry.Date.Substring(0, 3), $entry.Date.SubString(3, 2), $entry.Date.Substring(5, 2), +$entry.TradeVolume, +$entry.TradeValue, +$entry.Transaction, $entry.TAIEX, $entry.Change
}

$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Start-Transcript -Path "$PSScriptRoot\Logs\LuckyDraw-$(Get-Date -Format yyyyMMddHHmmss).log" | Out-Null
try {
    Write-Host "開源抽獎程式 Ver 1.0.0 by 黑暗執行緒" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    # 匯入參加者名單
    Write-Host "# 步驟一、匯入名單" -ForegroundColor Yellow
    $fileHash = (Get-FileHash $CandidatesCsv -Algorithm SHA256).Hash
    $csvLines = Get-Content $CandidatesCsv -Encoding UTF8
    $candidates = $csvLines | ConvertFrom-Csv
    $candidateCount = $candidates.Count
    Write-Host ("  匯入參加者 CSV: {0} 共 {1:N0} 筆，SHA256 檢核: {2}" -f $CandidatesCsv, $candidateCount, $fileHash)
    
    Write-Host "# 步驟二、抽樣檢查名單" -ForegroundColor Yellow
    # 設定抽樣檢查亂數種子
    if (!$SampleSeed) { $SampleSeed = $startTime }
    SetRandomSeed $startTime
    $sampleIndice = (1..3) | ForEach-Object { (GetNextRandomNumber) % $candidateCount }
    Write-Host "  使用亂數種子 ``$SampleSeed`` 決定抽樣序號: $($sampleIndice -join ', ')："
    $sampleIndice | ForEach-Object {
        Write-Host "    * 第 $_ 筆： $($csvLines[$_])"
    }

    Write-Host "# 步驟三、設定抽獎亂數種子(台股當日或最新成交統計)" -ForegroundColor Yellow
    if (!$DrawSeed) {
        $twseStats = GetLatestTWSEAfterTradingStatsString
        Write-Host "  取得最新市場成交資訊(日期：$($twseStats.Split('|')[0]))：$twseStats"
        Write-Host "  [主亂數種子源](台股成交統計)：``$twseStats``" -ForegroundColor Cyan
        $seed = $twseStats
    }
    else {
        Write-Host "  [主亂數種子源](自行指定)：``$DrawSeed``" -ForegroundColor Cyan
        $seed = $DrawSeed
    }
    if ($ExtraSeed) {
        Write-Host "  [附加亂數種子源]：``$ExtraSeed``"
        $seed += '(' + ([string]$ExtraSeed) + ')'
    }
    Write-Host "  最終亂數種子源：``$seed``"
    SetRandomSeed $seed

    Write-Host "# 步驟四、開始抽獎" -ForegroundColor Yellow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $candidates | ForEach-Object {
        $sortPriority = GetNextRandomNumber
        $_ | Add-Member -MemberType NoteProperty -Name SortPriority -Value $sortPriority
    }
    $sw.Stop()
    $genRndDura = $sw.Elapsed.TotalMilliseconds
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $sorted = $candidates | Sort-Object SortPriority -Descending
    $sw.Stop()
    $sortDura = $sw.Elapsed.TotalMilliseconds
    Write-Host ("  抽獎完成：產生亂數 {0:N0} ms，排序 {1:N0} ms" -f $genRndDura, $sortDura)
    Write-Host "  抽出前 $Top 名："
    # 決定顯示欄位，預設為前兩欄位
    if (!$DisplayFields -or $DisplayFields.Count -eq 0) {
        $DisplayFields = $sorted[0].PSObject.Properties | Select-Object -First 2 | Foreach-Object { $_.Name }
    }
    $DisplayFields += 'SortPriority'

    $winners = $sorted | Select-Object -First $Top 
    Write-Host "  抽獎結果：[顯示欄位：$($DisplayFields -join ', ')]"
    $winners | Select-Object -Property $DisplayFields| Format-Table -AutoSize

    if ($RemoveWinners) {
        Write-Host "# 步驟五、移除中獎者" -ForegroundColor Yellow
        $backupCsvPath = "$PSScriptRoot\Backup\$([IO.Path]::GetFileNameWithoutExtension($CandidatesCsv)).$(Get-Date -Format yyyyMMddHHmmss).csv"
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backupCsvPath)) | Out-Null 
        Write-Host "  備份原始名單至 $backupCsvPath"
        Copy-Item -Path $CandidatesCsv -Destination $backupCsvPath -Force
        $removed = $candidates | Where-Object { $winners -notcontains $_ } | Foreach-Object {
            $_.PSObject.Properties.Remove('SortPriority')
            return $_
        } 
        $removed | Export-Csv $CandidatesCsv -NoTypeInformation -Encoding UTF8
        Write-Host ("  已移除 {0:N0} 位中獎者，更新 $CandidatesCsv ({1:N0} 筆)" -f $winners.Count, $removed.Count)
    }
    Write-Host "==================================`n`n" -ForegroundColor Cyan
}
catch {
    Write-Host "錯誤：$($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Stop-Transcript | Out-Null
}
