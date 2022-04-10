#!/bin/bash
#leer parametros
#parametros:
#   -d: nombre del directorio de entrada donde se encuentran los archivos
#   -h: ayuda
#   -e: Sucursal excluida (opcional)
#   -o: directorio de salida (opcional)

while getopts  d:o:h opt;do
    case $opt in
        d)
            directorio=$OPTARG
            ;;
        o)
            output=$OPTARG
            ;;
        h)
            echo "Uso: $0 -d nombre_directorio -o nombre_directorio_salida"
            exit 0
            ;;
        \?)
            echo "Uso: $0 -d nombre_directorio -o nombre_directorio_salida"
            exit 1
            ;;
    esac
done

#csv to json
productos=$(find $directorio -name "*.csv" -exec cat {} \; | awk '{print $1}' | sed '1d' | awk -F "," 'BEGIN{OFS=",";} {arr[$1]+=$2} END {for (i in arr) {print i,arr[i]}}')
productos_json=$(echo $productos | #convertir a json
        sed 's/,/:/g' | #reemplazar comas por dos puntos
        sed 's/ /, /g' | #remplazar espacios por comas
        sed 's/^/{/g' | #agregar corchetes
        sed 's/$/}/g') #agregar corchetes

echo $productos_json > $output/productos.json