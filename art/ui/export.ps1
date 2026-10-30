param([switch]$PreviewOnly, [string]$Only)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
# Mechanical 9-slice assembly: generated corner art is fitted into the requested
# cap width, mirrored exactly, and joined with repeated midpoint border pixels.
# This prevents model-generated center shading and edge ornament from stretching.
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class MeteorUiExport {
    public static void CleanAlphaNoise(Bitmap image) {
        for (int y = 0; y < image.Height; y++)
            for (int x = 0; x < image.Width; x++)
                if (image.GetPixel(x, y).A == 1) image.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
    }
    public static Bitmap Horizontal(Bitmap input, int left, int right, int inset) {
        Bitmap output = input.Clone(new Rectangle(0, 0, input.Width, input.Height), PixelFormat.Format32bppArgb);
        Color center = input.GetPixel(input.Width / 2, input.Height / 2);
        for (int x = left; x < input.Width - right; x++)
            for (int y = 0; y < input.Height; y++) {
                Color pixel = inset > 0 && y >= inset && y < input.Height - inset ? center : input.GetPixel(input.Width / 2, y);
                output.SetPixel(x, y, pixel);
            }
        return output;
    }
    public static Bitmap Slice(Bitmap input, int cap, Color center, bool banner) {
        int w = input.Width, h = input.Height;
        Bitmap output = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(output)) {
            g.CompositingMode = CompositingMode.SourceCopy;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            using (SolidBrush fill = new SolidBrush(center))
                g.FillRectangle(fill, cap, cap, w - 2 * cap, h - 2 * cap);
            if (banner) {
                int side = Math.Min(w / 4, Math.Max(cap, h / 2));
                g.DrawImage(input, new Rectangle(0, 0, cap, h), new Rectangle(0, 0, side, h), GraphicsUnit.Pixel);
                for (int y = 0; y < h / 2; y++)
                    for (int x = 0; x < cap; x++)
                        output.SetPixel(x, h - 1 - y, output.GetPixel(x, y));
                for (int y = cap; y < h - cap; y++)
                    for (int x = 0; x < cap; x++)
                        output.SetPixel(x, y, output.GetPixel(x, h / 2));
                using (Bitmap right = output.Clone(new Rectangle(0, 0, cap, h), PixelFormat.Format32bppArgb)) {
                    right.RotateFlip(RotateFlipType.RotateNoneFlipX);
                    g.DrawImageUnscaled(right, w - cap, 0);
                }
                for (int y = 0; y < h; y++)
                    for (int x = 0; x < cap; x++)
                        output.SetPixel(w - 1 - x, y, output.GetPixel(x, y));
                for (int x = cap; x < w - cap; x++)
                    for (int y = 0; y < cap; y++) {
                        output.SetPixel(x, y, input.GetPixel(w / 2, y));
                        output.SetPixel(x, h - 1 - y, input.GetPixel(w / 2, y));
                    }
            } else {
                int sourceCap = Math.Min(Math.Min(w, h) / 2 - 1, Math.Max(cap, (int)(Math.Min(w, h) * .1875)));
                using (Bitmap corner = new Bitmap(cap, cap, PixelFormat.Format32bppArgb)) {
                    using (Graphics cg = Graphics.FromImage(corner)) {
                        cg.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        cg.DrawImage(input, new Rectangle(0, 0, cap, cap), new Rectangle(0, 0, sourceCap, sourceCap), GraphicsUnit.Pixel);
                    }
                    g.DrawImageUnscaled(corner, 0, 0);
                    corner.RotateFlip(RotateFlipType.RotateNoneFlipX);
                    g.DrawImageUnscaled(corner, w - cap, 0);
                    corner.RotateFlip(RotateFlipType.RotateNoneFlipY);
                    g.DrawImageUnscaled(corner, w - cap, h - cap);
                    corner.RotateFlip(RotateFlipType.RotateNoneFlipX);
                    g.DrawImageUnscaled(corner, 0, h - cap);
                }
                using (Bitmap top = new Bitmap(1, cap, PixelFormat.Format32bppArgb))
                using (Bitmap left = new Bitmap(cap, 1, PixelFormat.Format32bppArgb)) {
                    using (Graphics tg = Graphics.FromImage(top))
                        tg.DrawImage(input, new Rectangle(0, 0, 1, cap), new Rectangle(w / 2, 0, 1, sourceCap), GraphicsUnit.Pixel);
                    using (Graphics lg = Graphics.FromImage(left))
                        lg.DrawImage(input, new Rectangle(0, 0, cap, 1), new Rectangle(0, h / 2, sourceCap, 1), GraphicsUnit.Pixel);
                    for (int x = cap; x < w - cap; x++)
                        for (int y = 0; y < cap; y++) {
                            output.SetPixel(x, y, top.GetPixel(0, y));
                            output.SetPixel(x, h - 1 - y, top.GetPixel(0, y));
                        }
                    for (int y = cap; y < h - cap; y++)
                        for (int x = 0; x < cap; x++) {
                            output.SetPixel(x, y, left.GetPixel(x, 0));
                            output.SetPixel(w - 1 - x, y, left.GetPixel(x, 0));
                        }
                }
            }
        }
        return output;
    }
}
'@
$root = $PSScriptRoot
$manifest = Get-Content -LiteralPath (Join-Path $root 'prompts.json') -Raw | ConvertFrom-Json
function New-Canvas([int]$width, [int]$height) {
    return [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}
function Draw-Region($graphics, $image, $destination, $source) {
    $graphics.DrawImage($image, $destination, $source.X, $source.Y, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel)
}
if (-not $PreviewOnly) {
    foreach ($job in $manifest.jobs) {
        if ($job.status -ne 'generated') { continue }
        if ($Only -and "$($job.theme)/$($job.file)" -ne $Only) { continue }
        $folder = Join-Path $root $job.theme
        [void][System.IO.Directory]::CreateDirectory($folder)
        $destination = Join-Path $folder $job.file
        $source = [System.Drawing.Image]::FromFile($job.source)
        $image = New-Canvas $job.width $job.height
        $graphics = [System.Drawing.Graphics]::FromImage($image)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $target = if ($job.section -eq 6) { [System.Drawing.Rectangle]::new(48, 48, 416, 416) } else { [System.Drawing.Rectangle]::new(0, 0, $job.width, $job.height) }
        if ($job.section -eq 8) {
            $graphics.Clear([System.Drawing.Color]::FromArgb(255, 16, 20, 38))
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
            $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
            $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
            $graphics.DrawImage($source, $target, 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
            $attributes.Dispose()
        } else {
            $graphics.DrawImage($source, $target)
        }
        $graphics.Dispose()
        $source.Dispose()
        if ($job.section -eq 5) { [MeteorUiExport]::CleanAlphaNoise($image) }
        if ($job.section -eq 1 -or ($job.section -eq 2 -and $job.file -ne 'button_close.png')) {
            $cap = if ($job.section -eq 1) { 64 } else { [Math]::Min(48, [int]($job.height / 2 - 1)) }
            $center = if ($job.theme -eq 'A') { [System.Drawing.Color]::FromArgb(255, 28, 34, 54) } else { [System.Drawing.Color]::FromArgb(217, 16, 20, 38) }
            if ($job.section -eq 2) { $center = $image.GetPixel([int]($job.width / 2), [int]($job.height / 2)) }
            $sliced = [MeteorUiExport]::Slice($image, $cap, $center, ($job.file -eq 'frame_banner.png'))
            $image.Dispose(); $image = $sliced
        }
        if ($job.section -eq 3 -or $job.section -eq 4) {
            $left = if ($job.section -eq 3) { 128 } elseif ($job.file -eq 'bar_back.png') { 32 } else { 0 }
            $right = if ($job.section -eq 3) { 64 } elseif ($job.file -eq 'bar_back.png') { 32 } else { 0 }
            $inset = if ($job.section -eq 3) { 48 } else { 0 }
            $sliced = [MeteorUiExport]::Horizontal($image, $left, $right, $inset)
            $image.Dispose(); $image = $sliced
        }
        if ($job.file -match '^button_(main|blue|red)_pressed\.png$') {
            $shifted = New-Canvas $job.width $job.height
            $shiftGraphics = [System.Drawing.Graphics]::FromImage($shifted)
            $shiftGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $shiftGraphics.DrawImageUnscaled($image, 0, 2)
            $shiftGraphics.Dispose(); $image.Dispose(); $image = $shifted
        }
        $image.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        $image.Dispose()
        Write-Output "$($job.theme)/$($job.file) $($job.width)x$($job.height)"
    }
}
# Review sheets are separate from importable assets; labels never enter game PNGs.
$review = Join-Path $root '_review'
[void][System.IO.Directory]::CreateDirectory($review)
foreach ($theme in @('A', 'B')) {
    $jobs = @($manifest.jobs | Where-Object { $_.theme -eq $theme -and (Test-Path -LiteralPath (Join-Path (Join-Path $root $theme) $_.file)) })
    if (-not $jobs.Count) { continue }
    $columns = 6; $cellWidth = 200; $cellHeight = 190
    $rows = [int][Math]::Ceiling($jobs.Count / $columns)
    $sheet = New-Canvas ($columns * $cellWidth) ($rows * $cellHeight)
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(255, 25, 29, 45))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $font = [System.Drawing.Font]::new('Arial', 10)
    for ($index = 0; $index -lt $jobs.Count; $index++) {
        $job = $jobs[$index]
        $icon = [System.Drawing.Image]::FromFile((Join-Path (Join-Path $root $theme) $job.file))
        $scale = [Math]::Min(174.0 / $icon.Width, 150.0 / $icon.Height)
        $w = [int]($icon.Width * $scale); $h = [int]($icon.Height * $scale)
        $x = ($index % $columns) * $cellWidth; $y = [Math]::Floor($index / $columns) * $cellHeight
        $g.DrawImage($icon, [System.Drawing.Rectangle]::new([int]($x + ($cellWidth - $w) / 2), [int]($y + (155 - $h) / 2), $w, $h))
        $g.DrawString($job.file, $font, [System.Drawing.Brushes]::White, [single]($x + 5), [single]($y + 163))
        $icon.Dispose()
    }
    $font.Dispose(); $g.Dispose()
    $sheet.Save((Join-Path $review "$theme.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $sheet.Dispose()
    $icons = @($jobs | Where-Object { $_.section -eq 6 })
    if ($icons.Count) {
        $iconColumns = 7; $iconCellWidth = 96; $iconCellHeight = 84
        $iconRows = [int][Math]::Ceiling($icons.Count / $iconColumns)
        $small = New-Canvas ($iconColumns * $iconCellWidth) ($iconRows * $iconCellHeight)
        $sg = [System.Drawing.Graphics]::FromImage($small)
        $sg.Clear([System.Drawing.Color]::FromArgb(255, 25, 29, 45))
        $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $smallFont = [System.Drawing.Font]::new('Arial', 9)
        for ($index = 0; $index -lt $icons.Count; $index++) {
            $job = $icons[$index]
            $icon = [System.Drawing.Image]::FromFile((Join-Path (Join-Path $root $theme) $job.file))
            $x = ($index % $iconColumns) * $iconCellWidth; $y = [Math]::Floor($index / $iconColumns) * $iconCellHeight
            $sg.DrawImage($icon, [System.Drawing.Rectangle]::new([int]($x + 24), [int]($y + 2), 48, 48))
            $sg.DrawString(($job.file -replace '^icon_|\.png$', ''), $smallFont, [System.Drawing.Brushes]::White, [single]($x + 3), [single]($y + 57))
            $icon.Dispose()
        }
        $smallFont.Dispose(); $sg.Dispose()
        $small.Save((Join-Path $review "$($theme)_icons48.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $small.Dispose()
    }
}
$selectedTheme = if ($manifest.selectedTheme) { $manifest.selectedTheme } else { 'A' }
$requiredJobs = @($manifest.jobs | Where-Object { $_.stage -eq 'trial' -or $_.theme -eq $selectedTheme })
$presentJobs = @($requiredJobs | Where-Object { Test-Path -LiteralPath (Join-Path (Join-Path $root $_.theme) $_.file) })
$missing = [ordered]@{}
foreach ($theme in @('A', 'B')) {
    $missing[$theme] = @($requiredJobs | Where-Object { $_.theme -eq $theme -and -not (Test-Path -LiteralPath (Join-Path (Join-Path $root $_.theme) $_.file)) } | ForEach-Object { $_.file })
}
$status = [ordered]@{
    selectedTheme = $selectedTheme
    complete = $presentJobs.Count -eq $requiredJobs.Count
    tool = 'built-in image_gen'
    trialGenerated = @($presentJobs | Where-Object { $_.stage -eq 'trial' }).Count
    trialExpected = @($requiredJobs | Where-Object { $_.stage -eq 'trial' }).Count
    selectedGenerated = @($presentJobs | Where-Object { $_.theme -eq $selectedTheme }).Count
    selectedExpected = @($requiredJobs | Where-Object { $_.theme -eq $selectedTheme }).Count
    remainingRequired = $requiredJobs.Count - $presentJobs.Count
    missing = $missing
}
$status | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'status.json') -Encoding UTF8
