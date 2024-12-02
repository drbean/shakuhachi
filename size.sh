#!env bash

function length () {
	OPTIND=1
	local arg pipe
	while getopts 'p:' arg
	do 
		case ${arg} in
			p) pipe=${OPTARG};;
			*) return 1
		esac
	done
	export pipe hole
	total=$(yq ".$pipe.length" measurement.yaml)
	# total=551
	echo $total
}

function ratio () {
	OPTIND=1
	local arg pipe hole
	while getopts 'p:h:' arg
	do 
		case ${arg} in
			p) pipe=${OPTARG};;
			h) hole=${OPTARG};;
			*) return 1
		esac
	done
	export pipe hole
	total=$(length -p $pipe)
	# total=551
	to_hole=$(yq ".$pipe.hole.from_top.$hole" measurement.yaml)
	# to_hole=233
	ratio=$(echo 5 k $to_hole $total / p | dc)
	echo $ratio
}

function position () {
	OPTIND=1
	local arg pipe hole
	while getopts 'p:h:' arg
	do 
		case ${arg} in
			p) pipe=${OPTARG};;
			h) hole=${OPTARG};;
			*) return 1
		esac
	done
	export pipe hole
	ratio=$(ratio -p $pipe -h $hole)
	# ratio=.42962
	total=$(length -p $pipe)
	to_position=$(echo "$total $ratio * p" | dc)
	printf '%.0f' $to_position
}

function display () {
	echo -e "\nhole position"
	echo -e "\t\t5   4   3   2   1   length"
	for p in $(yq "to_entries | .[] | .key" measurement.yaml) ; do
		echo -ne "$p\t"
		for i  in {5..1} ; do
			printf '%s' $(position -p $p -h $i) ; echo -n " "
		done
		length -p $p
	done
	echo -e "\nposition ratio"
	echo -e "\t\t5\t4\t3\t2\t1"
	for p in $(yq "to_entries | .[]  | .key" measurement.yaml) ; do
		echo -ne "$p\t"
		for i in {5..1} ; do
			printf '%s' $(ratio -p $p -h $i) ; echo -n " "
		done
		echo
	done
}

function standard () {
	yq -n ".standard.length=$(echo 1 k $(declare -i lengthp 
		lengthp=0
		for p in matsumoto tanimura matsuda ; do
			lengthp+=$(length -p $p)
		done
		echo $lengthp) 3 / p | dc )"
	for i in {5..1} ; do yq -n ".standard.hole.from_top.$i=$(echo 1 k \
		$(declare -i holep
		holep=0
		for p in matsumoto tanimura matsuda ; do
			holep+=$(position -p $p -h $i)
		done
		echo $holep) 3 / p | dc )"
	done
}

function clone () {
	yq -n "with(.foundling.hole.from_top;
		.1 = $(echo 0 k $(length -p foundling) \
			$(ratio -p standard -h 1) '*' p | dc) |
		.2 = $(echo 1 k $(length -p foundling) \
			$(ratio -p standard -h 2) '*' p | dc) |
		.3 = $(echo 1 k $(length -p foundling) \
			$(ratio -p standard -h 3) '*' p | dc) |
		.4 = $(echo 1 k $(length -p foundling) \
			$(ratio -p standard -h 4) '*' p | dc) |
		.5 = $(echo 1 k $(length -p foundling) \
			$(ratio -p standard -h 5) '*' p | dc)
	)"
}

function from_bottom () {
	OPTIND=1
	local pipe hole args
	while getopts 'p:h:' arg
	do 
		case ${arg} in
			p) pipe=${OPTARG};;
			h) hole=${OPTARG};;
			*) return 1
		esac
	done
	export pipe hole
	length=$(length -p $pipe)
	from_top=$(position -p $pipe -h $hole)
	from_bottom=$(echo 1 k $length $from_top - p | dc )
	echo $from_bottom
}
