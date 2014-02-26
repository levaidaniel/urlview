#!/bin/sh

# Copyright LEVAI Daniel <leva@ecentrum.hu>
# Distributed under the 2-clause BSD license (see LICENSE file)


# If you don't want to weed out duplicate URLs in the resulting list,
# set this to 0.
typeset -i SORTING=1


typeset -i i=0
typeset -i nword=0

URL_PATTERN='https*://[[:alnum:]:./?=&_-]+'
for word in $(tr '\n' ' ');do
	nword=$(( nword + 1 ))

	[ $(( $nword % 50 )) -eq 0 ]  &&  printf "$0: $nword ...\r"

	while [[ "${word}" = *http*(s)://* ]];do
		url=$( echo ${word} |sed -r -e "s,(.*)(${URL_PATTERN})(.*),\2," )
		word=$( echo ${word} |sed -r -e "s,(.*)(${URL_PATTERN})(.*),\1\3," )

		URLS[$i]=${url}
		i=$(( i + 1 ))
	done
done
unset nword
unset word
unset url


printf "== URL viewer: $0 ==\n\n"
printf "BROWSER is '${BROWSER:-<empty>}'\n\n"

if [ ${#URLS[@]} -eq 0 ];then
	echo "No URLs found."
	exit 0;
fi

exec <&-
exec 0</dev/tty


if [ ${SORTING} -gt 0 ];then
	# Sort the array of URLs
	i=0
	for url in $(echo ${URLS[@]} |tr ' ' '\n' |sort |uniq);do
		URLS[$i]=${url}
		i=$(( i + 1 ))
	done
	# Erase the leftover items from the previous, unsorted array
	while [ ${#URLS[@]} -gt $i ];do
		unset URLS[$(( ${#URLS[@]} - 1 ))]
	done
fi
unset i


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

	echo ''
done
