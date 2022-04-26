#!/bin/bash

function ayuda() {
	echo "Este script sirve para emular el comportamiento del comando rm"
	echo "El script tendrá las siguientes opciones: "
    echo "        \"$0 --listar\"                  lista los archivos que contiene la papelera de reciclaje, informando nombre de archivo y su ubicación original."
    echo "        \"$0 --recuperar [ARCHIVO]\"     recupera el archivo pasado por parámetro a su ubicación original."
    echo "        \"$0 --vaciar\"                  vacía la papelera de reciclaje (eliminar definitivamente)."
    echo "        \"$0 --eliminar [ARCHIVO]\"      elimina el archivo (o sea, que lo envíe a la papelera de reciclaje)."
}

pathPapelera="${HOME}/mi_papelera.zip"

listar () {
    declare -i cantArchivos=$(zipinfo "$pathPapelera" | grep ^-| wc -l)
    [ $cantArchivos == 0 ] && exit
    lista="Nombre_del_Archivo\tUbicación_Original\n---------------------------- --------------------------------------------------------"

    OLD_IFS="$IFS"
    IFS=$'\n'
    array=($(unzip -Z -1 $pathPapelera))
    IFS="$OLD_IFS"

    for I in `seq 0 1 $((${#array[*]}-1))`; do
        #echo ${array[$I]}
        file="${array[$I]}"
        file_name="${file##*/}"
        file_path="${file%/*}/"
        #echo $file_name
        #echo $file_path
        lista="$lista\n${file_name}\t\t${file_path}"
    done
    echo -e $lista #| column -t
}

recuperar () {
    declare -i cantArchivos=$(zipinfo -1 "$pathPapelera" | grep "$1" | wc -l)
    [ -z $cantArchivos ] && exit

    if [ $cantArchivos == 1 ]
    then
        pathMover=$(zipinfo -1 $pathPapelera | grep "$1")

        unzip -p "$pathPapelera" > "$pathMover"

        # borra el archivo del zip
        zip -d "$pathPapelera" "./$pathMover"

        echo "Archivo restaurado exitosamente."
    elif [ $cantArchivos -gt 0 ]
    then
        #echo "mas de uno"
        sum=1
        # for file in $(zipinfo -1 $pathPapelera | grep "$1")
        # do
        #     file_name="${file##*/}"
        #     file_path="${file%/*}/"
        #     lista="$lista\n${sum} ${file_name} ${file_path}\n"
        #     sum=$((${sum} + 1))
        # done
        # echo -e $lista | column -t

        OLD_IFS="$IFS"
        IFS=$'\n'
        array=($(unzip -Z -1 $pathPapelera))
        IFS="$OLD_IFS"

        for I in `seq 0 1 $((${#array[*]}-1))`; do
            #echo ${array[$I]}
            file="${array[$I]}"
            file_name="${file##*/}"
            file_path="${file%/*}/"
            #echo $file_name
            #echo $file_path
            lista="$lista\n${sum}\t${file_name}\t${file_path}"
            sum=$((${sum} + 1))
        done
        echo -e $lista #| column -t

        read -p "¿Qué archivo desea recuperar? " -n 1 -r
        echo 
        if [[ $REPLY =~ ^-?[0-9]+$ ]]
        then
            #array=($(zipinfo -1 $pathPapelera | grep "$1"))
            
            recuperar="${array[$((${REPLY} - 1))]}"

            unzip -p "$pathPapelera" "$recuperar" >"$recuperar"

            # borra el archivo del zip
            zip -d "$pathPapelera" "./$recuperar"

            echo "Archivo restaurado exitosamente."
        fi
    fi
}

vaciar () {
    declare -i cantArchivos=$(unzip -Z1 "$pathPapelera" | wc -l)
    [ -z $cantArchivos ] && exit
    read -p "¿Desea eliminar $cantArchivos archivos? [s/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]
    then
        zip --delete "$pathPapelera" "*" 2> /dev/null
        echo "Archivo/s eliminado/s exitosamente."
    fi
}

eliminar () {
    zip "$pathPapelera" "$1"
    rm "$1"
    echo "Archivo eliminado exitosamente."
}

if [[ $# -gt 0 ]]; then
    while [[ "$#" -gt 0 ]]
    do
        case "$1" in
            -h|--help|-?)
                ayuda
                exit 1
            ;;
            --listar)
                listar
                exit 1
            ;;
            --recuperar)
                recuperar "$2"
                exit 1
            ;;
            --vaciar)
                vaciar
                exit 1
            ;;
            --eliminar)
                eliminar "$2"
                exit 1
            ;;
            *)
                echo "ERROR!!! La opción ingresada no esta disponible."
                exit 0
            ;;
        esac
    done
else
    echo "Cantidad de párametros inválida. Para recibir ayuda sobre la utilización de este script use \"$0 -h\" ó \"$0 --help\" ó \"$0 -?\""
fi