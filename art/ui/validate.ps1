param([string]$SelectedTheme = 'A', [switch]$RequireComplete)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public static class MeteorUiValidation {
    public static int CardOpening(Bitmap image) {
        int errors = 0;
        for (int y = 80; y < image.Height - 80; y++)
            for (int x = 80; x < image.Width - 80; x++)
                if (image.GetPixel(x, y).A != 0) errors++;
        return errors;
    }
    public static int Horizontal(Bitmap image, int left, int right) {
        int errors = 0;
        for (int x = left; x < image.Width - right; x++)
            for (int y = 0; y < image.Height; y++)
                if (image.GetPixel(x, y).ToArgb() != image.GetPixel(image.Width / 2, y).ToArgb()) errors++;
        return errors;
    }
    public static int[] Pixels(Bitmap image, int cap, bool checkSlice, bool icon, bool pressed) {
        Bitmap logical = null;
        if (pressed) {
            logical = new Bitmap(image.Width, image.Height, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(logical)) {
                g.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                g.DrawImageUnscaled(image, 0, -2);
            }
            image = logical;
        }
        int transparent = 0, opaque = 0, minimumAlpha = 255, maximumAlpha = 0;
        int centerErrors = 0, cornerErrors = 0, edgeErrors = 0, paddingErrors = 0;
        int w = image.Width, h = image.Height;
        Color center = image.GetPixel(w / 2, h / 2);
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
            Color pixel = image.GetPixel(x, y);
            if (pixel.A == 0) transparent++;
            if (pixel.A == 255) opaque++;
            minimumAlpha = Math.Min(minimumAlpha, pixel.A);
            maximumAlpha = Math.Max(maximumAlpha, pixel.A);
            if (icon && (x < 48 || x >= w - 48 || y < 48 || y >= h - 48) && pixel.A != 0) paddingErrors++;
            if (checkSlice && x >= cap && x < w - cap && y >= cap && y < h - cap && pixel.ToArgb() != center.ToArgb()) centerErrors++;
        }
        if (checkSlice) {
            for (int y = 0; y < cap; y++) for (int x = 0; x < cap; x++) {
                int pixel = image.GetPixel(x, y).ToArgb();
                if (image.GetPixel(w - 1 - x, y).ToArgb() != pixel) cornerErrors++;
                if (image.GetPixel(x, h - 1 - y).ToArgb() != pixel) cornerErrors++;
                if (image.GetPixel(w - 1 - x, h - 1 - y).ToArgb() != pixel) cornerErrors++;
            }
            for (int x = cap; x < w - cap; x++) for (int y = 0; y < cap; y++) {
                if (image.GetPixel(x, y).ToArgb() != image.GetPixel(w / 2, y).ToArgb()) edgeErrors++;
                if (image.GetPixel(x, h - 1 - y).ToArgb() != image.GetPixel(w / 2, h - 1 - y).ToArgb()) edgeErrors++;
            }
            for (int y = cap; y < h - cap; y++) for (int x = 0; x < cap; x++) {
                if (image.GetPixel(x, y).ToArgb() != image.GetPixel(x, h / 2).ToArgb()) edgeErrors++;
                if (image.GetPixel(w - 1 - x, y).ToArgb() != image.GetPixel(w - 1 - x, h / 2).ToArgb()) edgeErrors++;
            }
        }
        int[] result = new int[] {transparent, opaque, minimumAlpha, maximumAlpha, centerErrors, cornerErrors, edgeErrors, paddingErrors};
        if (logical != null) logical.Dispose();
        return result;
    }
}
'@
$root = $PSScriptRoot
$manifest = Get-Content -LiteralPath (Join-Path $root 'prompts.json') -Raw | ConvertFrom-Json
$results = @(); $errors = @()
foreach ($job in $manifest.jobs) {
    $required = $job.stage -eq 'trial' -or $job.theme -eq $SelectedTheme
    $path = Join-Path (Join-Path $root $job.theme) $job.file
    if (-not (Test-Path -LiteralPath $path)) {
        if ($RequireComplete -and $required) { $errors += "Missing $($job.theme)/$($job.file)" }
        continue
    }
    $image = [System.Drawing.Bitmap]::FromFile($path)
    $slice = $job.section -eq 1 -or ($job.section -eq 2 -and $job.file -ne 'button_close.png')
    $cap = if ($job.section -eq 1) { 64 } else { [Math]::Min(48, [int]($job.height / 2 - 1)) }
    $pressed = $job.file -match '^button_(main|blue|red)_pressed\.png$'
    $pixels = [MeteorUiValidation]::Pixels($image, $cap, $slice, ($job.section -eq 6), $pressed)
    if ($image.Width -ne $job.width -or $image.Height -ne $job.height) { $errors += "Dimensions $($job.theme)/$($job.file)" }
    if ($job.section -ne 8 -and $pixels[0] -eq 0) { $errors += "No transparent pixels $($job.theme)/$($job.file)" }
    if ($job.section -eq 8 -and $pixels[2] -ne 255) { $errors += "Loading background has transparency $($job.theme)/$($job.file)" }
    if ($pixels[7] -gt 0) { $errors += "Icon padding $($job.theme)/$($job.file)" }
    if ($slice -and ($pixels[4] + $pixels[5] + $pixels[6]) -gt 0) { $errors += "9-slice geometry $($job.theme)/$($job.file)" }
    $horizontalErrors = 0
    $cardOpeningErrors = if ($job.section -eq 5) { [MeteorUiValidation]::CardOpening($image) } else { 0 }
    if ($cardOpeningErrors -gt 0) { $errors += "Card opening is not transparent $($job.theme)/$($job.file)" }
    if ($job.section -eq 3 -or $job.section -eq 4) {
        $left = if ($job.section -eq 3) { 128 } elseif ($job.file -eq 'bar_back.png') { 32 } else { 0 }
        $right = if ($job.section -eq 3) { 64 } elseif ($job.file -eq 'bar_back.png') { 32 } else { 0 }
        $horizontalErrors = [MeteorUiValidation]::Horizontal($image, $left, $right)
        if ($horizontalErrors -gt 0) { $errors += "Horizontal repeat $($job.theme)/$($job.file)" }
    }
    $results += [ordered]@{
        theme = $job.theme; file = $job.file; width = $image.Width; height = $image.Height
        alphaMin = $pixels[2]; alphaMax = $pixels[3]; transparentPixels = $pixels[0]
        centerErrors = $pixels[4]; mirroredCornerErrors = $pixels[5]; repeatingEdgeErrors = $pixels[6]; paddingErrors = $pixels[7]
        horizontalRepeatErrors = $horizontalErrors
        cardOpeningErrors = $cardOpeningErrors
        pressedOffsetY = if ($pressed) { 2 } else { 0 }
        centerLuminance = [Math]::Round((0.2126 * $image.GetPixel([int]($image.Width / 2), [int]($image.Height / 2)).R + 0.7152 * $image.GetPixel([int]($image.Width / 2), [int]($image.Height / 2)).G + 0.0722 * $image.GetPixel([int]($image.Width / 2), [int]($image.Height / 2)).B), 3)
        sliceCenter = if ($slice) { $offset = if ($pressed) { 2 } else { 0 }; @($cap, ($cap + $offset), ($image.Width - $cap), ($image.Height - $cap + $offset)) } elseif ($job.section -eq 3) { @(128, 48, 448, 80) } elseif ($job.file -eq 'bar_back.png') { @(32, 24, 480, 40) } else { $null }
        sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $image.Dispose()
}
foreach ($theme in @('A', 'B')) {
    foreach ($kind in @('main', 'blue', 'red')) {
        $normal = $results | Where-Object { $_.theme -eq $theme -and $_.file -eq "button_$($kind)_normal.png" }
        $hover = $results | Where-Object { $_.theme -eq $theme -and $_.file -eq "button_$($kind)_hover.png" }
        $pressed = $results | Where-Object { $_.theme -eq $theme -and $_.file -eq "button_$($kind)_pressed.png" }
        if ($normal -and $hover -and $pressed) {
            if ($hover.centerLuminance -le $normal.centerLuminance) { $errors += "Hover must be brighter: $theme/button_$kind" }
            if ($pressed.centerLuminance -ge $normal.centerLuminance) { $errors += "Pressed must be darker: $theme/button_$kind" }
        }
    }
}
$report = [ordered]@{ selectedTheme = $SelectedTheme; checked = $results.Count; errors = @($errors); assets = @($results) }
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'validation.json') -Encoding UTF8
Write-Output "Checked $($results.Count) PNGs; errors: $($errors.Count)"
if ($errors.Count) { $errors | ForEach-Object { Write-Output $_ }; exit 1 }
