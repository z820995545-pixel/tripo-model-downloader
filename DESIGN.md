# Design direction: Tripo模型下载器

## Surface

One compact Windows utility window in Operate mode. The approved mockup is `.impeccable/approved/tripo-model-downloader.png`. The built window preserves its approximately 0.87 width-to-height proportion at 690 × 792 logical pixels.

## Direction

Use a restrained white Windows desktop surface with a single product title in the content area and blank custom title-bar space for window controls. Preserve the approved image’s relative type, icon, control, and whitespace scale instead of shrinking the content into a denser form. Use one blue accent for the main action, subtle blue-gray control borders, and green only for ready/success states. Embed transparent PNG assets for the cube, link, folder, download, and Blender mark. The app icon and taskbar identity use the Tripo cube, not the PowerShell host. Use whitespace and light separators instead of enclosing each section in a card.

## Interaction priorities

1. Paste or type a Tripo page URL.
2. Set the local destination.
3. Scan Blender detection status.
4. Start parse and download, then follow progress and completion/error status.

## Component character

- One-line URL and folder fields with conventional Windows focus and selection behavior.
- Quiet secondary paste and browse buttons.
- One full-width blue primary action.
- Inline status and a restrained progress bar; no decorative motion.
- Use system UI typography and clear focus indication.

## Provenance

The visual reference is the user-approved image generated in this conversation. Controls, icons, and layout are to be built as native WPF elements rather than shipped as a flattened image.
