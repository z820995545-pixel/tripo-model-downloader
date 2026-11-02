param(
    [string]$Url,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "converted"),
    [string]$BlenderPath,
    [string]$ProgressFile,
    [switch]$DeleteGlbAfter,
    [switch]$NoAutoInstallBlender,
    [switch]$DetectBlender
)

$ErrorActionPreference = "Stop"

function Set-Progress([int]$Percent, [string]$Message) {
    if ($ProgressFile) {
        $line = "{0}`t{1}" -f $Percent, ($Message -replace '[\r\n\t]+', ' ')
        [System.IO.File]::WriteAllText($ProgressFile, $line, [System.Text.Encoding]::UTF8)
    }
    Write-Host $Message
}

function Download-WithProgress([string]$Uri, [string]$Destination, [int]$ProgressStart, [int]$ProgressEnd, [string]$Label) {
    $request = [Net.HttpWebRequest]::Create($Uri)
    $request.UserAgent = 'Mozilla/5.0'
    $request.Timeout = 30000
    $request.ReadWriteTimeout = 30000
    $response = $null
    $inputStream = $null
    $outputStream = $null
    $tempPath = "$Destination.download"
    try {
        Set-Progress $ProgressStart ("正在连接下载服务器：{0}" -f $Label)
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength
        $inputStream = $response.GetResponseStream()
        $outputStream = [IO.File]::Open($tempPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $buffer = New-Object byte[] (1024 * 1024)
        [long]$receivedBytes = 0
        $lastUpdate = [DateTime]::MinValue
        while (($read = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $outputStream.Write($buffer, 0, $read)
            $receivedBytes += $read
            $now = [DateTime]::UtcNow
            if (($now - $lastUpdate).TotalMilliseconds -ge 400) {
                $receivedMb = $receivedBytes / 1MB
                if ($totalBytes -gt 0) {
                    $totalMb = $totalBytes / 1MB
                    $downloadPercent = [Math]::Min(100, [Math]::Floor(($receivedBytes * 100.0) / $totalBytes))
                    $overallPercent = $ProgressStart + [int][Math]::Floor(($ProgressEnd - $ProgressStart) * $downloadPercent / 100.0)
                    Set-Progress $overallPercent ("{0}：{1:N1} / {2:N1} MB（{3}%）" -f $Label, $receivedMb, $totalMb, $downloadPercent)
                } else {
                    Set-Progress $ProgressStart ("{0}：已下载 {1:N1} MB" -f $Label, $receivedMb)
                }
                $lastUpdate = $now
            }
        }
        $outputStream.Flush()
        $outputStream.Dispose(); $outputStream = $null
        $inputStream.Dispose(); $inputStream = $null
        $response.Dispose(); $response = $null
        if ($totalBytes -gt 0 -and $receivedBytes -ne $totalBytes) {
            throw ("下载未完成：期望 {0:N1} MB，实际 {1:N1} MB。" -f ($totalBytes / 1MB), ($receivedBytes / 1MB))
        }
        if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Force }
        [IO.File]::Move($tempPath, $Destination)
        Set-Progress $ProgressEnd ("{0}完成：{1:N1} MB" -f $Label, ($receivedBytes / 1MB))
    } catch {
        if ($outputStream) { $outputStream.Dispose() }
        if ($inputStream) { $inputStream.Dispose() }
        if ($response) { $response.Dispose() }
        if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue }
        throw
    }
}

