# Product

<!-- impeccable:product-schema 1 -->

## Platform

windows desktop (requested platform)

## Stack

Inferred for this build: Windows PowerShell 5.1 with WPF, extending the existing PowerShell downloader so the user can launch it without installing another runtime.

## Users

Inferred from the request: a Windows user who generates or owns a 3D model in Tripo and wants a local model file without using Tripo's export control.

## Product Purpose

Tripo模型下载器 takes a Tripo project page link, obtains its GLB model file, and saves it locally. It can then use Blender to convert that GLB to FBX. Success means the user can complete the workflow from one small desktop window and find the resulting files in the selected folder.

## Positioning

The tool reads the model address from the Tripo project data and performs the GLB-to-FBX conversion locally through Blender.

## Operating Context

The tool runs on Windows and is launched from the existing `.cmd` entry point. Users paste or type a Tripo page URL, choose an output folder, and start the download and optional local conversion from one window.

## Capabilities and Constraints

- Accept a Tripo model page URL and offer a paste button.
- Let users choose the output folder.
- Detect an existing Blender installation and use it; if none is found, retain the existing automatic portable Blender download behavior.
- Let users browse for a local `blender.exe` when automatic detection misses a custom or uncommon installation.
- Show progress and clear completion or failure status.
- Preserve the existing command-line workflow for direct use.
- The existing Tripo project API can return model URLs for accessible projects. Private projects or service-side access restrictions may require a clear error state.

## Brand Commitments

- Product name: Tripo模型下载器.
- The user approved a compact white Windows-style interface with one visible product title, small link and folder icons, a Blender icon, and minimal group framing.

## Product Principles

- Make the URL, destination, Blender availability, and current operation easy to scan.
- Keep downloading and conversion local after obtaining the GLB URL.
- Report actionable errors instead of silently falling back to clipboard contents.
- Preserve a lightweight, single-window workflow.
