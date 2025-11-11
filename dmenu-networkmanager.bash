#!/bin/bash -i

nmcliList(){
	nmcli device wifi rescan
	nmcli device wifi list | \
		sed "s/^\(..*\)\*\{4,4\}/\1▂▄▆█/g" | \
		sed "s/^\(..*\)\*\{3,3\}/\1▂▄▆_/g" | \
		sed "s/^\(..*\)\*\{2,2\}/\1▂▄__/g" | \
		sed "s/^\(..*\)\*\{1,1\}/\1▂___/g"
	}

printHelp(){
	:
	}

dmenu(){
	command dmenu -l $1 -p NetworkManager -i
}


readarray -t wifis < <(nmcliList | sed 's/  \+/\t/g' | awk 'NR > 1')
hidden=()
if ! printf "%s\n" "${wifis[@]}" | grep -i "WallaceHollisWestcott" &>/dev/null ; then
	hidden+=(WallaceHollisWestcott)
fi

while true
do
	currCon=$(printf "%s\n" "${wifis[@]}" | sort -rn -t $'\t' -k7,7 | awk -F $'\t' '$1 ~ /^*$/ {printf "%s %s\n", $8, $3}')

	if [[ -n "$currCon" ]]
	then
		readarray -t otherCon < <(printf "%s\n" "${wifis[@]}" | sort -t $'\t' -k3,3 -u | sort -rn -t $'\t' -k7,7 | awk -F $'\t' '$1 !~ /^*$/ && $0 !~ /'"${currCon#* }"'/ {printf "%s %s\n", $8, $3}')
		resp="$({ printf "%s\n" "rescan" "-> vpn" "-> reconnect" ; printf "%s\n" "$currCon (disconnect)" "${otherCon[@]}" ; [[ ${#hidden[@]} -gt 0 ]] && printf "hidden %s\n" "${hidden[@]}" ; printf "%s\n" "-> connection-editor" ; } | dmenu "$(( ${#otherCon[@]}  +5 ))")"
	else
		readarray -t otherCon < <(printf "%s\n" "${wifis[@]}" | sort -t $'\t' -k3,3 -u | sort -rn -t $'\t' -k7,7 | awk -F $'\t' '$1 !~ /^*$/ {printf "%s %s\n", $8, $3}')
		resp="$({ printf "%s\n" "-> vpn" ; [[ ${#hidden[@]} -gt 0 ]] && printf "hidden %s\n" "${hidden[@]}" ; printf "%s\n" "${otherCon[@]}"; printf "%s\n" "-> connection-editor" ; } | dmenu "$(( ${#otherCon[@]} +2 ))")"
	fi

	[[ -z "$resp" ]] && exit

	case "$resp" in
		*reconnect)
			notify-send -h string:x-canonical-private-synchronous:Network "Network" "Reconnecting..."
			out="$(nmcli device wifi connect ${currCon#* } 2>&1)"
			if [[ $? -eq 0 ]]
			then
				notify-send "Network" "Connection reactivated"
			else
				notify-send "Network" "$out"
			fi
			break
			;;
		*disconnect\))
			notify-send -h string:x-canonical-private-synchronous:Network "Network" "Disconnecting..."
			connection="${resp#* }"
			out="$(nmcli device disconnect wlp64s0 2>&1)"
			if [[ $? -eq 0 ]]
			then
				notify-send "Network" "Connection deactivated"
			else
				notify-send "Network" "$out"
			fi
			break
			;;
		*vpn)
			vpn="$({ nmcli connection | grep vpn | sed 's/  \+/\t/g' | awk -F $'\t' '{print $1}'; echo "back" ; } | dmenu "$(( $(nmcli connection | grep vpn | wc -l) +1 ))")"
			if [[ "$vpn" != back ]]
			then
				out="$(nmcli connection up "${vpn}" 2>&1)"
				if [[ $? -eq 0 ]]
				then
					notify-send "Network" "VPN activated"
				else
					notify-send "Network" "$out"
				fi
				break
			fi
			;;
		quit)
			break;;
		*connection-editor)
			nm-connection-editor
			break;;
		rescan)
			notify-send -h string:x-canonical-private-synchronous:Network "Network" "Searching..."
			nmcli device wifi rescan
			readarray -t wifis < <(nmcliList | sed 's/  \+/\t/g' | awk 'NR > 1')
			;;
		"hidden "*)
			notify-send -h string:x-canonical-private-synchronous:Network "Network" "Connecting..."
			connection="${resp#hidden }"
			out="$(nmcli connection up "${connection}" 2>&1)"
			if [[ $? -eq 0 ]]
			then
				notify-send -h string:x-canonical-private-synchronous:Network "Network" "Connection activated"
			else
				notify-send "Network" "$out"
			fi
			break
			;;
		*)
			notify-send -h string:x-canonical-private-synchronous:Network "Network" "Connecting..."
			connection="${resp#* }"
			out="$(nmcli device wifi connect "${connection}" 2>&1)"
			if [[ $? -eq 0 ]]
			then
				notify-send -h string:x-canonical-private-synchronous:Network "Network" "Connection activated"
			else
				notify-send "Network" "$out"
			fi
			break
			;;
	esac
done

statusbar-update wifi
