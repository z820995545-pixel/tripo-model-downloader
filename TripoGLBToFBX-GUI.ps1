$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tripo模型下载器" Width="690" Height="792" MinWidth="690" MinHeight="792"
        WindowStartupLocation="CenterScreen" WindowStyle="None" AllowsTransparency="True"
        ShowInTaskbar="True" Background="Transparent" ResizeMode="CanResizeWithGrip" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="TitleButton" TargetType="Button">
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="surface" Background="Transparent"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="surface" Property="Background" Value="#E5ECF5"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="surface" Property="Background" Value="#D6E0ED"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="SecondaryButton" TargetType="Button">
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="surface" CornerRadius="8" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" RecognizesAccessKey="True"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="surface" Property="Background" Value="#EAF1FC"/><Setter TargetName="surface" Property="BorderBrush" Value="#ADC3E4"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="surface" Property="Background" Value="#DDE8F8"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter TargetName="surface" Property="Opacity" Value="0.55"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="PrimaryButton" TargetType="Button">
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="surface" CornerRadius="9" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="surface" Property="Opacity" Value="0.92"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="surface" Property="Opacity" Value="0.82"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter TargetName="surface" Property="Opacity" Value="0.55"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="FieldTextBox" TargetType="TextBox">
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="TextBox"><Border x:Name="surface" CornerRadius="8" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}"><ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="surface" Property="BorderBrush" Value="#80A8E8"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter TargetName="surface" Property="Opacity" Value="0.6"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
  </Window.Resources>
  <Border Background="#F9FBFE" BorderBrush="#D6E0EF" BorderThickness="1" CornerRadius="11">
    <Border.Effect><DropShadowEffect BlurRadius="20" ShadowDepth="2" Opacity="0.15"/></Border.Effect>
    <Grid>
      <Grid.RowDefinitions><RowDefinition Height="50"/><RowDefinition Height="*"/></Grid.RowDefinitions>
      <Grid x:Name="TitleBar" Grid.Row="0" Background="#F2F6FC">
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="MinButton" Style="{StaticResource TitleButton}" Width="54" Height="49" Background="Transparent" BorderThickness="0" ToolTip="最小化"><Path Data="M 9,15 L 25,15" Stroke="#202A3A" StrokeThickness="1.6"/></Button>
          <Button x:Name="MaxButton" Style="{StaticResource TitleButton}" Width="54" Height="49" Background="Transparent" BorderThickness="0" ToolTip="最大化"><Path Data="M 10,7 L 24,7 L 24,21 L 10,21 Z" Stroke="#202A3A" StrokeThickness="1.5"/></Button>
          <Button x:Name="CloseButton" Style="{StaticResource TitleButton}" Width="54" Height="49" Background="Transparent" BorderThickness="0" ToolTip="关闭"><Path Data="M 10,7 L 23,21 M 23,7 L 10,21" Stroke="#202A3A" StrokeThickness="1.6"/></Button>
        </StackPanel>
      </Grid>
      <StackPanel Grid.Row="1" Margin="31,32,31,31">
          <Grid Height="72" Margin="0,0,0,44">
            <Grid.ColumnDefinitions><ColumnDefinition Width="91"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Image x:Name="CubeIcon" Width="68" Height="68" Stretch="Uniform" HorizontalAlignment="Left" VerticalAlignment="Center"/>
            <StackPanel Grid.Column="1" VerticalAlignment="Center">
              <TextBlock Text="Tripo模型下载器" FontSize="36" FontWeight="Bold" Foreground="#151E30"/>
              <TextBlock Text="粘贴模型链接，保存为本地 3D 文件" FontSize="22" Foreground="#68768D" Margin="0,1,0,0"/>
            </StackPanel>
          </Grid>

          <Grid Height="22" Margin="0,0,0,18">
            <Grid.ColumnDefinitions><ColumnDefinition Width="37"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Image x:Name="LinkIcon" Width="27" Height="27" Stretch="Uniform" VerticalAlignment="Center"/>
            <TextBlock Grid.Column="1" Text="Tripo 页面链接" FontSize="21" FontWeight="SemiBold" Foreground="#1A2437" VerticalAlignment="Center"/>
          </Grid>
          <Grid Height="55" Margin="0,0,0,43">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="114"/></Grid.ColumnDefinitions>
            <Grid>
              <TextBox x:Name="UrlBox" Style="{StaticResource FieldTextBox}" Height="55" Padding="17,7" FontSize="21" VerticalContentAlignment="Center" BorderBrush="#CDD8EA" BorderThickness="1.5" Background="White" Foreground="#202B40" ToolTip="粘贴或输入 Tripo 项目页面地址"/>
              <TextBlock x:Name="UrlPlaceholder" Text="https://studio.tripo3d.ai/..." Margin="18,0,8,0" FontSize="19" Foreground="#68768D" VerticalAlignment="Center" IsHitTestVisible="False"/>
            </Grid>
            <Button x:Name="PasteButton" Style="{StaticResource SecondaryButton}" Grid.Column="1" Content="粘贴" Margin="12,0,0,0" Height="55" FontSize="18" Foreground="#172338" Background="#F3F6FB" BorderBrush="#CAD6EA" BorderThickness="1.3"/>
          </Grid>

          <Grid Height="22" Margin="0,0,0,18">
            <Grid.ColumnDefinitions><ColumnDefinition Width="37"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Image x:Name="FolderIcon" Width="27" Height="27" Stretch="Uniform" VerticalAlignment="Center"/>
            <TextBlock Grid.Column="1" Text="保存位置" FontSize="21" FontWeight="SemiBold" Foreground="#1A2437" VerticalAlignment="Center"/>
          </Grid>
          <Grid Height="55" Margin="0,0,0,35">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="114"/></Grid.ColumnDefinitions>
            <TextBox x:Name="FolderBox" Style="{StaticResource FieldTextBox}" Height="55" Padding="17,7" FontSize="21" VerticalContentAlignment="Center" BorderBrush="#CDD8EA" BorderThickness="1.5" Background="White" Foreground="#202B40"/>
            <Button x:Name="BrowseButton" Style="{StaticResource SecondaryButton}" Grid.Column="1" Content="浏览…" Margin="12,0,0,0" Height="55" FontSize="18" Foreground="#172338" Background="#F3F6FB" BorderBrush="#CAD6EA" BorderThickness="1.3"/>
          </Grid>

          <Border Height="1" Background="#DCE4EF"/>
          <Grid Height="108">
            <Grid.ColumnDefinitions><ColumnDefinition Width="91"/><ColumnDefinition Width="*"/><ColumnDefinition Width="88"/><ColumnDefinition Width="42"/></Grid.ColumnDefinitions>
            <Image x:Name="BlenderIcon" Width="68" Height="68" Stretch="Uniform" HorizontalAlignment="Left" VerticalAlignment="Center"/>
            <StackPanel Grid.Column="1" VerticalAlignment="Center">
              <TextBlock x:Name="BlenderTitle" Text="正在检测 Blender…" FontSize="21" FontWeight="SemiBold" Foreground="#1A2437"/>
              <TextBlock x:Name="BlenderDetail" Text="可用于模型转换" FontSize="19" Foreground="#66758C" Margin="0,1,0,0" TextTrimming="CharacterEllipsis"/>
            </StackPanel>
            <Button x:Name="BrowseBlenderButton" Style="{StaticResource SecondaryButton}" Grid.Column="2" Content="选择" Width="82" Height="38" FontSize="16" Foreground="#172338" Background="#F3F6FB" BorderBrush="#CAD6EA" BorderThickness="1.3" ToolTip="选择本地 blender.exe"/>
            <Image x:Name="BlenderStatusIcon" Grid.Column="3" Width="32" Height="32" Stretch="Uniform" VerticalAlignment="Center" HorizontalAlignment="Right" Visibility="Collapsed" ToolTip="Blender 检测状态"/>
          </Grid>

          <Button x:Name="RunButton" Style="{StaticResource PrimaryButton}" Height="74" FontSize="22" FontWeight="SemiBold" Foreground="White" BorderBrush="#2F78F2" BorderThickness="1" Cursor="Hand">
            <Button.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,0"><GradientStop Color="#2D7BF5" Offset="0"/><GradientStop Color="#306EEA" Offset="1"/></LinearGradientBrush></Button.Background>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
              <Image x:Name="DownloadIcon" Width="28" Height="28" Stretch="Uniform" Margin="0,0,16,0"/>
              <TextBlock x:Name="RunLabel" Text="解析并下载" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Border Height="1" Background="#DCE4EF" Margin="0,25,0,0"/>
          <Grid Height="24" Margin="0,28,0,13">
            <Grid.ColumnDefinitions><ColumnDefinition Width="39"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <Ellipse x:Name="StateDot" Width="19" Height="19" Fill="#3AA957" VerticalAlignment="Center"/>
            <TextBlock x:Name="StatusText" Grid.Column="1" Text="准备就绪" FontSize="20" Foreground="#1B263B" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
            <TextBlock x:Name="PercentText" Grid.Column="2" Text="0%" FontSize="19" Foreground="#68768D" VerticalAlignment="Center"/>
          </Grid>
          <Border x:Name="ProgressTrack" CornerRadius="9" Background="#D6E0EF" Height="18" ClipToBounds="True">
            <Border x:Name="ProgressFill" CornerRadius="9" Background="#3478E5" Width="0" HorizontalAlignment="Left"/>
          </Border>
      </StackPanel>
    </Grid>
  </Border>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$names = @('TitleBar','MinButton','MaxButton','CloseButton','CubeIcon','LinkIcon','FolderIcon','BlenderIcon','DownloadIcon','UrlBox','UrlPlaceholder','PasteButton','FolderBox','BrowseButton','BrowseBlenderButton','BlenderTitle','BlenderDetail','BlenderStatusIcon','RunButton','RunLabel','StateDot','StatusText','PercentText','ProgressTrack','ProgressFill')
