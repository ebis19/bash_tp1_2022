#!/bin/bash
#leer parametros
#parámetros que puede recibir el script son:
#--ext: ruta al archivo de configuración que posee el listado de extensiones de archivos a
#analizar, será un archivo de texto plano con las extensiones separadas por ; (punto y coma).
#Ejemplo: sh;cs;js;css
#--coment : toma en cuenta las líneas comentadas en la comparación (estas comienzan por //
#o #)•
#--sincom: no toma en cuenta los comentarios.
#Estos dos parámetros son excluyentes, no pueden estar juntos en una llamada al script.
#--porc [NÚMERO ENTERO]: si la similitud entre archivos es mayor o igual al número pasado
#se informan, sino se desestiman.
#--salida ARCHIVO: Se solicita la salida a un archivo, caso contrario se muestra por pantalla
#como cualquier comando. Debe estar formateada para ser legible y estética.
#--help: muestra la ayuda del script.

porc=50
directorio="."
salida="./salida.txt"
extension="c"
archivos=$(find ./ -iname "*.$extension" -type f -print)
for arch1 in $archivos
do
    for arch2 in $archivos
    do
        if  [ $arch1 = "" ]
        then
            continue
        fi
        if [ "$arch1" != "$arch2" ]
        then
            cant_linea_archivo1=$(cat $arch1 | wc -l)
            cant=$(grep -F -x -f $arch1 $arch2 | wc -l)
            echo "$arch1 $arch2 $cant $cant_linea_archivo1"
            porcentaje=$(echo "scale=0; $cant*100/($cant_linea_archivo1+1)" | bc -l)
            if  [ $porcentaje -ge $porc ]
            then
                echo "El archivo $arch1 y $arch2 son $porcentaje similares"
            fi
        fi
       
    done
done