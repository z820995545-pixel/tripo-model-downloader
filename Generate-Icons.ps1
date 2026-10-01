$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore, WindowsBase

$iconRoot = Join-Path $PSScriptRoot 'assets\icons'
New-Item -ItemType Directory -Force -Path $iconRoot | Out-Null

function New-Brush([string]$ColorA, [string]$ColorB, [double]$X1 = 1, [double]$Y1 = 1) {
    $brush = New-Object Windows.Media.LinearGradientBrush
    $brush.StartPoint = [Windows.Point]::new(0, 0)
    $brush.EndPoint = [Windows.Point]::new($X1, $Y1)
    $brush.GradientStops.Add([Windows.Media.GradientStop]::new([Windows.Media.ColorConverter]::ConvertFromString($ColorA), 0))
    $brush.GradientStops.Add([Windows.Media.GradientStop]::new([Windows.Media.ColorConverter]::ConvertFromString($ColorB), 1))
    return $brush
}

function Save-VectorPng([string]$FileName, [int]$Size, [scriptblock]$Draw) {
    $visual = New-Object Windows.Media.DrawingVisual
    $context = $visual.RenderOpen()
    & $Draw $context
    $context.Close()
    $bitmap = New-Object Windows.Media.Imaging.RenderTargetBitmap($Size, $Size, 96, 96, [Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($visual)
    $encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $file = [IO.File]::Open((Join-Path $iconRoot $FileName), [IO.FileMode]::Create, [IO.FileAccess]::Write)
    try { $encoder.Save($file) } finally { $file.Dispose() }
}

$cubeTop = [Windows.Media.Geometry]::Parse('M 128,10 L 238,70 L 128,132 L 18,70 Z')
$cubeLeft = [Windows.Media.Geometry]::Parse('M 18,70 L 128,132 L 128,248 L 18,187 Z')
$cubeRight = [Windows.Media.Geometry]::Parse('M 128,132 L 238,70 L 238,187 L 128,248 Z')
$cubeSeams = [Windows.Media.Geometry]::Parse('M 128,10 L 128,132 M 18,70 L 128,132 L 238,70 M 128,132 L 128,248')
$seamPen = New-Object Windows.Media.Pen([Windows.Media.Brushes]::White, 7)
$seamPen.LineJoin = [Windows.Media.PenLineJoin]::Round
Save-VectorPng 'cube-logo.png' 256 {
    param($dc)
    $dc.DrawGeometry((New-Brush '#DDF0FF' '#6DAEFF'), $null, $cubeTop)
    $dc.DrawGeometry((New-Brush '#66A8FF' '#2054C6'), $null, $cubeLeft)
    $dc.DrawGeometry((New-Brush '#3478E5' '#1749B3'), $null, $cubeRight)
    $dc.DrawGeometry($null, $seamPen, $cubeSeams)
}.GetNewClosure()

$linkPen = New-Object Windows.Media.Pen([Windows.Media.SolidColorBrush]::new([Windows.Media.ColorConverter]::ConvertFromString('#293A58')), 17)
$linkPen.StartLineCap = [Windows.Media.PenLineCap]::Round
$linkPen.EndLineCap = [Windows.Media.PenLineCap]::Round
$linkPen.LineJoin = [Windows.Media.PenLineJoin]::Round
$linkA = [Windows.Media.Geometry]::Parse('M 108,138 A 50,50 0 0 0 183,143 L 213,113 A 50,50 0 0 0 142,43 L 125,60')
$linkB = [Windows.Media.Geometry]::Parse('M 148,118 A 50,50 0 0 0 73,113 L 43,143 A 50,50 0 0 0 109,209 L 126,192')
Save-VectorPng 'link.png' 256 {
    param($dc)
    $dc.DrawGeometry($null, $linkPen, $linkA)
    $dc.DrawGeometry($null, $linkPen, $linkB)
}.GetNewClosure()

$folder = [Windows.Media.Geometry]::Parse('M 24,65 L 24,53 C 24,44 31,38 40,38 L 93,38 L 115,60 L 216,60 C 226,60 232,67 232,77 L 232,194 C 232,204 225,211 215,211 L 41,211 C 31,211 24,204 24,194 Z')
$folderBrush = New-Object Windows.Media.SolidColorBrush([Windows.Media.ColorConverter]::ConvertFromString('#3D4E68'))
Save-VectorPng 'folder.png' 256 {
    param($dc)
    $dc.DrawGeometry($folderBrush, $null, $folder)
}.GetNewClosure()

$downloadPen = New-Object Windows.Media.Pen([Windows.Media.Brushes]::White, 15)
$downloadPen.StartLineCap = [Windows.Media.PenLineCap]::Round
$downloadPen.EndLineCap = [Windows.Media.PenLineCap]::Round
$downloadPen.LineJoin = [Windows.Media.PenLineJoin]::Round
$downloadArrow = [Windows.Media.Geometry]::Parse('M 128,34 L 128,151 M 82,108 L 128,154 L 174,108')
$downloadTray = [Windows.Media.Geometry]::Parse('M 47,160 L 47,202 Q 47,213 59,213 L 197,213 Q 209,213 209,202 L 209,160')
Save-VectorPng 'download.png' 256 {
    param($dc)
    $dc.DrawGeometry($null, $downloadPen, $downloadArrow)
    $dc.DrawGeometry($null, $downloadPen, $downloadTray)
}.GetNewClosure()

# The Blender status mark is a compact, transparent badge that changes with detection state.
$statusCircle = New-Object Windows.Media.EllipseGeometry([Windows.Rect]::new(5, 5, 118, 118))
$statusMarkPen = New-Object Windows.Media.Pen([Windows.Media.Brushes]::White, 11)
$statusMarkPen.StartLineCap = [Windows.Media.PenLineCap]::Round
$statusMarkPen.EndLineCap = [Windows.Media.PenLineCap]::Round
$statusMarkPen.LineJoin = [Windows.Media.PenLineJoin]::Round
$statusCheck = [Windows.Media.Geometry]::Parse('M 34,66 L 54,85 L 96,41')
$statusCross = [Windows.Media.Geometry]::Parse('M 43,43 L 85,85 M 85,43 L 43,85')
$readyBadgeBrush = New-Object Windows.Media.SolidColorBrush([Windows.Media.ColorConverter]::ConvertFromString('#35A853'))
$missingBadgeBrush = New-Object Windows.Media.SolidColorBrush([Windows.Media.ColorConverter]::ConvertFromString('#D9534F'))
Save-VectorPng 'status-ready.png' 128 {
    param($dc)
    $dc.DrawGeometry($readyBadgeBrush, $null, $statusCircle)
    $dc.DrawGeometry($null, $statusMarkPen, $statusCheck)
}.GetNewClosure()
Save-VectorPng 'status-missing.png' 128 {
    param($dc)
    $dc.DrawGeometry($missingBadgeBrush, $null, $statusCircle)
    $dc.DrawGeometry($null, $statusMarkPen, $statusCross)
}.GetNewClosure()

# Windows accepts PNG-backed ICO frames (Vista and newer); this keeps the taskbar icon crisp.
$pngBytes = [IO.File]::ReadAllBytes((Join-Path $iconRoot 'cube-logo.png'))
$icoPath = Join-Path $iconRoot 'tripo-model-downloader.ico'
try {
    $icoFile = [IO.File]::Open($icoPath, [IO.FileMode]::Create, [IO.FileAccess]::Write)
    $writer = New-Object IO.BinaryWriter($icoFile)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32); $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally { $writer.Dispose(); $icoFile.Dispose() }
} catch [System.IO.IOException] {
    Write-Warning 'The taskbar ICO is in use; skipped it. Other PNG icons were updated.'
}

Write-Host "Generated transparent PNG icons in $iconRoot"
