# 開源抽獎程式 Ver 1.0 (台股交易盤後統計版)

一個程式碼及抽獎邏輯 100% 開源，公平公正又公開的抽獎程式。(保證無添加不可告人之權重機制)

[好讀版完整說明](https://blog.darkthread.net/blogs/open-lucky-draw)

我一向推崇「程式碼公開，演算結果能被反覆驗證」的抽獎程式，認為這才是解決抽獎作㢣、程式有 Bug 等無端指控的治本之道。演算法及邏輯公開，以具公信力且不可操控的方式決定亂數種子，再依據其產生亂數決定抽獎結果，是我心中最完美的抽獎程式。

程式是用 PowerShell 寫的，用 Notepad 記事本就可以看到所有程式碼，程式碼及邏輯完全公開。Windows 作業系統有內建 PowerShell，所以把 OpenLuckDraw.ps1 檔案下載回去就可以直接跑了。若是 Linux 或 macOS，可參考[在 Windows、Linux 和 macOS 上安裝 PowerShell](https://learn.microsoft.com/zh-tw/powershell/scripting/install/installing-powershell)的說明，輕鬆下載安裝，PowerShell 不難學又可以做很多事，說不定你會愛上它。

[下載 OpenLuckyDraw.ps1 與測試用範例 CSV 檔](https://github.com/darkthread/OpenLuckyDraw/releases/tag/1.0.0)

使用範例：

1. 使用台股當日(或最新)成交統計作為亂數種子抽出前 10 名
    ```powershell 
    ./OpenLuckyDraw.ps1 RunnerList.csv 
    ```
1. 使用指定亂數種子抽出前 5 名
    ```powershell 
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -DrawSeed "113/11/06|8,013,368,499|409,279,637,442|2,608,905|23,217.38|110.58"
    ```
1. 使用指定亂數種子及抽樣檢查種子抽出前 10 名 (驗證)
    ```powershell
    ./OpenLuckyDraw.ps1 RunnerList.csv -SampleSeed "2021-11-06 12:34:56" -DrawSeed "113/11/06|8,013,368,499|409,279,637,442|2,608,905|23,217.38|110.58"
    ```
1. 使用台股當日(或最新)成交統計作為亂數種子抽出前 10 名，並顯示指定欄位
    ```powershell
    ./OpenLuckyDraw.ps1 RunnerList.csv -DisplayFields Name,Bibnr,Category
    ```    
1. 使用指定亂數種子抽出前 5 名，並將幸運兒自CSV名單移除 (原 CSV 檔案會備份後覆寫)
    ```powershell
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -DrawSeed "113/11/06|8,013,368,499|409,279,637,442|2,608,905|23,217.38|110.58" -RemoveWinners
    ```
1. 使用主亂數種子源及附加亂數種子源分別抽出 5 名三獎, 3 名二獎, 1 名頭獎(允許重複中獎)
    ```powershell
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -DrawSeed "<主要種子>" -ExtraSeed "<三獎附加種子>"
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 3 -DrawSeed "<主要種子>" -ExtraSeed "<二獎附加種子>"
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 1 -DrawSeed "<主要種子>" -ExtraSeed "<頭獎附加種子>"
    ```
1. 使用台股當日(或最新)成交統計亂數種子及附加亂數種子源分別抽出 5 名三獎, 3 名二獎, 1 名頭獎，得獎者不參加後續抽獎  
   做法為每次抽獎後將中獎者自 CSV 名單移除 (原 CSV 檔案備份後覆寫)
    ```powershell
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -ExtraSeed "<三獎附加種子>" -RemoveWinners
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 3 -ExtraSeed "<二獎附加種子>" -RemoveWinners
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 1 -ExtraSeed "<頭獎附加種子>" -RemoveWinners
    ```
1. 使用台股當日(或最新)成交統計亂數種子分別抽出 5 名三獎, 3 名二獎, 1 名頭獎(得獎者不參加後續抽獎)  
    ```powershell
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 5 -RemoveWinners
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 3 -RemoveWinners
    ./OpenLuckyDraw.ps1 RunnerList.csv -Top 1 -RemoveWinners
    ```
