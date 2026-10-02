# Tripo模型下载器

本项目以 MIT License 开源。第三方 Blender 标志仅用于标识 Blender 状态，相关商标说明见 `assets/icons/ATTRIBUTION.md`。

## 图形界面

双击 `Tripo模型下载器.cmd` 打开小窗口（旧入口 `Run-TripoGLBToFBX.cmd` 也仍可用）。启动过程由隐藏的 Windows Script Host 转发，不会停留一个 PowerShell 控制台窗口：

1. 粘贴或输入 Tripo 项目页面链接；
2. 选择模型保存位置；
3. 点击“解析并下载”，等待 GLB 下载和 FBX 转换完成。

窗口启动时会检测系统 Blender。检测到时直接复用；没有检测到时，处理模型时会自动下载并缓存官方便携版 Blender（约 405 MB）。保存目录会记住上次选择。启动器隐藏 PowerShell 控制台；窗口和任务栏使用 Tripo cube 图标。

如果没有自动识别到 Blender，可以在 Blender 状态区域点击“选择”，手动选择安装目录中的 `blender.exe`。选择的路径会保存，下次启动自动使用；自动扫描也会兼容 Blender 3.6、4.4、4.5 等未写死版本号的常见安装目录。

如果剪贴板为空，粘贴按钮会提示并保持链接输入框为空；请复制链接后再粘贴，或直接在输入框输入。

也可继续使用命令行方式，直接传入参数时 `.cmd` 会自动走 CLI：

```powershell
Run-TripoGLBToFBX.cmd -Url "https://studio.tripo3d.ai/zh/workspace/generate/你的项目ID"
```

## 命令行方式

这个工具会：

1. 读取 Tripo 模型页面代码；
2. 自动找到页面已经加载的真实 `.glb` 地址；
3. 下载 GLB；
4. 自动调用本地 Blender，转换成带材质/贴图信息的 FBX。

在 PowerShell 中运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\TripoGLBToFBX.ps1 -Url "https://studio.tripo3d.ai/zh/workspace/generate/你的项目ID"
```

如果不想手动粘贴 URL，可以先复制 Tripo 当前页面地址，然后运行：

```powershell
.\TripoGLBToFBX.ps1
```

输出默认写入工具目录下的 `converted` 文件夹。也可以指定目录：

```powershell
.\TripoGLBToFBX.ps1 -Url "页面地址" -OutputDirectory "D:\Models"
```

## Blender

脚本会优先检测 PATH、常见安装目录、注册表和 WinGet 安装目录中的 Blender；检测到系统已有 Blender 后，不会重复下载。只有完全找不到 Blender 时，才会自动下载官方便携版 Blender（约 405 MB）并缓存到 `.blender-cache`。也可以手动指定：

```powershell
.\TripoGLBToFBX.ps1 -Url "页面地址" -BlenderPath "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
```

模型页面必须能被脚本直接访问，并且生成任务已经完成。私有模型若需要浏览器登录态，建议先将模型设为可访问，或在可访问模型页面上运行。

## 图标资源

`assets/icons` 中的 cube、链接、文件夹和下载图标为透明 PNG，由 `Generate-Icons.ps1` 绘制；Blender 标志取自 [Blender 官方图标资源](https://download.blender.org/branding/square/blender_icon_1024x1024.png)，仅用于标识 Blender 状态。商标使用说明见 [Blender Logo 页面](https://www.blender.org/about/logo/)。
