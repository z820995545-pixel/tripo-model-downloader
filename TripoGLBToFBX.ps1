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
        Write-Host "首次运行：下载 Blender 便携版（约 405 MB）..."
        Invoke-WebRequest -Uri "https://download.blender.org/release/Blender5.2/blender-5.2.1-windows-x64.zip" `
            -Headers @{ "User-Agent" = "Mozilla/5.0" } -OutFile $zip
    }
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Host "解压 Blender..."
        Expand-Archive -LiteralPath $zip -DestinationPath $root -Force
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

Set-Progress 65 "正在转换为 FBX..."
$blenderArgs = @("--background", "--python", $converter, "--", $glbPath, $fbxPath)
& $blender @blenderArgs
if ($LASTEXITCODE -ne 0) { throw "Blender 转换失败，退出码：$LASTEXITCODE" }

$result = Get-Item -LiteralPath $fbxPath
Set-Progress 100 ("转换完成：{0} ({1:N1} MB)" -f $result.FullName, ($result.Length / 1MB))
if ($DeleteGlbAfter) {
    Remove-Item -LiteralPath $glbPath -Force
    Write-Host "已删除中间 GLB 文件。"
} else {
    Write-Host "保留 GLB：$glbPath"
}

