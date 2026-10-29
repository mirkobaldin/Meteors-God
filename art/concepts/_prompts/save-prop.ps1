param([Parameter(Mandatory=$true)][string]$Source,[Parameter(Mandatory=$true)][string]$Name)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$destination = Join-Path (Split-Path $PSScriptRoot -Parent) "props/$Name.png"
$image = [System.Drawing.Bitmap]::FromFile($Source)
$output = New-Object System.Drawing.Bitmap 1024,1024,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($output)
try {
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($image,(New-Object System.Drawing.Rectangle 0,0,1024,1024),0,0,$image.Width,$image.Height,[System.Drawing.GraphicsUnit]::Pixel)
    $output.Save($destination,[System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "Saved $Name.png (1024x1024, RGBA)"
} finally {
    $graphics.Dispose()
    $output.Dispose()
    $image.Dispose()
}