foreach ($name in $names) { Set-Variable -Name $name -Value $window.FindName($name) }

$iconRoot = Join-Path $PSScriptRoot 'assets\icons'
$window.Icon = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new((Join-Path $iconRoot 'tripo-model-downloader.ico')))
foreach ($pair in @(@('CubeIcon','cube-logo.png'),@('LinkIcon','link.png'),@('FolderIcon','folder.png'),@('BlenderIcon','blender-official.png'),@('DownloadIcon','download.png'))) {
    $bitmap = [Windows.Media.Imaging.BitmapImage]::new()
    $bitmap.BeginInit(); $bitmap.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.UriSource = [Uri]::new((Join-Path $iconRoot $pair[1])); $bitmap.EndInit(); $bitmap.Freeze()
    (Get-Variable -Name $pair[0] -ValueOnly).Source = $bitmap
}
function Import-StatusBitmap([string]$FileName) {
    $bitmap = [Windows.Media.Imaging.BitmapImage]::new()
    $bitmap.BeginInit(); $bitmap.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.UriSource = [Uri]::new((Join-Path $iconRoot $FileName)); $bitmap.EndInit(); $bitmap.Freeze()
    return $bitmap
}
$script:BlenderReadyIcon = Import-StatusBitmap 'status-ready.png'
$script:BlenderMissingIcon = Import-StatusBitmap 'status-missing.png'
if (-not ('TripoTaskbarIdentity' -as [type])) {
    Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class TripoTaskbarIdentity {
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appID);
    [DllImport("kernel32.dll")]
    public static extern System.IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
}
'@
}
[void][TripoTaskbarIdentity]::SetCurrentProcessExplicitAppUserModelID('Tripo.ModelDownloader')
if ($env:TRIPO_HIDE_CONSOLE -eq '1') {
    $consoleWindow = [TripoTaskbarIdentity]::GetConsoleWindow()
    if ($consoleWindow -ne [IntPtr]::Zero) { [void][TripoTaskbarIdentity]::ShowWindow($consoleWindow, 0) }
}
$BlenderStatusIcon.Visibility = 'Collapsed'

