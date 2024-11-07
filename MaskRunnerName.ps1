# 跑者名單製作 參考

# 資料來源：https://www.sportsnet.org.tw/score_detail_utf8.php?Id=303
# var list = JSON.parse(localStorage.getItem('runnerList') ?? '[]');
# [...document.querySelectorAll('tr[onclick^=self]')].map((tr) => 
#     list.push([...tr.querySelectorAll('td')].map(td => td.innerText).join(','))
# );
# console.log(list.length);
# localStorage.setItem('runnerList', JSON.stringify(list));

# 姓名馬賽克工具
$csv = Get-Content RawRunnerList.csv | ConvertFrom-Csv | ForEach-Object {
    $name = $_.Name;
    if ([regex]::IsMatch($name, "^[ A-Za-z0-9]+$"))
    {
        $i = 0
        $name = ($name.ToCharArray() | ForEach-Object {
            if ($i % 3 -eq 1) { "*" } else { $_ }
            $i++
        }) -join ""
    }
    elseif ($name.Length -le 2)
    {
        $name = $name.Substring(0, 1) + "Ｏ";
    }
    else
    {
        $name = $name.Substring(0, 1) + "Ｏ" + $name.Substring(2);
    }
    $_.Name = $name;
    return $_
} | Export-Csv RunnerList.csv -NoTypeInformation -Encoding UTF8