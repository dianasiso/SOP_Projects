#!/bin/bash
export LC_ALL=C
printf '\n'
if [ $# -lt 1 ]; then
	echo "Número de argumentos inválido. Passe pelo menos 1 argumento.";
	exit;
fi
ARGC=0	#numero de argumentos passados
for arg in "${@}"; do
	ARGC=$((ARGC+1))
done
LASTARG="${@: -1}"
if ! [[ $LASTARG =~ ^[0-9]+$ ]] || [[ $LASTARG -eq 0 ]]; then
	echo "Argumento inválido. Passe um número inteiro como argumento.";
	exit;
fi

opP=0; opR=0; opM=0; opT=0; opW=0; opD=0; opE=0; opS=0; opU=0; opC=0
countArgs=1
for element in "${@}";do
	if [[ $element == "-m" ]]; then
		opM=$((opM+1))
		countArgs=$(($countArgs+1))
	fi
	if [[ $element == "-t" ]]; then
		opT=$((opT+1))
		countArgs=$(($countArgs+1))
	fi
	if [[ $element == "-d" ]]; then
		opD=$((opD+1))
		countArgs=$(($countArgs+1))
	fi
	if [[ $element == "-w" ]]; then
		opW=$((opW+1))
		countArgs=$(($countArgs+1))
	fi
	if [[ $element == "-r" ]]; then
		opR=$((opR+1))
		countArgs=$(($countArgs+1))
	fi
	if [[ $element == "-p" ]]; then
		opP=$((opP+1))
		countArgs=$(($countArgs+2))
	fi
	if [[ $element == "-c" ]]; then
		opC=$((opC+1))
		countArgs=$(($countArgs+2))
	fi
	if [[ $element == "-u" ]]; then
		opU=$((opU+1))
		countArgs=$(($countArgs+2))
	fi
	if [[ $element == "-e" ]]; then
		opE=$((opE+1))
		countArgs=$(($countArgs+2))
	fi
	if [[ $element == "-s" ]]; then
		opS=$((opS+1))
		countArgs=$(($countArgs+2))
	fi
done
if [[ $opS -gt 1 ]] || [[ $opE -gt 1 ]] || [[ $opD -gt 1 ]] || [[ $opC -gt 1 ]] || [[ $opU -gt 1 ]] || [[ $opT -gt 1 ]] || [[ $opM -gt 1 ]] || [[ $opP -gt 1 ]] || [[ $opR -gt 1 ]] || [[ $opW -gt 1 ]]; then 
	echo "Argumentos inválidos. Não introduza a mesma opção de ordenação mais do que uma vez."
	exit
fi
if [[ $countArgs -ne $# ]]; then 
	echo "Argumentos inválidos. Passou argumentos que não serão usados ou faltam argumentos!"
	exit
fi
: > TABELA.txt
: > RATE1.txt
: > TEMP.txt
for f in /proc/*; do
	if [[ $f =~ ^[/proc0123456789]+$ ]]; then
		if [ -f "$f/status" ] && [ -f "$f/io" ]; then
			if [ -r $f/status ] && [ -r $f/io ]; then
				PID=$(cat $f/status | awk '/Pid:/{print $2}' | head -1)
				RATER=$(cat $f/io | awk '/rchar/{print $2}'| head -1)
				RATEW=$(cat $f/io | awk '/wchar/{print $2}'| head -1)
				echo "$PID - rchar: $RATER" >> RATE1.txt
				echo "$PID - wchar: $RATEW" >> RATE1.txt
			fi
		fi	
	fi			
done
sleep $LASTARG
for f in /proc/*; do
	if [[ $f =~ ^[/proc0123456789]+$ ]]; then
		if [ -f "$f/status" ] && [ -f "$f/io" ]; then
			if [ -r $f/status ] && [ -r $f/io ]; then
				PID=$(cat $f/status | awk '/Pid:/{print $2}' | head -1)
				RATER2=$(cat $f/io | awk '/rchar/{print $2}'| head -1)
				RATEW2=$(cat $f/io | awk '/wchar/{print $2}'| head -1)
				READB=$(cat $f/io | awk '/read_bytes/{print $2}'| head -1)
				WRITEB=$(cat $f/io | awk '/write_bytes/{print $2}'| head -1)
				NAME=$(cat $f/status | awk '/Name:/{for (i=2; i<=NF; i++) printf "%s ", $i} END {print ""}')
				PID=$(cat $f/status | awk '/Pid:/{print $2}' | head -1)
				MEM=$(cat $f/status | awk '/VmSize:/{print $2}' | head -1)
				RSS=$(cat $f/status | awk '/VmRss:/{print $2}' | head -1)
				RATER1=$(cat RATE1.txt | grep "$PID - rchar:" | awk '{print $4}'| head -1)
				RATEW1=$(cat RATE1.txt | grep "$PID - wchar:" | awk '{print $4}'| head -1)
				if [[ ${#MEM} -eq 0 ]]; then
					MEM=0
				fi
				if [[ ${#RSS} -eq 0 ]]; then
					RSS=0
				fi			
				if [[ ${#NAME} -eq 0 ]]; then
					NAME="-----"
				fi
				NAME="${NAME// /}"
				NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
				if [[ ${#WRITEB} -eq 0 ]]; then
					WRITEB=0
				fi
				if [[ ${#READB} -eq 0 ]]; then
					READB=0
				fi
				if [[ ${#RATER1} -eq 0 ]]; then
					RATER1=0
				fi
				if [[ ${#RATER2} -eq 0 ]]; then
					RATER2=0
				fi
				if [[ ${#RATEW1} -eq 0 ]]; then
					RATEW1=0
				fi
				if [[ ${#RATEW2} -eq 0 ]]; then
					RATEW2=0
				fi	
				RESULTR=`expr $RATER2 - $RATER1`
				RESULTW=`expr $RATEW2 - $RATEW1`
				
				if [[ ${#NAME} -gt 12 ]];then
					printf '%-20s' "${NAME:0:10}..." >> TABELA.txt
				else
					printf '%-20s' "$NAME" >> TABELA.txt
				fi
				if [[ ${#PID} -eq 0 ]]; then
					PID="-----"
					printf '%-20s %10s' "-----" "$PID" >> TABELA.txt
				else
					printf '%-20s %10s' "$(ps -o user= -p $PID)" "$PID" >> TABELA.txt
				fi
				printf '%16s %15s %20s %20s' "$MEM" "$RSS" "$READB" "$WRITEB" >> TABELA.txt
				printf '%21s' $(echo "scale=2; $RESULTR/$LASTARG" | bc -l ) >> TABELA.txt
				printf '%21s' $(echo "scale=2; $RESULTW/$LASTARG" | bc -l ) >> TABELA.txt
				if [[ ${#PID} -eq 0 ]]; then
					printf '%20s\n' "-----" >> TABELA.txt
				else
					DATE=$(ps -o lstart= -p $PID | awk '{for (i=2; i<NF; i++) printf "%s ", $i} END {print ""}')
					DATE="${DATE// /_}"
					DATE=${DATE::-1}
					printf '%22s\n' "$DATE" >> TABELA.txt
				fi
			fi			
		fi
	fi
done
sed '1d' TABELA.txt > TEMP.txt; 
: > TABELA.txt
sort TEMP.txt > TABELA.txt 

if [[ $# -gt 1 ]]; then	#já está validado lá em cima e já sabemos que só é passado o tempo
	while getopts "mtdwr,:c:s:e:u:p:" opt;do
		case $opt in
			c)
				OPTARG="${OPTARG//./}"
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				{
				while read line; do
					nome=$(awk '{printf $1}' <<< $line)
					if [[ $nome == $OPTARG ]]; then
						echo "$line" >> TABELA.txt
					fi
				done
				}<TEMP.txt			
				;;
			s)
				#VALIDAÇÃO DO INPUT
				count=0
				for element in $OPTARG; do
					if [[ $count -eq 0 ]]; then
						if [[ "$element" == "Dez" ]] || [[ "$element" == "Dec" ]]; then
							mesArg=12
						elif [[ "$element" == "Nov" ]]; then
							mesArg=11						
						elif [[ "$element" == "Oct" ]] || [[ "$element" == "Out" ]]; then
							mesArg=10						
						elif [[ "$element" == "Sep" ]] || [[ "$element" == "Set" ]]; then
							mesArg=9					
						elif [[ "$element" == "Ago" ]] || [[ "$element" == "Aug" ]]; then
							mesArg=8						
						elif [[ "$element" == "Jul" ]]; then
							mesArg=7						
						elif [[ "$element" == "Jun" ]]; then
							mesArg=6
						elif [[ "$element" == "May" ]] || [[ "$element" == "Mai" ]]; then
							mesArg=5
						elif [[ "$element" == "Apr" ]] || [[ "$element" == "Abr" ]]; then
							mesArg=4
						elif [[ "$element" == "Mar" ]]; then
							mesArg=3
						elif [[ "$element" == "Feb" ]] || [[ "$element" == "Fev" ]]; then
							mesArg=2
						elif [[ "$element" == "Jan" ]]; then
							mesArg=1
						else
							echo "Primeiro argumento inválido: passe um mês como primeiro argumento."
							exit
						fi
					fi
					if [[ $count -eq 1 ]]; then
						diaArg=$element;
						if ! [[ $element =~ ^[0-9]+$ ]]; then
							echo "Segundo argumento inválido: passe um número inteiro."
							exit
						fi 	#VALIDAR SE É UM NUMERO
						#VALIDAR O INTERVALO DE DIAS
						if [[ $mesArg -eq 12 ]] || [[ $mesArg -eq 10 ]] || [[ $mesArg -eq 8 ]] || [[ $mesArg -eq 7 ]]  || [[ $mesArg -eq 5 ]] || [[ $mesArg -eq 3 ]]  || [[ $mesArg -eq 1 ]]; then	#meses com 31 dias
							if [[ $element -lt 1 ]] || [[ $element -gt 31 ]]; then
								echo "Segundo argumento inválido: passe um número compreendido entre 1 e 31."
								exit 
							fi
						elif [[ $mesArg -eq 11 ]] || [[ $mesArg -eq 9 ]] || [[ $mesArg -eq 6 ]] || [[ $mesArg -eq 4 ]]; then	#meses com 31 dias
							if [[ $element -lt 1 ]] || [[ $element -gt 30 ]]; then
								echo "Segundo argumento inválido: passe um número compreendido entre 1 e 30."
								exit
							fi
						else 	#FEB
							if [[ $element -lt 1 ]] || [[ $element -gt 29 ]]; then
								echo "Segundo argumento inválido: passe um número compreendido entre 1 e 29."
								exit
							fi
						fi						
					fi
					if [[ $count -eq 2 ]]; then
						element="${element//:/ }"
						horaArg=$(awk '{printf $1}' <<< $element)
						minArg=$(awk '{printf $2}' <<< $element)
						segArg=$(awk '{printf $3}' <<< $element)
						if [[ ${#segArg} -eq 0 ]]; then
							segArg=00
						fi 
						if [[ ${#minArg} -eq 0 ]] || [[ ${#horaArg} -eq 0 ]]; then
							echo "Argumento inválido. Passe o parâmetro horário com pelo menos a informação referente às horas e minutos. Ex.: 23:43."
							exit
						fi 
						
						if [[ $horaArg =~ ^[0-9]+$ ]]  && [[ $minArg =~ ^[0-9]+$ ]] && [[ $segArg =~ ^[0-9]+$ ]]; then
							if [[ $horaArg -gt 24 ]]; then
								echo "Horas inválidas: passe um número inteiro compreendido entre 0 e 24."
								exit
							fi
							if [[ $minArg -gt 60 ]]; then
								echo "Minutos inválidos: passe um número inteiro compreendido entre 0 e 60."
								exit
							fi
							if [[ $segArg -gt 60 ]]; then
								echo "Segundos inválidos: passe um número inteiro compreendido entre 0 e 60."
								exit
							fi
						else
							echo "Terceiro argumento inválido: passe um número inteiro."
							exit
						fi 	
						
					fi
					count=$((count+1))
				done
				if [[ $count -gt 3 ]]; then
					echo "Número de argumentos inválido! Passe apenas 3 argumentos, o 1º referente ao mês, o 2º referente ao dia e o 3º referente às horas."
					exit
				fi
				
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				{
				while read line; do
					data=$(awk '{printf $10}' <<< $line)
					data="${data//_/ }"
					mesTabela=$(awk '{printf $1}' <<< $data)
					diaTabela=$(awk '{printf $2}' <<< $data)
					horarioTabela=$(awk '{printf $3}' <<< $data)
					horarioTabela="${horarioTabela//:/ }"
					horaTabela=$(awk '{printf $1}' <<< $horarioTabela)
					minTabela=$(awk '{printf $2}' <<< $horarioTabela)
					segTabela=$(awk '{printf $3}' <<< $horarioTabela)
					if [[ "$mesTabela" == "Dez" ]] || [[ "$mesTabela" == "Dec" ]]; then
						mesTabela=12
					elif [[ "$mesTabela" == "Nov" ]]; then
						mesTabela=11						
					elif [[ "$mesTabela" == "Oct" ]] || [[ "$mesTabela" == "Out" ]]; then
						mesTabela=10						
					elif [[ "$mesTabela" == "Sep" ]] || [[ "$mesTabela" == "Set" ]]; then
						mesTabela=9					
					elif [[ "$mesTabela" == "Ago" ]] || [[ "$mesTabela" == "Aug" ]]; then
						mesTabela=8						
					elif [[ "$mesTabela" == "Jul" ]]; then
						mesTabela=7						
					elif [[ "$mesTabela" == "Jun" ]]; then
						mesTabela=6
					elif [[ "$mesTabela" == "May" ]] || [[ "$mesTabela" == "Mai" ]]; then
						mesTabela=5
					elif [[ "$mesTabela" == "Apr" ]] || [[ "$mesTabela" == "Abr" ]]; then
						mesTabela=4
					elif [[ "$mesTabela" == "Mar" ]]; then
						mesTabela=3
					elif [[ "$mesTabela" == "Feb" ]] || [[ "$mesTabela" == "Fev" ]]; then
						mesTabela=2
					elif [[ "$mesTabela" == "Jan" ]]; then
						mesTabela=1
					fi
					if [[ $mesTabela -gt $mesArg ]]; then 
						echo "$line" >> TABELA.txt
					else	# meses iguais ou mes menor, se for mes menor ent n vai escrever, pelo q so nos interessa averiguar os casos que sao iguais
						if [[ $mesTabela -eq $mesArg ]]; then
							if [[ $diaTabela -gt $diaArg ]]; then
								echo "$line" >> TABELA.txt
							else #dias iguais ou dia menor, se for dia menor ent n vai escrever, pelo q so nos interessa averiguar os casos que sao iguais
								if [[ $diaTabela -eq $diaArg ]]; then
									if [[ $horaTabela -gt $horaArg ]]; then
										echo "$line" >> TABELA.txt
									else
										if [[ $horaTabela -eq $horaArg ]]; then
											if [[ $minTabela -gt $minArg ]]; then
												echo "$line" >> TABELA.txt
											else
												if [[ $minTabela -eq $minArg ]]; then
													if [[ $segTabela -ge $segArg ]]; then
														echo "$line" >> TABELA.txt
													fi
												fi
											fi
										fi
									fi
								fi	
							fi	
						fi
					fi				
				done
				}<TEMP.txt	
				;;	
			e)
				#VALIDAÇÃO DO INPUT
				count=0
				for element in $OPTARG; do
					if [[ $count -eq 0 ]]; then
						if [[ "$element" == "Dez" ]] || [[ "$element" == "Dec" ]]; then
							mesArg=12
						elif [[ "$element" == "Nov" ]]; then
							mesArg=11						
						elif [[ "$element" == "Oct" ]] || [[ "$element" == "Out" ]]; then
							mesArg=10						
						elif [[ "$element" == "Sep" ]] || [[ "$element" == "Set" ]]; then
							mesArg=9					
						elif [[ "$element" == "Ago" ]] || [[ "$element" == "Aug" ]]; then
							mesArg=8						
						elif [[ "$element" == "Jul" ]]; then
							mesArg=7						
						elif [[ "$element" == "Jun" ]]; then
							mesArg=6
						elif [[ "$element" == "May" ]] || [[ "$element" == "Mai" ]]; then
							mesArg=5
						elif [[ "$element" == "Apr" ]] || [[ "$element" == "Abr" ]]; then
							mesArg=4
						elif [[ "$element" == "Mar" ]]; then
							mesArg=3
						elif [[ "$element" == "Feb" ]] || [[ "$element" == "Fev" ]]; then
							mesArg=2
						elif [[ "$element" == "Jan" ]]; then
							mesArg=1
						else
							echo "Primeiro argumento inválido: passe um mês como primeiro argumento."
							exit
						fi
					fi
					if [[ $count -eq 1 ]]; then
						diaArg=$element;
						if ! [[ $element =~ ^[0-9]+$ ]]; then
							echo "Segundo argumento inválido: passe um número inteiro."
							exit
						fi 	#VALIDAR SE É UM NUMERO
						#VALIDAR O INTERVALO DE DIAS
						if [[ $mesArg -eq 12 ]] || [[ $mesArg -eq 10 ]] || [[ $mesArg -eq 8 ]] || [[ $mesArg -eq 7 ]]  || [[ $mesArg -eq 5 ]] || [[ $mesArg -eq 3 ]]  || [[ $mesArg -eq 1 ]]; then	#meses com 31 dias
							if [[ $element -lt 1 ]] || [[ $element -gt 31 ]]; then
								echo "Segundo argumento inválido: passe um número compreendido entre 1 e 31."
								exit 
							fi
						elif [[ $mesArg -eq 11 ]] || [[ $mesArg -eq 9 ]] || [[ $mesArg -eq 6 ]] || [[ $mesArg -eq 4 ]]; then	#meses com 31 dias
							if [[ $element -lt 1 ]] || [[ $element -gt 30 ]]; then
								echo "Segundo argumento inválido: passe um número compreendido entre 1 e 30."
								exit
							fi
						else 	#FEB
							if [[ $element -lt 1 ]] || [[ $element -gt 29 ]]; then
								echo "Segundo argumento inválido: passe um número compreendido entre 1 e 29."
								exit
							fi
						fi					
					fi
					if [[ $count -eq 2 ]]; then
						element="${element//:/ }"
						horaArg=$(awk '{printf $1}' <<< $element)
						minArg=$(awk '{printf $2}' <<< $element)
						segArg=$(awk '{printf $3}' <<< $element)
						if [[ ${#segArg} -eq 0 ]]; then
							segArg=00
						fi 
						if [[ ${#minArg} -eq 0 ]] || [[ ${#horaArg} -eq 0 ]]; then
							echo "Argumento inválido. Passe o parâmetro horário com pelo menos a informação referente às horas e minutos. Ex.: 23:43."
							exit
						fi 
						
						if [[ $horaArg =~ ^[0-9]+$ ]]  && [[ $minArg =~ ^[0-9]+$ ]] && [[ $segArg =~ ^[0-9]+$ ]]; then
							if [[ $horaArg -gt 24 ]]; then
								echo "Horas inválidas: passe um número inteiro compreendido entre 0 e 24."
								exit
							fi
							if [[ $minArg -gt 60 ]]; then
								echo "Minutos inválidos: passe um número inteiro compreendido entre 0 e 60."
								exit
							fi
							if [[ $segArg -gt 60 ]]; then
								echo "Segundos inválidos: passe um número inteiro compreendido entre 0 e 60."
								exit
							fi
						else
							echo "Terceiro argumento inválido: passe um número inteiro."
							exit
						fi 	
						
					fi
					count=$((count+1))
				done
				if [[ $count -gt 3 ]]; then
					echo "Número de argumentos inválido! Passe apenas 3 argumentos, o 1º referente ao mês, o 2º referente ao dia e o 3º referente às horas."
					exit
				fi
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				{
				while read line; do
					data=$(awk '{printf $10}' <<< $line)
					data="${data//_/ }"
					mesTabela=$(awk '{printf $1}' <<< $data)
					diaTabela=$(awk '{printf $2}' <<< $data)
					horarioTabela=$(awk '{printf $3}' <<< $data)
					horarioTabela="${horarioTabela//:/ }"
					horaTabela=$(awk '{printf $1}' <<< $horarioTabela)
					minTabela=$(awk '{printf $2}' <<< $horarioTabela)
					segTabela=$(awk '{printf $3}' <<< $horarioTabela)
					if [[ "$mesTabela" == "Dez" ]] || [[ "$mesTabela" == "Dec" ]]; then
						mesTabela=12
					elif [[ "$mesTabela" == "Nov" ]]; then
						mesTabela=11						
					elif [[ "$mesTabela" == "Oct" ]] || [[ "$mesTabela" == "Out" ]]; then
						mesTabela=10						
					elif [[ "$mesTabela" == "Sep" ]] || [[ "$mesTabela" == "Set" ]]; then
						mesTabela=9					
					elif [[ "$mesTabela" == "Ago" ]] || [[ "$mesTabela" == "Aug" ]]; then
						mesTabela=8						
					elif [[ "$mesTabela" == "Jul" ]]; then
						mesTabela=7						
					elif [[ "$mesTabela" == "Jun" ]]; then
						mesTabela=6
					elif [[ "$mesTabela" == "May" ]] || [[ "$mesTabela" == "Mai" ]]; then
						mesTabela=5
					elif [[ "$mesTabela" == "Apr" ]] || [[ "$mesTabela" == "Abr" ]]; then
						mesTabela=4
					elif [[ "$mesTabela" == "Mar" ]]; then
						mesTabela=3
					elif [[ "$mesTabela" == "Feb" ]] || [[ "$mesTabela" == "Fev" ]]; then
						mesTabela=2
					elif [[ "$mesTabela" == "Jan" ]]; then
						mesTabela=1
					fi
					if [[ $mesTabela -lt $mesArg ]]; then 
						echo "$line" >> TABELA.txt
					else	# meses iguais ou mes menor, se for mes menor ent n vai escrever, pelo q so nos interessa averiguar os casos que sao iguais
						if [[ $mesTabela -eq $mesArg ]]; then
							if [[ $diaTabela -lt $diaArg ]]; then
								echo "$line" >> TABELA.txt
							else #dias iguais ou dia menor, se for dia menor ent n vai escrever, pelo q so nos interessa averiguar os casos que sao iguais
								if [[ $diaTabela -eq $diaArg ]]; then
									if [[ $horaTabela -lt $horaArg ]]; then
										echo "$line" >> TABELA.txt
									else
										if [[ $horaTabela -eq $horaArg ]]; then
											if [[ $minTabela -lt $minArg ]]; then
												echo "$line" >> TABELA.txt
											else
												if [[ $minTabela -eq $minArg ]]; then
													if [[ $segTabela -le $segArg ]]; then
														echo "$line" >> TABELA.txt
													fi
												fi
											fi
										fi
									fi
								fi	
							fi	
						fi
					fi			
				done
				}<TEMP.txt
				;;
			u)
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				{
				while read line; do
					userT=$(awk '{printf $2}' <<< $line)
					if [[ "$userT" == "$OPTARG" ]]; then
						echo "$line" >> TABELA.txt
					fi
					#echo $user
				done
				}<TEMP.txt
				;;
			p)
				if ! [[ $OPTARG  =~ ^[0-9]+$ ]] || [[ $OPTARG -lt 1 ]]; then
					echo "Argumento inválido. Ao parâmetro -p deverá estar associado um número inteiro positivo."
					exit
				fi
				head -$(($OPTARG)) TABELA.txt > TEMP.txt
				: > TABELA.txt
				cp TEMP.txt TABELA.txt 
				;;
			m)
				reverse=0
				count=1
				for i in "$@"; do
					if [[ "$i" == "-t" ]] || [[ "$i" == "-d" ]] || [[ "$i" == "-w" ]]; then
						echo "Argumentos inválidos! Não pode passar a opção -m com as opções -t, -d ou -w."
						exit
					fi 
					if [[ $count -eq $OPTIND ]]; then
						if [[ "$i" == "-r" ]]; then
							reverse=1
						fi
					fi 
					count=$(($count+1))
				done
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				if [[ $reverse -eq 0 ]]; then
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nrk4 | uniq > TABELA.txt
				else
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nk4 | uniq > TABELA.txt
				fi
				;;
			t)
				reverse=0
				count=1
				for i in "$@"; do
					if [[ "$i" == "-m" ]] || [[ "$i" == "-d" ]] || [[ "$i" == "-w" ]]; then
						echo "Argumentos inválidos! Não pode passar a opção -t com as opções -m, -d ou -w."
						exit
					fi 
					if [[ $count -eq $OPTIND ]]; then
						if [[ "$i" == "-r" ]]; then
							reverse=1
						fi
					fi 
					count=$(($count+1))
				done
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				if [[ $reverse -eq 0 ]]; then
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nrk5 | uniq > TABELA.txt
				else
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nk5 | uniq > TABELA.txt
				fi
				;;
			d)
				reverse=0
				count=1
				for i in "$@"; do
					if [[ "$i" == "-m" ]] || [[ "$i" == "-t" ]] || [[ "$i" == "-w" ]]; then
						echo "Argumentos inválidos! Não pode passar a opção -d com as opções -m, -t ou -w."
						exit
					fi 
					if [[ $count -eq $OPTIND ]]; then
						if [[ "$i" == "-r" ]]; then
							reverse=1
						fi
					fi 
					count=$(($count+1))
				done
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				if [[ $reverse -eq 0 ]]; then
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nrk8 | uniq > TABELA.txt
				else
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nk8 | uniq > TABELA.txt
				fi
				;;
			w)
				reverse=0
				count=1
				for i in "$@"; do
					if [[ "$i" == "-m" ]] || [[ "$i" == "-t" ]] || [[ "$i" == "-d" ]]; then
						echo "Argumentos inválidos! Não pode passar a opção -w com as opções -m, -t ou -d."
						exit
					fi 
					if [[ $count -eq $OPTIND ]]; then
						if [[ "$i" == "-r" ]]; then
							reverse=1
						fi
					fi 
					count=$(($count+1))
				done
				cp TABELA.txt TEMP.txt; 
				: > TABELA.txt
				if [[ $reverse -eq 0 ]]; then
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nrk9 | uniq > TABELA.txt
				else
					awk '{ printf "%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %20s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 }' TEMP.txt | sort -nk9 | uniq > TABELA.txt
				fi
				;;
			r)
				if [[ $# -eq 2 ]]; then	#um deles já sabemos que é o tempo por isso o outro é -r reverse alpha
					 sort -r TABELA.txt > TEMP.txt
					 : > TABELA.txt
					 cp TEMP.txt TABELA.txt 
				elif [[  $# -eq 3 ]]; then	
					if [[ "$1" == "-r" ]]; then
						echo "Argumentos inválidos! Verifique se passou os argumentos -m, -t, -d ou -w antes do -r ou se passou argumentos válidos."
						exit
					fi
				else
					indexR=1
					for i in "${@}"; do
						indexO=1
						for k in "${@}"; do
							if [[ "$i" == "-r" ]]; then
								if [[ "$k" == "-m" ]] || [[ "$k" == "-t" ]] || [[ "$k" == "-d" ]] || [[ "$k" == "-w" ]]; then
									
									if [[ $indexO -gt $indexR ]]; then
										echo "Argumentos inválidos! Verifique se passou os argumentos -m, -t, -d ou -w antes do -r."
										exit
									else
										DIF=`expr $indexR - $indexO`
										if [[ $DIF -ne 1 ]]; then
											echo "Argumentos inválidos! Verifique se as opções -m/-t/-d/-w estão exatamente antes do -r"
											exit
										else
											break;
										fi
									fi
								else
									sort -r TABELA.txt > TEMP.txt
					 				: > TABELA.txt
					 				cp TEMP.txt TABELA.txt 
								fi 
							fi
							indexO=$(($indexO+1))
						done									
						indexR=$(($indexR+1))
					done
				fi
				;;
		esac
	done
	shift $((OPTIND-1))
fi
printf '%-19s %-21s %9s %15s %15s %20s %20s %20s %20s %21s\n' "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE" 
cat TABELA.txt