function Expand-ZipWithProgress([string]$ArchivePath, [string]$Destination, [int]$ProgressStart, [int]$ProgressEnd) {
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $totalBytes = [long](($archive.Entries | Measure-Object -Property Length -Sum).Sum)
        if ($totalBytes -le 0) { $totalBytes = 1 }
        [long]$extractedBytes = 0
        $entryNumber = 0
        foreach ($entry in $archive.Entries) {
            $entryNumber++
            $targetPath = [IO.Path]::GetFullPath((Join-Path $Destination ($entry.FullName -replace '/', '\')))
            $destinationRoot = [IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'
            if (-not $targetPath.StartsWith($destinationRoot, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Blender 压缩包中包含无效路径：$($entry.FullName)"
            }
            if ($entry.FullName.EndsWith('/')) {
                New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
                continue
            }
            $parent = Split-Path -Parent $targetPath
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
            $entryStream = $entry.Open()
            $fileStream = [IO.File]::Open($targetPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try {
                $buffer = New-Object byte[] (1024 * 1024)
                while (($read = $entryStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $fileStream.Write($buffer, 0, $read)
                    $extractedBytes += $read
                    $overallPercent = $ProgressStart + [int][Math]::Floor(($ProgressEnd - $ProgressStart) * $extractedBytes / $totalBytes)
                    Set-Progress $overallPercent ("正在解压 Blender：文件 {0}/{1}" -f $entryNumber, $archive.Entries.Count)
                }
            } finally { $fileStream.Dispose(); $entryStream.Dispose() }
        }
    } finally { $archive.Dispose() }
    Set-Progress $ProgressEnd 'Blender 解压完成，准备转换…'
}

trap {
    if ($ProgressFile) {
        try {
            $errorText = $_.Exception.Message -replace '[\r\n\t]+', ' '
            [System.IO.File]::WriteAllText($ProgressFile, "ERROR`t$errorText", [System.Text.Encoding]::UTF8)
        } catch { }
    }
    throw
}

function Normalize-PageText([string]$Text) {
    $decoded = [System.Net.WebUtility]::HtmlDecode($Text)
    $decoded = $decoded -replace '\\u002F', '/'
    $decoded = $decoded -replace '\\u0026', '&'
    $decoded = $decoded -replace '\\u003F', '?'
    $decoded = $decoded -replace '\\u003D', '='
    $decoded = $decoded -replace '\\/', '/'
    $decoded = $decoded -replace '\\"', '"'
    return $decoded
}

function Get-ProjectId([string]$PageUrl) {
    $match = [regex]::Match($PageUrl, '(?i)([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})')
    if ($match.Success) { return $match.Groups[1].Value }
    return (Get-Date -Format "yyyyMMdd-HHmmss")
}

function Find-ModelUrl([string]$PageUrl) {
    if ($PageUrl -match '(?i)\.glb(?:\?|$)') { return $PageUrl }

    $projectId = Get-ProjectId $PageUrl
    if ($projectId -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
        Write-Host "读取 Tripo 项目接口并查找模型地址..."
        $cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $apiUrl = "https://api.tripo3d.ai/v2/studio/project/detail/v3/${projectId}?locale=zh-CN&v=$cacheBust"
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                $data = (Invoke-WebRequest -Uri $apiUrl -Headers @{ "User-Agent" = "Mozilla/5.0" }).Content | ConvertFrom-Json
                if ($data.code -eq 0 -and $data.data.model_url) { return [string]$data.data.model_url }
                throw "接口返回中没有可用的 model_url。"
            } catch {
                if ($attempt -lt 3) {
                    Start-Sleep -Seconds 2
                    continue
                }
                Write-Host "项目接口读取失败：$($_.Exception.Message)"
                Write-Host "尝试从页面代码提取..."
            }
        }
    }

    Write-Host "读取 Tripo 页面并查找已加载的 GLB 地址..."
    $response = Invoke-WebRequest -Uri $PageUrl -Headers @{ "User-Agent" = "Mozilla/5.0" }
    $page = Normalize-PageText $response.Content

    $pattern = '(?i)https://[^"''<>\s]+?\.glb(?:\?[^"''<>\s]*)?'
    $urls = [regex]::Matches($page, $pattern) |
        ForEach-Object { $_.Value.TrimEnd('\', ')', ']', ';') } |
        Select-Object -Unique

    if (-not $urls) {
        throw "没有在页面代码中找到 GLB 地址。请确认 Tripo 页面可访问，并且模型已经生成完成。"
    }

    $preferred = $urls | Where-Object { $_ -match '(?i)tripo_pbr_model.*\.glb' } | Select-Object -First 1
    if (-not $preferred) {
        $preferred = $urls | Where-Object { $_ -match '(?i)output_point_cloud.*\.glb' } | Select-Object -First 1
    }
    if (-not $preferred) { $preferred = $urls | Select-Object -First 1 }
    return $preferred
}

function Find-Blender([string]$RequestedPath) {
    if ($RequestedPath) {
        if (-not (Test-Path -LiteralPath $RequestedPath)) { throw "找不到指定的 Blender：$RequestedPath" }
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    # 先检测系统已有的 Blender，避免重复下载便携版。
    $candidates = @(
        (Get-Command blender.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        (Get-Command blender -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        (Join-Path ${env:ProgramFiles} "Blender Foundation\Blender\blender.exe"),
        (Join-Path ${env:ProgramFiles} "Blender Foundation\Blender 5.2\blender.exe"),
        (Join-Path ${env:ProgramFiles} "Blender Foundation\Blender 5.1\blender.exe"),
        (Join-Path ${env:ProgramFiles} "Blender Foundation\Blender 4.3\blender.exe"),
        (Join-Path ${env:ProgramFiles} "Blender Foundation\Blender 4.2\blender.exe"),
        (Join-Path ${env:LOCALAPPDATA} "Programs\Blender Foundation\Blender\blender.exe"),
        (Join-Path ${env:LOCALAPPDATA} "Programs\Blender Foundation\Blender 5.2\blender.exe"),
        (Join-Path ${env:LOCALAPPDATA} "Programs\Blender Foundation\Blender 4.3\blender.exe"),
        (Join-Path ${env:LOCALAPPDATA} "Microsoft\WinGet\Packages\BlenderFoundation.Blender_Microsoft.Winget.Source_*\blender.exe"),
        (Join-Path ${env:LOCALAPPDATA} "Microsoft\WinGet\Packages\BlenderFoundation.Blender_Microsoft.Winget.Source_*\Blender Foundation\Blender *\blender.exe"),
        (Join-Path $PSScriptRoot "blender\blender.exe"),
        (Join-Path $PSScriptRoot "..\..\work\blender\blender-5.2.1-windows-x64\blender.exe")
    )

    # 兼容未写死版本号的安装目录，例如 Blender 3.6、4.4、4.5 或自带版本目录。
    $versionedRoots = @(
        (Join-Path ${env:ProgramFiles} "Blender Foundation"),
        (Join-Path ${env:ProgramFiles(x86)} "Blender Foundation"),
        (Join-Path ${env:LOCALAPPDATA} "Programs\Blender Foundation")
    )
    foreach ($root in $versionedRoots) {
        if (Test-Path -LiteralPath $root) {
            $candidates += Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { Join-Path $_.FullName 'blender.exe' }
            $candidates += Join-Path $root 'blender.exe'
        }
    }

    $registryCandidates = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\blender.exe",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\blender.exe"
    ) | ForEach-Object {
        try { (Get-ItemProperty -LiteralPath $_ -ErrorAction Stop).'(default)' } catch { $null }
    }
    $candidates += $registryCandidates

    $resolvedCandidates = foreach ($candidate in $candidates) {
        if (-not $candidate) { continue }
        if ($candidate -match '[*?]') {
            Get-ChildItem -Path $candidate -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
        } elseif (Test-Path -LiteralPath $candidate) {
            (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $blender = $resolvedCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
    if ($blender) {
        Write-Host "检测到系统 Blender：$blender"
        return $blender
    }

    if ($NoAutoInstallBlender) { throw "没有找到 Blender。请安装 Blender，或用 -BlenderPath 指定 blender.exe。" }

    $cache = Join-Path $PSScriptRoot ".blender-cache"
    $zip = Join-Path $cache "blender-5.2.1-windows-x64.zip"
    $root = Join-Path $cache "blender"
    New-Item -ItemType Directory -Force -Path $cache | Out-Null

    if (-not (Test-Path -LiteralPath $zip)) {
        Download-WithProgress "https://download.blender.org/release/Blender5.2/blender-5.2.1-windows-x64.zip" $zip 58 78 '正在下载 Blender 便携版'
    }
    if (-not (Test-Path -LiteralPath $root)) {
        Set-Progress 79 '正在解压 Blender…'
        Expand-ZipWithProgress $zip $root 79 89
    }

    $portable = Get-ChildItem -LiteralPath $root -Filter "blender.exe" -Recurse | Select-Object -First 1
    if (-not $portable) { throw "Blender 便携版解压后仍未找到 blender.exe。" }
    return $portable.FullName
}

if ($DetectBlender) {
    try {
        $detectedBlender = Find-Blender $BlenderPath
        if ($ProgressFile) { [System.IO.File]::WriteAllText($ProgressFile, "BLENDER_PATH=$detectedBlender", [System.Text.Encoding]::UTF8) }
        Write-Output "BLENDER_PATH=$detectedBlender"
        exit 0
    } catch {
        if ($ProgressFile) { [System.IO.File]::WriteAllText($ProgressFile, "BLENDER_NOT_FOUND=$($_.Exception.Message)", [System.Text.Encoding]::UTF8) }
        Write-Output "BLENDER_NOT_FOUND=$($_.Exception.Message)"
        exit 2
    }
}

if (-not $Url) {
    $Url = Get-Clipboard -Raw -ErrorAction SilentlyContinue
    if (-not $Url) { throw "请用 -Url 传入 Tripo 页面地址，或先把页面地址复制到剪贴板。" }
    $Url = $Url.Trim()
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Set-Progress 5 "正在解析 Tripo 项目..."
$projectId = Get-ProjectId $Url
$modelUrl = Find-ModelUrl $Url
$glbPath = Join-Path $OutputDirectory ("tripo_{0}.glb" -f $projectId)
$fbxPath = Join-Path $OutputDirectory ("tripo_{0}.fbx" -f $projectId)

Set-Progress 25 "正在下载 GLB 模型..."
Invoke-WebRequest -Uri $modelUrl -Headers @{ "User-Agent" = "Mozilla/5.0" } -OutFile $glbPath

Set-Progress 58 "正在检查 Blender..."
$blender = Find-Blender $BlenderPath
$converter = Join-Path $PSScriptRoot "blender_convert.py"
if (-not (Test-Path -LiteralPath $converter)) { throw "缺少 Blender 转换脚本：$converter" }

Set-Progress 90 "正在转换为 FBX..."
$blenderArgs = @("--background", "--python", $converter, "--", $glbPath, $fbxPath)
$blenderLog = Join-Path $OutputDirectory ("tripo_{0}_blender.log" -f $projectId)
if (Test-Path -LiteralPath $blenderLog) { Remove-Item -LiteralPath $blenderLog -Force }
& $blender @blenderArgs 2>&1 | Set-Content -LiteralPath $blenderLog -Encoding UTF8
$blenderExitCode = $LASTEXITCODE
if ($blenderExitCode -ne 0) {
    $logTail = (Get-Content -LiteralPath $blenderLog -Tail 24 -ErrorAction SilentlyContinue) -join ' '
    throw "Blender 转换失败，退出码：$blenderExitCode。日志：$blenderLog。$logTail"
}
if (-not (Test-Path -LiteralPath $fbxPath -PathType Leaf)) {
    $logTail = (Get-Content -LiteralPath $blenderLog -Tail 24 -ErrorAction SilentlyContinue) -join ' '
    throw "Blender 未生成 FBX 文件。请查看日志：$blenderLog。$logTail"
}

$result = Get-Item -LiteralPath $fbxPath
Set-Progress 100 ("转换完成：{0} ({1:N1} MB)" -f $result.FullName, ($result.Length / 1MB))
if ($DeleteGlbAfter) {
    Remove-Item -LiteralPath $glbPath -Force
    Write-Host "已删除中间 GLB 文件。"
} else {
    Write-Host "保留 GLB：$glbPath"
}

