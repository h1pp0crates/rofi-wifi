#!/bin/bash

set -euo pipefail

while true; do
    wifi_status=$(nmcli --field wifi g)
    if [[ "$wifi_status" =~ enabled ]]; then
        notify-send "Getting list of available Wi-Fi networks..." -t 2000 -r 7778
        toggle="󰖪 Disable Wi-Fi"
        delete_con="Delete existing connection"
        hiden="Add hiden network"
        wifi_list=$(nmcli --field "security, ssid, freq" device wifi list | sed -E '1d; s/  */ /g; s/WPA\S*|WEP\S*//g; s/^--//g; s/ //g; /--/d')
        chosen=$(printf "${toggle}\n${delete_con}\n${hiden}\nRefresh\n${wifi_list}" | rofi -dmenu -i -selected-row 3 -p "Enter Wi-Fi SSID: ")
        if [[ "$chosen" = "Refresh" ]]; then
            continue
        fi
        chosen_ssid=$(echo "${chosen:2:-10}")
        if [[ "$chosen" =~ Disable ]]; then
            nmcli radio wifi off && notify-send "Wi-Fi successfully turned off." -t 2000 -r 7778
            exit 0
        elif [[ "$chosen" =~ Delete ]]; then
            connection_list=$(nmcli -f "name,type" connection | grep wifi | awk '{print $1}')
            chosen=$(printf "Back\n${connection_list}" | rofi -dmenu -i -p "Delete connection: ")
            if [[ "$chosen" = "Back" ]]; then
                continue
            else
                nmcli connection delete "$chosen" && notify-send "Connection '${chosen}' successfully deleted." -r 7778
            fi
        elif [[ "$chosen" =~ hiden ]]; then
            ssid=$(rofi -dmenu -p "Wi-Fi ssid: ")
            password=$(rofi -dmenu -password -p "Password: ")
            nmcli device wifi connect "$ssid" password "$password" hidden yes | grep "successfullly" && notify-send "Connection Established" "$success_message" -r 7778
        else
            success_message="Connected to the Wi-Fi network \"$chosen_ssid\"."
            if nmcli -g NAME connection | grep -qx "$chosen_ssid"; then
                nmcli connection up "$chosen_ssid" | grep "successfully" && notify-send "Connection Established" "$success_message" -r 7778
                exit
            else
                wifi_password=""
                if [[ "$chosen" =~  ]]; then
                    wifi_password=$(rofi -dmenu -password -p "Password: ")
                fi
                nmcli device wifi connect "$chosen_ssid" password "$wifi_password" | grep "successfully" >/dev/null && notify-send "Connection Established" "$success_message" -r 7778
                exit
            fi
        fi
    else
        toggle="󰖩 Enable Wi-Fi"
        chosen=$(printf "$toggle" | rofi -dmenu -i -p "Please enable Wi-Fi")
        if [[ "$chosen" =~ Enable ]]; then
            nmcli radio wifi on && notify-send "Please wait five seconds..." -t 5000 -r 7779 && sleep 4 && notify-send "Wi-Fi succesfully turned on." -t 2000 -r 7779
        fi
        continue
    fi
done
