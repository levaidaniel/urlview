#!/bin/sh

# Copyright LEVAI Daniel <leva@ecentrum.hu>
# Distributed under the 2-clause BSD license (see LICENSE file)


typeset -i i=0
typeset -i nword=0

URL_PATTERN='https*://[[:alnum:]:./?=&_-]+'
for word in $(tr '\n' ' ');do
	nword=$(( nword + 1 ))

	[ $(( $nword % 50 )) -eq 0 ]  &&  printf "$0: $nword ...\r"

	# Huge speed-up (for pretesting the string with an internal shell feature):
	# (if "[[ ]]" is not supported by the shell, comment it)
	if [[ "${word}" != *http* ]];then continue;fi

	while echo "${word}" |egrep -q -e "${URL_PATTERN}";do
		url=$( echo ${word} |sed -r -e "s,(.*)(${URL_PATTERN})(.*),\2," )
		word=$( echo ${word} |sed -r -e "s,(.*)(${URL_PATTERN})(.*),\1\3," )

		URLS[$i]=${url}
		i=$(( i + 1 ))
	done
done

unset i
unset nword


printf "== URL viewer: $0 ==\n\n"
printf "BROWSER is '${BROWSER:-<empty>}'\n\n"

exec 0</dev/tty

PS3="<1-${#URLS[@]},x,b> #? "
select url in ${URLS[@]};do
	case "${REPLY}" in
		X|x|Q|q)
			break;
		;;
		B|b)
			echo -n 'Enter new BROWSER value: '; read BROWSER
		;;
		*)
			[ -n "${url}" ]  ||  continue;

			if [ -z "${BROWSER}" ]  ||  [ ! -x "${BROWSER}" ];then
				echo -n 'Wrong or empty BROWSER value! Enter a browser: '; read BROWSER
			fi

			if [ -z "${BROWSER}" ]  ||  [ ! -x "${BROWSER}" ];then
				echo "Wrong or empty BROWSER value: '${BROWSER}'"
			else
				echo "Executing: ${BROWSER} ${url}"
				( ${BROWSER} "${url}" )
			fi
		;;
	esac
done
