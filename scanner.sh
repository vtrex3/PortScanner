#!/bin/bash
clear
echo -e "\e[0;32mBienvenido al escaneador de puertos\e[0m"
echo "Autor: Armando Elorriaga"
now=$(date)
echo "$now"
echo "---------------------------------"
echo ""
read -p "`echo $'\n' `Introduce IP o dominio de destino: " ip
read -p "`echo $'\n' `Puerto de inicio (default 1): " p_ini
read -p "`echo $'\n' `Puerto de fin (default 65535): " p_fin

#Funcion de escaneo de puerto de la ip solicitada
#$1 ip, $2 puerto inicial, $3 puerto final
scan(){
        array_open=()
        for (( i=$2; i<=$3; i++ ))
        do
                abierto=false
                timeout 1 bash -c "</dev/tcp/$1/$i" && abierto=true || abierto=false
                if [ $abierto = true ] ; then
                        echo -e  "       \e[0;32m[+] $i\e[0m -- puerto abierto"

                        #Guardamos en el array
                        elemento="$1;$i;open"
                        array_open+=($elemento)
                fi

        done
        #echo "${array_open[@]}"
        #echo "${array_open[0]}"

        printf "%s\n" "${array_open[@]}" > $ip.txt
}


#Funcion que comprueba que los puerto que tenemos son numeros
#Si son vacio seteamos default
check_isnumber(){
        re='^[0-9]+$'
        if ! [[ -z $1 ]] && ! [[ $1 =~ $re ]] ; then
                echo -e "       \e[01;31mError: El puerto inicial introducido no es numero\e[0m" >&2; exit 1
        fi
        if ! [[ -z $2 ]] && ! [[ $2 =~ $re ]] ; then
                echo -e "       \e[01;31mError: El puerto final introducido no es numero\e[0m" >&2; exit 1
        fi

        if [ -z $1 ] || [ $1 -lt 1 ]; then
                p_ini=1
        fi
        if [ -z $2 ] || [ $2 -gt 65535 ]; then
                p_fin=65535
        fi

        #echo $p_ini
        #echo $p_fin
}



#Comprobamos que sea un dominio o ip valido
check_validateDomain_IP(){
        echo -e "       \e[0;32m[*]\e[0mComprobando si \e[0;32m$ip\e[0m es una ip o dominio valido, por favor espere..."
        #primero obtenemos la ip por si es un dominio lo que nos pasan
        local ip_aux=$(ping -c 1 $1 | gawk -F'[()]' '/PING/{print $2}')
        echo -e "       \e[0;32m[*]IP detectada: $ip_aux\e[0m"
        #echo $i

        local  stat=1
        if [[ $ip_aux =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
        then
                OIFS=$IFS
                IFS='.'
                ip_aux2=($ip_aux)
                IFS=$OIFS
                [[ ${ip_aux2[0]} -le 255 && ${ip_aux2[1]} -le 255 && ${ip_aux2[2]} -le 255 && ${ip_aux2[3]} -le 255 ]]
                stat=$?
        fi
        return $stat
}



#Funcion de ejecucion del scaneo segun casuistica
execute_scan(){

        if [ -z "$p_ini" ] || [ -z "&p_fin" ] || [ -z "$ip" ];
        then
                echo -e "       \e[01;31mIP o Puertos no validos.\e[0m"

        elif [ "$p_ini" -eq "$p_fin" ];
        then
                echo -e "       \e[0;32m[*]\e[0mEscaneo de puertos sobre la IP/dominio: $ip en puerto $p_ini"
                scan $ip $p_ini $p_ini


        elif [ "$p_ini" -lt "$p_fin" ];
        then
                echo -e "       \e[0;32m[*]\e[0mEscaneo de puertos sobre la IP/dominio: $ip en puertos: $p_ini - $p_fin"
                scan $ip $p_ini $p_fin
        else
                p_aux=$p_ini
                p_ini=$p_fin
                p_fin=$p_aux
                echo -e "       \e[0;32m[*]\e[0mEscaneo de puertos sobre la IP/dominio: $ip en puertos: $p_ini a $p_fin"
                scan $ip $p_ini $p_fin
        fi


}


#Ejecucion principal
#Comprobamos que la ip o dominio sean validos
if check_validateDomain_IP $ip;
then
        #Comprobamos que los puertos esten bien dados
        check_isnumber $p_ini $p_fin
        #Ejecucion del escaneo
        execute_scan
else
        echo -e "       \e[01;31mError: La ip o dominio introducido no son validos.\e[0m"

fi