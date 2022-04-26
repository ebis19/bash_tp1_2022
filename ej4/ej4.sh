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
#--dir ARCHIVO: Se solicita la salida a un archivo, caso contrario se muestra por pantalla
#como cualquier comando. Debe estar formateada para ser legible y estética.
#--help: muestra la ayuda del script.

#Parseo los parametros

usage(){
    echo "Uso: $0 [OPCIONES]" ;
    echo "Opciones:"
    echo "--ext: ruta al archivo de configuración que posee el listado de extensiones de archivos a"
    echo "analizar, será un archivo de texto plano con las extensiones separadas por ; (punto y coma)."
    echo "Ejemplo: sh;cs;js;css"
    echo "--coment : toma en cuenta las líneas comentadas en la comparación (estas comienzan por //"
    echo "o #)•"
    echo "--sincom: no toma en cuenta los comentarios."
    echo "Estos dos parámetros son excluyentes, no pueden estar juntos en una llamada al script."
    echo "--porc [NÚMERO ENTERO]: si la similitud entre archivos es mayor o igual al número pasado"
    echo "se informan, sino se desestiman."
    echo "--salida ARCHIVO: Archivo de salida"
    echo "--dir ARCHIVO: Directorio de salida"
    echo "--help: muestra la ayuda del script."
    echo "--porc [NÚMERO ENTERO]: si la similitud entre archivos es mayor o igual al número pasado"
    echo "Ejemplo: $0  --dir=test --ext=extensiones.txt --porc=50 --salida=salida.txt"
    echo "Ejemplo: $0  --dir test --ext ./extensiones/extensiones.txt --porc=50 --salida=salida.txt"
    exit 1;
}
coment=0
sincom=0
HELP=0
# #Seteo los parametros
PARSED_ARGUMENTS=$(getopt -a -o hp: --long help,dir:,porc:,coment,sincom,ext:,salida:: -- "$@")
result=$?
if [ "$result" != "0" ]; then
 	usage
fi
eval set -- "$PARSED_ARGUMENTS"
while true;
do
 	case "$1" in
 		-h | --help) HELP=1 ; shift ;;
 		--ext ) extensiones=$2 ; shift 2;;
 		--coment ) coment=1 ; shift ;;
 		--sincom ) sincom=1 ; shift  ;;
 		-p | --porc) porc=$2; shift 2 ;;
        --salida) salida=$2 ; shift 2 ;;
        --dir ) directorio=$2; shift 2 ;;
        --) shift; break ;;
 		*) echo "Unexpected option: $1 - this should not happen."
          			usage;;
 	esac
done

validaciones (){
if [ $HELP -eq 1 ]
then
       usage        
fi

if [ $coment -eq 0 ] && [ $sincom -eq 0 ]
then
    echo "debe tener solo una de las dos siguientes opciones --coment o --sincom"
    usage
fi

if [ $coment -eq 1 ] && [ $sincom -eq 1 ]
then
    echo "No puede haber parámetros excluyentes --coment y --sincom"
    usage
fi

if [ -z $extensiones ]
then
    echo "No se pasaron extensiones"
    usage
fi

echo $directorio
if [ -z $directorio ]
then
    echo "No se paso directorio"
    usage
fi

if [ -z $porc ]
then
    echo "No se paso el porcentaje"
    usage
fi
}

comprobar_diferencias_entre_archivos(){
            cant_linea_archivo1=$(cat $1  | wc -l)
            cant_diff_a1toa2=$(diff  -d  $1 $2  | grep ">" | wc -l)
            cant_diff_a2toa1=$(diff  -d  $2 $1  | grep "<" | wc -l)
            if [ $coment -eq 0 ] 
            then
                cant_linea_archivo1=$(cat $1 | grep  -v "#" | grep  -v "^//" | wc -l)
                cant_diff_a1toa2=$(diff  -d  $1 $2 | grep ">" | grep  -v "^#" | grep  -v "^//" | wc -l)
                cant_diff_a2toa1=$(diff  -d  $1 $2 | grep "<" | grep  -v "^#" | grep  -v "^//" | wc -l)
            fi
            if [ $cant_diff_a1toa2 -gt $cant_diff_a2toa1 ]
            then
                cant_diff=$cant_diff_a1toa2
            else
                cant_diff=$cant_diff_a2toa1
            fi
            porcentaje=$(echo "scale=2;($cant_diff)/$cant_linea_archivo1*100" | bc)
            porcentaje=$(echo "scale=2; 100-$porcentaje" | bc)
            result=$(echo "$porcentaje > $porc" | bc -l)
            if [ $result -eq 1 ]
            then
                
                if [ -z $salida ]
                then
                    echo "Archivo $1 y $2 tienen similitud de $porcentaje%"
                else
                    echo "Archivo $1 y $2 tienen similitud de $porcentaje%" >> $salida
                fi
                
            fi
}

# comprobar diferencias entre archivos de la misma extencion
# comprobar_diferencia [extencion]
comprobar_diferencias(){
    archivos=$(find $directorio -iname "*.$1" -type f -print | awk '{print $0 }' )
    for arch1 in $archivos
    do
        for arch2 in $archivos
        do
            if  [ "$arch1" = "" ]
            then
                continue
        fi
        if [ "$arch1" != "$arch2" ]
        then
            comprobar_diferencias_entre_archivos "$arch1" "$arch2"
        fi  
    done
done
}


validaciones

extensiones=$(cat $extensiones| tr ";" "\n") #separo las extensiones
for ext in $extensiones
do
    echo "Analizando archivos con extencion $ext"
    comprobar_diferencias $ext
done
