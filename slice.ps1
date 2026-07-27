Add-Type -AssemblyName System.Drawing
$imgPath = 'C:\Users\secre\.gemini\antigravity\brain\695ebd3a-7b9d-4950-932c-eb0552884d16\.user_uploaded\media__1784928777416.png'
$img = [System.Drawing.Image]::FromFile($imgPath)
$w = $img.Width / 2
$h = $img.Height / 2

$bmp1 = New-Object System.Drawing.Bitmap([int]$w, [int]$h)
$g1 = [System.Drawing.Graphics]::FromImage($bmp1)
$g1.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
$bmp1.Save('assets\mascot\poses\front.png', [System.Drawing.Imaging.ImageFormat]::Png)

$bmp2 = New-Object System.Drawing.Bitmap([int]$w, [int]$h)
$g2 = [System.Drawing.Graphics]::FromImage($bmp2)
$g2.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), (New-Object System.Drawing.Rectangle($w, 0, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
$bmp2.Save('assets\mascot\poses\side.png', [System.Drawing.Imaging.ImageFormat]::Png)

$bmp3 = New-Object System.Drawing.Bitmap([int]$w, [int]$h)
$g3 = [System.Drawing.Graphics]::FromImage($bmp3)
$g3.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), (New-Object System.Drawing.Rectangle(0, $h, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
$bmp3.Save('assets\mascot\poses\front_right.png', [System.Drawing.Imaging.ImageFormat]::Png)

$bmp4 = New-Object System.Drawing.Bitmap([int]$w, [int]$h)
$g4 = [System.Drawing.Graphics]::FromImage($bmp4)
$g4.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), (New-Object System.Drawing.Rectangle($w, $h, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
$bmp4.Save('assets\mascot\poses\back.png', [System.Drawing.Imaging.ImageFormat]::Png)

$img.Dispose()
$bmp1.Dispose()
$bmp2.Dispose()
$bmp3.Dispose()
$bmp4.Dispose()