$settingsPath = Join-Path $PSScriptRoot 'settings.json'
$FolderBox.Text = Join-Path $PSScriptRoot 'converted'
$script:SelectedBlenderPath = ''
if (Test-Path -LiteralPath $settingsPath) {
    try {
        $saved = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
        if ($saved.OutputDirectory) { $FolderBox.Text = [string]$saved.OutputDirectory }
        if ($saved.BlenderPath) { $script:SelectedBlenderPath = [string]$saved.BlenderPath }
    } catch { }
}

$script:ChildProcess = $null
$script:ChildMode = ''
$script:ProgressPath = ''

function Save-Settings {
    [IO.File]::WriteAllText($settingsPath, (@{
        OutputDirectory = $FolderBox.Text.Trim()
        BlenderPath = $script:SelectedBlenderPath
    } | ConvertTo-Json), [Text.Encoding]::UTF8)
}

function Start-Worker([string]$Mode, [string]$Url, [string]$Output, [string]$BlenderPath = '') {
    $token = [guid]::NewGuid().ToString('N')
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) 'TripoModelDownloader'
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $script:ProgressPath = Join-Path $tempRoot "$token.progress"

    $body = if ($Mode -eq 'detect') {
        '& $env:TRIPO_SCRIPT -DetectBlender -NoAutoInstallBlender -BlenderPath $env:TRIPO_BLENDER -ProgressFile $env:TRIPO_PROGRESS; exit $LASTEXITCODE'
    } else {
        '& $env:TRIPO_SCRIPT -Url $env:TRIPO_URL -OutputDirectory $env:TRIPO_OUT -BlenderPath $env:TRIPO_BLENDER -ProgressFile $env:TRIPO_PROGRESS; exit $LASTEXITCODE'
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $PSHOME 'powershell.exe'
    if (-not (Test-Path -LiteralPath $psi.FileName)) { $psi.FileName = 'powershell.exe' }
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $psi.EnvironmentVariables['TRIPO_SCRIPT'] = Join-Path $PSScriptRoot 'TripoGLBToFBX.ps1'
    $psi.EnvironmentVariables['TRIPO_URL'] = $Url
    $psi.EnvironmentVariables['TRIPO_OUT'] = $Output
    $psi.EnvironmentVariables['TRIPO_BLENDER'] = $BlenderPath
    $psi.EnvironmentVariables['TRIPO_PROGRESS'] = $script:ProgressPath
    $proc = New-Object Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null
    $script:ChildProcess = $proc
    $script:ChildMode = $Mode
}

