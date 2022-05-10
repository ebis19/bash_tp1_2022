<#
.SYNOPSIS
Este script emula el comportamiento del comando rm.
.DESCRIPTION
Este script al emular el comportamiento del comando rm, pero utilizando el concepto de “papelera de reciclaje”, es decir que, al borrar un archivo se tenga la posibilidad de recuperarlo en el futuro.
La papelera de reciclaje deberá ser un archivo comprimido ZIP y debe estar alojada en el home del usuario que ejecuta el comando, en caso de no encontrarse debe crearla
.EXAMPLE
.\ejercicio6.ps1 -listar                     lista los archivos que contiene la papelera de reciclaje, informando nombre de archivo y su ubicación original
.\ejercicio6.ps1 -recuperar [ARCHIVO]        recupera el archivo pasado por parámetro a su ubicación original.
.\ejercicio6.ps1 -vaciar                     vacía la papelera de reciclaje (eliminar definitivamente).
.\ejercicio6.ps1 -eliminar [ARCHIVO]         elimina el archivo (o sea, que lo envíe a la papelera de reciclaje)..
#>

[CmdletBinding()]
Param (
    [ValidateScript({Test-Path $_})]
    [ValidateNotNullOrEmpty()][String] $eliminar,
    [ValidateNotNullOrEmpty()][String] $recuperar,
    [switch] $vaciar,
    [switch] $listar   
) 

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$pathPapelera = "${HOME}/mi_papelera_powershell.zip"
#Write-Host $pathPapelera
$zip_exists = Test-Path $pathPapelera
if ($zip_exists -eq $False) {
    $zip = [System.IO.Compression.ZipFile]::Open($pathPapelera, 'create')
    $zip.Dispose()
    #Write-Host "zip creado"
}

if ($listar) {
    #Write-Host "listar"

    $stream = New-Object IO.FileStream($pathPapelera, [IO.FileMode]::Open)
    $mode   = [IO.Compression.ZipArchiveMode]::Update
    $zip    = New-Object IO.Compression.ZipArchive($stream, $mode)

    $Archivos = $zip.Entries

    # Crea un array donde guardará la información de cada archivo
    $ObjArray = @()
    
    # Guarda la información de cada archivo dentro del .zip en el array declarado previamente
    foreach($x in $Archivos)
    {            
        #Write-Host $x
        # Testea que se trate de un archivo, y no de un directorio (que no termine con '/')
        if (-Not ($Archivo.FullName -match '\/$'))
        {
            $Objeto = New-Object -TypeName PSObject            
            $Objeto | Add-Member -MemberType NoteProperty -Name 'Nombre del Archivo' -Value $x.Name            
            $Objeto | Add-Member -MemberType NoteProperty -Name 'Ubicacion del Archivo' -Value (Split-Path -Path $x)            
            $ObjArray += $Objeto 
        }
    }
    
    # Muestra por pantalla
    Write-Host ($ObjArray | Format-Table | Out-String)

    $zip.Dispose()
    $stream.Close()
    $stream.Dispose()
    Exit
} 
elseif ($vaciar) {
    #Write-Host "borrar definitivamente"

    $stream = New-Object IO.FileStream($pathPapelera, [IO.FileMode]::Open)
    $mode   = [IO.Compression.ZipArchiveMode]::Update
    $zip    = New-Object IO.Compression.ZipArchive($stream, $mode)

    $entries = [System.Collections.ArrayList]@()

    $zip.Entries | ForEach-Object { 
        $entry = $zip.GetEntry($_.FullName)
        $entries.Add($entry)
    } | Out-Null

    foreach ($item in $entries) {
        $item.Delete()
    }

    $zip.Dispose()
    $stream.Close()
    $stream.Dispose()

    #Write-Host "borrados"
    Exit
}
elseif ($eliminar) {
    #Write-Host "borrar un archivo"
    [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    $mode   = [IO.Compression.ZipArchiveMode]::Update
    $zip = [System.IO.Compression.ZipFile]::Open($pathPapelera,$mode)

    $zentry = $zip.CreateEntry($eliminar)
    $zentryWriter = New-Object -TypeName System.IO.BinaryWriter $zentry.Open()
    $zentryWriter.Write([System.IO.File]::ReadAllBytes($eliminar))
    $zentryWriter.Flush()
    $zentryWriter.Close()

    $zip.Dispose()
    Remove-Item -Path $eliminar
    #Write-Host "archivo borrado"
    Exit
}

if ($recuperar) { 
    #Write-Host "recuperar"
    #Write-Host $recuperar

    $stream = New-Object IO.FileStream($pathPapelera, [IO.FileMode]::Open)
    $mode   = [IO.Compression.ZipArchiveMode]::Update
    $zip    = New-Object IO.Compression.ZipArchive($stream, $mode)

    $cantidad = @($zip.Entries | Where-Object { $_.Name -eq $recuperar }).Count
    #Write-Host "cantidad" $cantidad
    if ($cantidad -eq 0){
        Exit
    }
    elseif ($cantidad -eq 1) {
        #Write-Host "recupero el que es unico"
        $uniquefile = @($zip.Entries | Where-Object { $_.Name -eq $recuperar })[0]
        #Write-Host $uniquefile
        $OutPath = @(Split-Path -Path $uniquefile) 
        #Write-Host $OutPath

        $zip.Entries | 
        Where-Object { $_.Name -eq $recuperar } |
        ForEach-Object { 
            $FileName = $_.Name
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$OutPath/$FileName", $true)
        }

        $item = @($zip.Entries | Where-Object { $_.Name -eq $recuperar })[0]
        #Write-Host $item
        $item.Delete()
    }
    else {
        #Write-Host "elijo cual recupero"

        $index = 1

        # Crea un array donde guardará la información de cada archivo
        $ObjArray = @()
        # Guarda la información de cada archivo dentro del .zip en el array declarado previamente
        foreach($z in $zip.Entries)
        {            
            # Testea que se trate de un archivo, y no de un directorio (que no termine con '/')
            if (-Not ($z.FullName -match '\/$'))
            {
                $Objeto = New-Object -TypeName PSObject            
                $Objeto | Add-Member -MemberType NoteProperty -Name 'nombre archivo' -Value "$($index) - $($z.Name)"             
                $Objeto | Add-Member -MemberType NoteProperty -Name 'ubicacion' -Value (Split-Path -Path $z)            
                $ObjArray += $Objeto 
                $index += 1
            }
        }
        Write-Host ($ObjArray | Format-Table -HideTableHeaders | Out-String)

        $numero = Read-Host "¿Que archivo desea recuperar?"
        #Write-Host $numero

        if($numero -match "^\d+$") {
            #Write-host "It's a number"
            $file = @($zip.Entries | Where-Object { $_.Name -eq $recuperar })[$numero-1]
            #Write-Host $file
            $OutPath = @(Split-Path -Path $file) 
            #Write-Host $OutPath

            $zip.Entries | 
            Where-Object { $_.FullName -eq $file } |
            ForEach-Object { 
                $FileName = $_.Name
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$OutPath/$FileName", $true)
            }

            $item = @($zip.Entries | Where-Object { $_.FullName -eq $file })[0]
            #Write-Host $item
            $item.Delete()
        }
    }

    $zip.Dispose()
    $stream.Close()
    $stream.Dispose()
    #Write-Host "recuperado"
    Exit
}