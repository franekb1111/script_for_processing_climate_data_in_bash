#!/bin/bash

czas_start=$(($(date +%s%N) / 1000))

if [ "$(echo $#)" == "0" ]
then
	echo "nie podano argumentow, podaj 2 lub wiecej argumentow w postaci <KAT_BAZOWY> <nazwa_pliku_danych_1> ... <nazwa_pliku_danych_N>" >&2
	exit 1
fi

if [ "$(echo $#)" == "1" ]
then
	echo "podano 1 argument,  podaj 2 lub wiecej argumentow w postaci <KAT_BAZOWY> <nazwa_pliku_danych_1> ... <nazwa_pliku_danych_N>" >&2
	exit 2
fi

pom=0

for((i=2;i<=$#;i++))
do
	if [ ! -f "${!i}" ] || [ "$(ls -l "${!i}" | cut -c2)" != "r" ]
	then
		echo podany plik "${!i}" nie istnieje lub nie ma dostepu do niego >&2
		pom=$(($pom+1))
	fi
done

if [ $pom -ge "1" ]
then
        exit 3
fi	

if [ ! -d "$1" ]
then
	mkdir "$1"
	if [ ! -d "$1" ]
	then
		echo nie mozna stwozyc katalogu bazowego >&2
		exit 4
	fi
fi

touch "$1"/temp

for((i=2;i<=$#;i++))
do
	cat "${!i}" | cut -f3,4 -d, | uniq | tr -d '"'
done > "$1"/temp

while read wiersz
do
	mkdir -p "$1"/"$wiersz"
done < <(cat "$1"/temp | tr ',' '/' | sort | uniq)

rm "$1"/temp

if [ -f "o_d_02_2021_part1.csv" ]
then
        echo "" >> "o_d_02_2021_part1.csv"
	echo "" >> "o_d_02_2021_part1.csv"
        sed -i '/^$/d' "o_d_02_2021_part1.csv"   #^ - poczatek lini, $ - koniec lini
fi

touch "$1"/temp2

for((i=2;i<=$#;i++))
do
        cat "${!i}" >> "$1"/temp2
done

while read wiersz
do	
	if [ "$(echo $wiersz | cut -f7 -d,)" != "8" ]
	then
		echo $wiersz >> "$1"/"$(echo $wiersz | cut -f3 -d,)"/"$(echo $wiersz | cut -f4 -d,)"/"$(echo $wiersz | cut -f5 -d,)".csv
		sort -u "$1"/"$(echo $wiersz | cut -f3 -d,)"/"$(echo $wiersz | cut -f4 -d,)"/"$(echo $wiersz | cut -f5 -d,)".csv -o "$1"/"$(echo $wiersz | cut -f3 -d,)"/"$(echo $wiersz | cut -f4 -d,)"/"$(echo $wiersz | cut -f5 -d,)".csv
	fi
	if [ "$(echo $wiersz | cut -f7 -d,)" == "8" ]
        then
                echo $wiersz >> "$1"/"$(echo $wiersz | cut -f3 -d,)"."$(echo $wiersz | cut -f4 -d,)".errors
        	sort -u "$1"/"$(echo $wiersz | cut -f3 -d,)"."$(echo $wiersz | cut -f4 -d,)".errors -o "$1"/"$(echo $wiersz | cut -f3 -d,)"."$(echo $wiersz | cut -f4 -d,)".errors
	fi
done < <(cat "$1"/temp2 | sort | uniq | tr -d '"')

mkdir -p "$1"/"LINKS"

while read wiersz1
do
	if [ "$(echo $wiersz1 | cut -f7 -d,)" != "8" ]
	then
		suma=0
		while read wiersz2
		do
			pom=$(echo $wiersz2 | cut -f6 -d,)
			suma=$(echo $suma + $pom | bc -l)
		done < <(cat "$1"/"$(echo $wiersz1 | cut -f3 -d,)"/"$(echo $wiersz1 | cut -f4 -d,)"/"$(echo $wiersz1 | cut -f5 -d,)".csv)		
		echo "$1"/"$(echo $wiersz1 | cut -f3 -d,)"/"$(echo $wiersz1 | cut -f4 -d,)"/"$(echo $wiersz1 | cut -f5 -d,)".csv,$suma >> "$1"/temp3
	fi
done < <(cat "$1"/temp2 | sort | uniq | tr -d '"')

ln -s -f -r "$(cat "$1"/temp3 | sort -u -k2 -t, -h | head -n1 | cut -f1 -d,)" "$1"/"LINKS"/MIN_OPAD

ln -s -f -r "$(cat "$1"/temp3 | sort -u -k2 -t, -h | tail -n1 | cut -f1 -d,)" "$1"/"LINKS"/MAX_OPAD

rm "$1"/temp3

rm "$1"/temp2

echo "$$,$PPID,$(($(($(date +%s%N) / 1000)) - $czas_start)),$(ps -p $$ -o cmd=)" >> "$1"/out.log

find "$(realpath "$1")" -type d -exec chmod 750 {} +
find "$(realpath "$1")" -type f -exec chmod 640 {} +