function Set-RunState([bool]$Busy) {
    $RunButton.IsEnabled = -not $Busy
    $UrlBox.IsEnabled = -not $Busy
    $FolderBox.IsEnabled = -not $Busy
    $BrowseButton.IsEnabled = -not $Busy
    $BrowseBlenderButton.IsEnabled = -not $Busy
    $PasteButton.IsEnabled = -not $Busy
    if ($Busy) { $RunLabel.Text = '正在处理…'; $StateDot.Fill = '#E9A23B' }
    else { $RunLabel.Text = '解析并下载' }
}

function Set-ProgressValue([int]$Value) {
    $script:CurrentProgress = [Math]::Min(100, [Math]::Max(0, $Value))
    $PercentText.Text = "$script:CurrentProgress%"
    $ProgressFill.Width = [Math]::Max(0, $ProgressTrack.ActualWidth * ($script:CurrentProgress / 100.0))
}

function Read-SharedText([string]$Path) {
    $reader = $null
    $stream = New-Object IO.FileStream($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try { $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8); return $reader.ReadToEnd() }
    finally { if ($reader) { $reader.Dispose() } else { $stream.Dispose() } }
}

$TitleBar.Add_MouseLeftButtonDown({ if ($_.ButtonState -eq 'Pressed' -and $window.WindowState -ne 'Maximized') { $window.DragMove() } })
$MinButton.Add_Click({ $window.WindowState = 'Minimized' })
$MaxButton.Add_Click({ if ($window.WindowState -eq 'Maximized') { $window.WindowState = 'Normal' } else { $window.WindowState = 'Maximized' } })
$CloseButton.Add_Click({ $window.Close() })
$UrlBox.Add_TextChanged({ if ($UrlBox.Text.Length -gt 0) { $UrlPlaceholder.Visibility = 'Collapsed' } else { $UrlPlaceholder.Visibility = 'Visible' } })
$ProgressTrack.Add_SizeChanged({ Set-ProgressValue $script:CurrentProgress })
$PasteButton.Add_Click({
    try {
        $clip = [System.Windows.Clipboard]::GetText()
        if ($clip) { $UrlBox.Text = $clip.Trim(); $UrlBox.CaretIndex = $UrlBox.Text.Length; $UrlBox.Focus() }
        else { $StatusText.Text = '剪贴板没有链接，请复制 Tripo 页面地址后再试'; $UrlBox.Focus() }
    } catch { $StatusText.Text = '无法读取剪贴板，请直接粘贴或输入链接' }
})
$BrowseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = '选择模型文件保存位置'
    $dialog.SelectedPath = $FolderBox.Text
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $FolderBox.Text = $dialog.SelectedPath }
})
$BrowseBlenderButton.Add_Click({
    if ($script:ChildProcess -and -not $script:ChildProcess.HasExited) {
        $StatusText.Text = '正在检测或处理，请稍候再选择 Blender'
        return
    }
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = '选择 Blender.exe'
    $dialog.Filter = 'Blender 程序 (blender.exe)|blender.exe|所有文件 (*.*)|*.*'
    $dialog.CheckFileExists = $true
    $dialog.Multiselect = $false
    if ($script:SelectedBlenderPath -and (Test-Path -LiteralPath $script:SelectedBlenderPath)) {
        $dialog.InitialDirectory = Split-Path -Parent $script:SelectedBlenderPath
        $dialog.FileName = Split-Path -Leaf $script:SelectedBlenderPath
    }
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $candidate = [IO.Path]::GetFullPath($dialog.FileName)
    if ([IO.Path]::GetFileName($candidate) -ine 'blender.exe') {
        $BlenderTitle.Text = '文件不是 Blender.exe'; $BlenderDetail.Text = '请选择 Blender 安装目录中的 blender.exe'; $BlenderTitle.Foreground = '#B54747'
        $BlenderStatusIcon.Source = $script:BlenderMissingIcon; $BlenderStatusIcon.Visibility = 'Visible'; return
    }
    $script:SelectedBlenderPath = $candidate
    Save-Settings
    $BlenderTitle.Text = '正在验证 Blender…'; $BlenderDetail.Text = $candidate; $BlenderDetail.ToolTip = $candidate; $BlenderTitle.Foreground = '#1A2437'
    $BlenderStatusIcon.Visibility = 'Collapsed'
    try { Start-Worker 'detect' '' '' $script:SelectedBlenderPath } catch {
        $BlenderTitle.Text = 'Blender 检测失败'; $BlenderDetail.Text = '无法启动检测进程'; $BlenderDetail.ToolTip = $_.Exception.Message; $BlenderTitle.Foreground = '#B54747'
        $BlenderStatusIcon.Source = $script:BlenderMissingIcon; $BlenderStatusIcon.Visibility = 'Visible'
    }
})
$RunButton.Add_Click({
    $link = $UrlBox.Text.Trim()
    $uri = $null
    if (-not [Uri]::TryCreate($link, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -notin @('http','https')) {
        $StatusText.Text = '请先粘贴或输入有效的 Tripo 页面链接'
        $StateDot.Fill = '#D9534F'; $UrlBox.Focus(); return
    }
    $destination = $FolderBox.Text.Trim()
    if (-not $destination) { $StatusText.Text = '请先选择保存位置'; $StateDot.Fill = '#D9534F'; return }
    try {
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Save-Settings
        Set-ProgressValue 0; $StatusText.Text = '正在启动下载…'
        Set-RunState $true
        Start-Worker 'convert' $link $destination $script:SelectedBlenderPath
    } catch {
        Set-RunState $false; $StatusText.Text = "无法启动：$($_.Exception.Message)"; $StateDot.Fill = '#D9534F'
    }
})

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(400)
$timer.Add_Tick({
    if (-not $script:ChildProcess) { return }
    if ($script:ChildMode -eq 'detect' -and $script:ChildProcess.HasExited) {
        $detectText = if (Test-Path -LiteralPath $script:ProgressPath) { Read-SharedText $script:ProgressPath } else { '' }
        $match = [regex]::Match($detectText, '(?m)^BLENDER_PATH=(.+)$')
        if ($match.Success) {
            $versionName = Split-Path (Split-Path $match.Groups[1].Value.Trim() -Parent) -Leaf
            $versionName = $versionName -replace '^Blender\s*', ''
            $BlenderTitle.Text = '已检测到 Blender ' + $versionName
            $BlenderDetail.Text = $match.Groups[1].Value.Trim(); $BlenderDetail.ToolTip = $BlenderDetail.Text
            $BlenderTitle.Foreground = '#263448'; $BlenderStatusIcon.Source = $script:BlenderReadyIcon; $BlenderStatusIcon.Visibility = 'Visible'
        } else {
            $missingMatch = [regex]::Match($detectText, '(?m)^BLENDER_NOT_FOUND=(.+)$')
            if ($missingMatch.Success) {
                $BlenderTitle.Text = '未检测到 Blender'; $BlenderDetail.Text = '转换时将自动下载官方便携版（约 405 MB）'
                $BlenderDetail.ToolTip = $missingMatch.Groups[1].Value.Trim()
                $BlenderTitle.Foreground = '#A66A14'
            } else {
                $BlenderTitle.Text = 'Blender 检测失败'; $BlenderDetail.Text = '请重启应用重试 Blender 检测'
                $BlenderDetail.ToolTip = if ($detectText) { $detectText } else { "检测进程异常退出（代码 $($script:ChildProcess.ExitCode)）" }
                $BlenderTitle.Foreground = '#B54747'
            }
            $BlenderStatusIcon.Source = $script:BlenderMissingIcon; $BlenderStatusIcon.Visibility = 'Visible'
        }
        $script:ChildProcess.Dispose(); $script:ChildProcess = $null; $script:ChildMode = ''
        return
    }
    if ($script:ChildMode -eq 'convert') {
        if (Test-Path -LiteralPath $script:ProgressPath) {
            try {
                $line = (Read-SharedText $script:ProgressPath).Trim()
                if ($line -match '^ERROR\t(.*)$') {
                    $StatusText.Text = '处理失败：' + $matches[1]; $StatusText.ToolTip = $matches[1]; $StateDot.Fill = '#D9534F'
                } elseif ($line -match '^(\d+)\t(.*)$') {
                    $value = [Math]::Min(100, [Math]::Max(0, [int]$matches[1]))
            Set-ProgressValue $value; $StatusText.Text = $matches[2]
                }
            } catch { }
        }
        if ($script:ChildProcess.HasExited) {
            $exitCode = $script:ChildProcess.ExitCode
            if ($exitCode -eq 0) {
                Set-ProgressValue 100; $StatusText.Text = '完成，GLB 与 FBX 已保存到所选文件夹'; $StateDot.Fill = '#49A867'
            } else {
                $message = if (Test-Path -LiteralPath $script:ProgressPath) { (Read-SharedText $script:ProgressPath).Trim() } else { '' }
                $message = $message -replace '^ERROR\t', ''
                if (-not $message) { $message = "转换失败，进程退出码：$exitCode" }
                if ($message.Length -gt 260) { $message = $message.Substring($message.Length - 260) }
                $StatusText.Text = '处理失败：' + ($message -replace '[\r\n]+',' '); $StatusText.ToolTip = $message; $StateDot.Fill = '#D9534F'
            }
            Set-RunState $false
            $script:ChildProcess.Dispose(); $script:ChildProcess = $null; $script:ChildMode = ''
        }
    }
})
$timer.Start()
try { Start-Worker 'detect' '' '' $script:SelectedBlenderPath } catch {
    $BlenderTitle.Text = 'Blender 检测失败'; $BlenderDetail.Text = '无法启动检测进程'; $BlenderDetail.ToolTip = $_.Exception.Message
    $BlenderTitle.Foreground = '#B54747'; $BlenderStatusIcon.Source = $script:BlenderMissingIcon; $BlenderStatusIcon.Visibility = 'Visible'
}
$window.Add_Closed({ $timer.Stop(); if ($script:ChildProcess -and -not $script:ChildProcess.HasExited) { try { $script:ChildProcess.Kill() } catch { } } })
$window.Add_SourceInitialized({
    $source = [Windows.Interop.HwndSource]::FromVisual($window)
    if ($source) { [void][TripoTaskbarIdentity]::ShowWindow($source.Handle, 5) }
})
$window.WindowState = 'Normal'
$window.ShowActivated = $true
$window.ShowDialog() | Out-Null
