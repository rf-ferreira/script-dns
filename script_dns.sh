#!/bin/bash

serial=0
dns1=0
dns2=0

while [ true ]
do
clear

echo -e "\e[1m
+-----------------------------+
|          -=Menu=-           |
|  1. Adicionar novo serial   |     
|  2. Mudar IPs dns1 e dns2   |
|  3. Criar zone + arquivo    |
|  4. Criar zone DNS Slave    |
|  5. Ver zonas criadas       |
|  6. Sair                    |
+-----------------------------+
        \e[0m"

echo "Escolha uma opcao:"
read -p "-> " opcao

#Cria zone no arquivo /etc/named.conf
function criar_zone_master {
    sed -i "59s/$/zone "\"$zona"\" IN {/g" /etc/named.conf
    sed -i "60s/$/       type master;/g" /etc/named.conf
    sed -i "61s/$/       file "\"$zona".zone\";/g" /etc/named.conf
    sed -i "62s/$/       allow-transfer { "$dns2"; };/g" /etc/named.conf
    sed -i "63s/$/};/g" /etc/named.conf
}

#Cria zone DNS Slave
function criar_zone_slave {
    sed -i "59s/$/zone "\"$zona"\" IN {/g" /etc/named.conf
    sed -i "60s/$/       type slave;/g" /etc/named.conf
    sed -i "61s/$/       masters { "$dns1"; };/g" /etc/named.conf
    sed -i "62s/$/       file \"slaves\/"$zona".zone\";/g" /etc/named.conf
    sed -i "63s/$/};/g" /etc/named.conf
}

#Cria arquivo zone em /var/named
function criar_arquivo_zone {
    printf "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" > /var/named/$zona.zone

    sed -i "1s/$/\$TTL 86400/g" /var/named/$zona.zone
    sed -i "2s/$/@ IN SOA dns1."$zona". hostmaster."$zona". (/g" /var/named/$zona.zone
    sed -i "3s/$/                        "$serial" ; Serial/g" /var/named/$zona.zone
    sed -i "4s/$/                        3600       ; Refresh/g" /var/named/$zona.zone
    sed -i "5s/$/                        7200       ; Retry/g" /var/named/$zona.zone
    sed -i "6s/$/                        2419200    ; Expire/g" /var/named/$zona.zone
    sed -i "7s/$/                        86400 )    ; Minimum/g" /var/named/$zona.zone
    sed -i "9s/$/@ IN NS dns1."$zona"./g" /var/named/$zona.zone
    sed -i "10s/$/@ IN NS dns2."$zona"./g" /var/named/$zona.zone
    sed -i "12s/$/;A/g" /var/named/$zona.zone
    sed -i "14s/$/@ IN A "$endereco_ip"/g" /var/named/$zona.zone
    sed -i "15s/$/www IN A "$endereco_ip"/g" /var/named/$zona.zone
    sed -i "16s/$/dns1 IN A "$dns1"/g" /var/named/$zona.zone
    sed -i "17s/$/dns2 IN A "$dns2"/g" /var/named/$zona.zone
}

#Cria linhas em branco onde sera adicionada nova zona em /etc/named.conf
function pular_linhas {
for i in {0..5}
    do
        sed -i "57s/.*};/&\n/" /etc/named.conf
    done
}

#Opcoes do menu
case $opcao in
1*)
    echo -e "Novo serial: \e[1m(AAAAMMDDVV)\e[0m"
    read -p "-> " serial
    echo -e "Deseja salvar alteracoes? (s/n)"
    read -p "" sn
    if [ "$sn" = "s" -o "$sn" = "S" ]
        then
            if [[ $serial =~ ^[0-9]+$ ]]
                then
                    continue
            else
                serial=0
                echo -e "\e[91mSomente numeros sao validos\e[0m"
                read -p "Pressione qualquer tecla para continuar..." -s -n1
            fi
    elif [ "$sn" = "n" -o "$sn" = "N" ]
        then
            serial=0
    else
        serial=0
        echo -e "\e[91mOpcao invalida!\e[0m"
        read -p "Pressione qualquer tecla para continuar..." -s -n1
    fi;;

2*)
    read -p "dns1 IN A " dns1
    read -p "dns2 IN A " dns2
    if [[ $dns1 =~ ^[0-9]+.+$ && $dns2 =~ ^[0-9]+.+$ ]]
        then
            continue
    else
        echo -e "\e[91mSomente numeros sao validos\e[0m"
        dns1=0
        dns2=0
        read -p "Pressione qualquer tecla para continuar..." -s -n1
    fi;;

3*)
    echo -e "\e[32mCriacao de zona DNS Master\e[0m"
    echo "zona do dominio (ex: google.com)"
    read -p "-> " zona

    if [ $serial = 0 ]
        then
            echo -e "\e[91mAdicione um serial para o arquivo zone\e[0m"
    fi
    if [ $dns1 = 0 ]
        then
            echo -e "\e[91mAdicione um endereco IP para o dns1\e[0m"
    fi
    if [ $dns2 = 0 ]
        then
            echo -e "\e[91mAdicione um endereco IP para o dns2\e[0m"
    fi
    if [ $serial = 0 -o $dns1 = 0 -o $dns2 = 0 ]
        then
            read -p "Pressione qualquer tecla para continuar..." -s -n1
    fi
    if [ $serial != 0 -a $dns1 != 0 -a $dns2 != 0 ]
        then
            read -p "-> www IN A " endereco_ip
            pular_linhas
            criar_zone_master
            criar_arquivo_zone
            echo -e "\e[92mzona criada + arquivo .zone\e[0m"
            service named restart
            read -p "Pressione qualquer tecla para continuar..." -s -n1
    fi;;

4*)
    echo -e "\e[31mCriacao de zona DNS Slave\e[0m"
    echo "zona do dominio (ex: google.com)"
    read -p "-> " zona
    if [ $dns1 = 0 ]
    then
            echo -e "\e[91mAdicione um endereco IP para o dns1\e[0m"
            read -p "Pressione qualquer tecla para continuar..." -s -n1
    fi
    if [ $dns1 != 0 ]
    then
        pular_linhas
        criar_zone_slave
        echo -e "\e[92mzona criada\e[0m"
        service named restart
        read -p "Pressione qualquer tecla para continuar..." -s -n1
    fi;;

5*)
    clear
    echo -e "\e[1;96;100m"
    sed -n '59,$p' /etc/named.conf
    echo -e "\e[0m"
    read -p "Pressione qualquer tecla para continuar..." -s -n1;;

6*)
    break;;

esac
done