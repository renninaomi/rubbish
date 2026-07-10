# automatic_time_synchronization.ps1

#.\useful\automatic_time_synchronization.ps1

# 确保 Windows Time 服务正在运行
$service = Get-Service w32time
if ($service.Status -ne 'Running') {
    Start-Service w32time
}

# 定义至少三个不同的时间服务器
$servers = @(
    "time.windows.com",
    "time.apple.com",
    "ntp.aliyun.com"
)

$maxRounds = 2          # 最多轮询遍数
$targetSuccesses = 3    # 总成功次数阈值
$totalSuccesses = 0     # 当前成功次数计数器

Write-Host "开始执行系统时间同步..." -ForegroundColor Cyan

for ($round = 1; $round -le $maxRounds; $round++) {
    Write-Host "`n--- 第 $round 轮轮询 ---" -ForegroundColor Yellow
    
    # 遍历每一个服务器
    foreach ($server in $servers) {
        # 每个服务器同步2次
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            Write-Host "正在尝试与 $server 同步 (第 $attempt 次)..."
            
            # 配置手动对等端
            w32tm /config /manualpeerlist:"$server" /syncfromflags:manual /reliable:no /update | Out-Null
            
            # 强制执行同步
            $result = w32tm /resync 2>&1
            
            # 根据退出码判断是否成功
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  同步成功: $server" -ForegroundColor Green
                $totalSuccesses++
            } else {
                Write-Host "  同步失败: $server" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "第 $round 轮结束。当前总成功次数: $totalSuccesses" -ForegroundColor Cyan
    
    # 检查是否达到目标成功次数
    if ($totalSuccesses -ge $targetSuccesses) {
        Write-Host "已达到目标成功次数，停止轮询。" -ForegroundColor Green
        break
    }
    
    # 判断是否继续轮询
    if ($round -lt $maxRounds) {
        Write-Host "成功次数小于3次，准备进行下一轮轮询..." -ForegroundColor Magenta
    } else {
        Write-Host "已达到最大轮询次数。" -ForegroundColor Red
    }
}

# 最终结果反馈
Write-Host "`n--- 同步结果汇总 ---" -ForegroundColor White
Write-Host "总尝试次数: $($servers.Count * 2) (每个服务器2次)"
Write-Host "总成功次数: $totalSuccesses"

if ($totalSuccesses -ge $targetSuccesses) {
    Write-Host "最终状态: 同步目标达成。" -ForegroundColor Green
} else {
    Write-Host "最终状态: 未能在 $maxRounds 轮内达到目标成功次数。" -ForegroundColor Red
}
