#!/bin/bash

#port="-p tcp -m multiport --dport 80,443"
port=""

usage() {
	echo "usage :"
    echo -e "\t./geoip.sh [country code] [ACCEPT/REJECT/DROP]"
    echo -e "\tex) ./geoip.sh KR ACCEPT\n"
	echo -e "\t./geoip.sh remove [Chain Name]"
    echo -e "\tex) ./geoip.sh remove ACCEPTKR"

	exit 0

}

main() {
    wget https://mailfud.org/geoip-legacy/GeoIP-legacy.csv.gz --no-check-certificate
    gzip -d GeoIP-legacy.csv.gz

    iptables -N $policy$country
    iptables -I INPUT --jump $policy$country -p tcp -m multiport --dport 80,443

    DATA=./GeoIP-legacy.csv

    for IPRANGE in `egrep "$country" $DATA | grep -v ":" | cut -d, -f1,2 | sed -e 's/"//g' | sed -e 's/,/-/g'`
    do
        echo $IPRANGE
        iptables -A $policy$country -p tcp -m iprange --src-range $IPRANGE -m multiport --dport 80,443 -j $policy
    done

	rm -f GeoIP-legacy.csv
}

if (( $# != 2 )) ; then
	usage
elif (( $# == 2 )) ; then
	if [[ $1 == "remove" ]] ; then
		iptables -D INPUT --jump $2 -p tcp -m multiport --dport 80,443
		iptables -F $2
		iptables -X	$2
	else
		country=$1
		policy=$2 
		if [[ `cat country_code_list.txt | cut -d ',' -f 2 | grep $country` != "" ]] && [[ `echo $policy | grep -E "ACCEPT|REJECT|DROP"` != "" ]] ; then
			main
		else
			usage
		fi
	fi
fi
