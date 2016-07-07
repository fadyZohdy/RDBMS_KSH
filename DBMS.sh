#!/usr/bin/ksh

viewDatabases() {
	ls databases
	read
}

createDatabase() {
	echo enter database name
	read name
	if [[ `ls databases/ | grep -x $name` ]]; then
	echo this database already exists
	else
	mkdir databases/$name;
	echo database $name has been created
	fi
	read
}

dropDatabase() {
	cd databases/
	#get the databases and display them as choices to the user
	select choice in */;
	do
	test -n "$choice" && break;
	done
	rm -r $choice
	cd ..
}


createTable(){
	echo enter table name
	read name
	ctable=$name
	if [[ `ls | grep -x $name` ]]; then
		echo this table already exists
	else
		touch $name
		metadataTable='.'$name'.metadata'
		touch $metadataTable
		flag='true'
		while [[ $flag = 'true' ]] do
		echo "enter number of columns ?!"
		read colNum
		if [[ $colNum > 0 ]]; then
			typeset -i counter=0
			while [[ $counter -lt $

			]] do
				addCol $metadataTable
				counter=$counter+1
			done
			flag='false'
			echo table created successfully
			read
		else
		echo please enter a valid number
		fi
		done
		echo choose column as PK?
		echo $metadataTable
		select choice in `cut -d : -f1 $metadataTable`;
		do
		test -n "$choice" && break;
		done
		sed -i "/^\<$choice\>/ s/$/:PK/" '.'$ctable'.metadata'
		echo $choice is the new new primary column
	fi
	read
}

dropTable() {
	#get the tables and display them as choices to the user
	select choice in *;
	do
	test -n "$choice" && break;
	done
	rm $choice
	rm '.'$choice$'.metadata'
	echo table $choice was removed successfully
	read
}

insert() {
	table=$1
	metadata='.'$table'.metadata'
	clear
	for column in `cut -d : -f1 $metadata`
	do
		while :
		do
		flag='false'
		dataType=`sed -n "/^\<$column\>/p" $metadata | cut -d: -f2`
		echo -n "$column [$dataType] = "
		read value
			if [[ `sed -n "/^\<$column\>/p" $metadata | cut -d : -f3` ]]; then
				pkColNum=`sed -n "/^\<$column\>/=" $metadata`
				if [[ `cut -d : -f $pkColNum $table | grep -x $value` ]]; then
					flag='true'
				fi
			fi
			if [[ "$value" == +([0-9]) ]] && [[ "$dataType" == 'number' ]]; then

				if [[ $flag == 'true' ]]; then
					print 'You must enter unique value in primary key column'
					read -s -n 1
					continue
				else
					values+=("$value")
					break
				fi
			elif [[ "$value" == +([a-zA-Z]) ]] && [[ "$dataType" == 'character' ]]; then
				if [[ $flag == 'true' ]]; then
					print 'You must enter unique value in primary key column'
					read -s -n 1
					continue
				else
					values+=("$value")
					break
				fi
			elif [[ "$value" == +([0-9|a-z|A-Z|@|-|_|.]) ]] && [[ "$dataType" == 'mix' ]]; then
				if [[ $flag == 'true' ]]; then
					print 'You must enter unique value in primary key column'
					read -s -n 1
					continue
				else
					values+=("$value")
					break
				fi
			else
				print 'Invalid datatype'
				read -s -n 1
				continue
			fi
		done
	done
	echo ${values[@]} | tr ' ' ':' >>$table
	values=()
	echo all data inserted
	read
}

delete() {
	table=$1
	metadata='.'$table'.metadata'
	echo choose the column you want to operate on
	#get the columns and display them as choices to the user
	select choice in `cut -d : -f1 $metadata`
	do
		test -n "$choice" && break;
	done
	pkColNum=`sed -n "/^\<$choice\>/=" $metadata`
	echo $pkColNum
	echo enter the value
	read value
	if [[ `cut -d : -f $pkColNum $table | grep -x $value` ]]; then
		#remove the column by doing in-place modification with zero length extension thus removing the need to make a backup file
		sed -i'' "/$value/d" $table
		echo rows were removed successfully
		read
	else
	echo this value doesnt exist
	read
	fi
}

selectFromTable() {
	table=$1
	metadata='.'$table'.metadata'
	echo choose the column you want to operate on
	#get the columns and display them as choices to the user
	select choice in `cut -d : -f1 $metadata`
	do
		test -n "$choice" && break;
	done
	colNum=`sed -n "/^\<$choice\>/=" $metadata`
	clear
	echo "select from $table where $choice = "
	read value
	if [[ `cut -d : -f $colNum $table | grep -x $value` ]]; then
		awk -F: -v temp="$colNum" -v val="$value" '{if($temp==val)print $0;}' $table | tr ':' ' - '
		read
	else
	echo this value doesnt exist
	read
	fi
}

update() {
	table=$1
	metadata='.'$table'.metadata'
		isUnique=''
		echo 'choose the column you want to search in'
		#get the columns and display them as choices to the user
		select searchCol in `cut -d : -f1 $metadata`
		do
			test -n "$searchCol" && break;
		done
		echo choose the column you want to operate on
		#get the columns and display them as choices to the user
		select updateCol in `cut -d : -f1 $metadata`
		do
			test -n "$updateCol" && break;
		done
		#check if the update column is primary or not
		if [[ `sed -n "/^\<$updateCol\>/p" $metadata | cut -d: -f3` ]]; then
			isUnique='true'
		fi
		searchColNum=`sed -n "/^\<$searchCol\>/=" $metadata`
		updateColNum=`sed -n "/^\<$updateCol\>/=" $metadata`
		updateColDataType=`sed -n "/^\<$updateCol\>/p" $metadata | cut -d: -f2`
		print 'enter the search keyword'
		read searchKeyWord
		print 'enter the new value'
		echo -n "$updateCol [$updateColDataType] : "
		read newValue
		#check if the update column is primary and the new value already exists in this column
		if [[ $isUnique == 'true' ]] && [[ `cut -f"$updateColNum" -d: $table | grep -x "$newValue"` ]]; then
			clear
			print 'Primary key columns are unique identifiers that cant have duplicated values'
			read
			#read again
			continue
		fi
		awk -F: -v colNumber="$updateColNum" -v searchVal="$searchKeyWord" -v searchCol="$searchColNum" -v newValue="$newValue" '{if($searchCol==searchVal)$colNumber=newValue}1' $table |tr ' ' ':' > tmp && mv tmp $table
		echo all data updated
		break
	read

}

operateOnTable() {
	echo choose the table
	#get the tables and display them as choices to the user
	select operateOnTableChoice in *;
	do
	test -n "$operateOnTableChoice" && break;
	done
	while :
	do
		clear
		echo " _______________________________"
		echo " 1. insert "
		echo " 2. select "
		echo " 3. delete "
		echo " 4. update "
		echo " 5. Exit "
		echo " _______________________________"
		echo "Enter Choice: "
		read ch

		case $ch in

			    1) insert $operateOnTableChoice;;
			    2) selectFromTable $operateOnTableChoice;;
			    3) delete $operateOnTableChoice ;;
			    4) update $operateOnTableChoice ;;
			    5) break ;;
			    *) echo " Wrong Choice "
		esac
	done
}

addCol() {
	clear
	table=$1
	echo enter column name
		read name
		echo 'choose column type'
		echo " _______________________________"
		echo " 1. character "
		echo " 2. number "
		echo " 3. mix "
		echo " 4. Exit    "
		echo " _______________________________"
		echo "Enter Choice: "
		read ch
		case $ch in

			    1) colType="character";;
			    2) colType="number" ;;
			    3) colType="mix" ;;
			    4) break ;;
			    *) echo " Wrong Choice "; continue;;
		esac
	echo "$name:$colType" >> $table
}

deleteCol() {
	echo $1
	table=$1
	metadata='.'$table'.metadata'
	echo 'choose the column you want to delete'
		#get the columns and display them as choices to the user
		select column in `cut -d : -f1 $metadata`
		do
			test -n "$column" && break;
		done
	colNum=`sed -n "/^\<$column\>/=" $metadata`
	#check if the column exists in the table metadata file
		if [[ `cut -d : -f1 $metadata | grep -x $column` ]]; then
			if [[ `sed -n "/^\<$column\>/p" $metadata | cut -d : -f3` ]]; then
				echo "can't delete column with primary key"
			else
				#remove the column by doing in-place modification with zero length extension thus removing the need to make a backup file
				sed -i'' "/$column/d" $metadata
				#cut -d : -f$colNum- $table > tmp && mv tmp $table
				echo column $column was removed succesfully
			fi
		else
		echo this column doesnt exist
		fi

	read
}

changePK() {
	metadata=$1
	echo choose the column with the new primary key
	select choice in `cut -d : -f1 $metadata`;
	do
	test -n "$choice" && break;
	done
	cut -d: -f1,2 $metadata >tmp && mv tmp $metadata
	sed -i "/^\<$choice\>/ s/$/:PK/" $metadata
	echo $choice is the new new primary column
	read
}

alterTable() {
	echo choose the table
	#get the tables and display them as choices to the user
	select PKchoice in *;
	do
	test -n "$PKchoice" && break;
	done
	while :
	do
		clear
		echo " _______________________________"
		echo " 1. add column "
		echo " 2. delete column "
		echo " 3. change PK "
		echo " 4. Exit "
		echo " _______________________________"
		echo "Enter Choice: "
		read ch

		case $ch in

			    1) addCol '.'$PKchoice'.metadata';;
			    2) deleteCol $PKchoice;;
			    3) changePK '.'$PKchoice'.metadata';;
			    4) break ;;
			    *) echo " Wrong Choice "
		esac
	done
}

tablesHome() {
	while :
	do
		clear
		echo " _______________________________"
		echo " 1. create table  "
		echo " 2. alter table  "
		echo " 3. drop table  "
		echo " 4. view tables "
		echo " 5. operate on table "
		echo " 6. Exit "
		echo " _______________________________"
		echo "Enter Choice: "
		read ch

		case $ch in

			    1) createTable;;
			    2) alterTable ;;
			    3) dropTable ;;
			    4) ls; read ;;
			    5) operateOnTable ;;
			    6) break;;
			    *) echo " Wrong Choice "
		esac
	done
}

selectDatabase() {
	cd databases/
	#get the databases and display them as choices to the user
	select choice in */;
	do
	test -n "$choice" && break;
	done
	cd $choice
	tablesHome
	cd ..
	cd ..

}

alterDbName() {
	cd databases/
	#get the databases and display them as choices to the user
	if [[ `ls` ]]; then
	select choice in */;
	do
		test -n "$choice" && break;
	done
	while :
	do
		echo enter new name
		read newName
		if [ ! -d $newName ]; then
			mv $choice $newName
			break
		else
		echo folder already exists
		fi
	done
	else
		echo no databases to alter its name
	fi
	cd ..
}

while :
	do
		clear
		echo " _______________________________"
		echo " 1. create database "
		echo " 2. view databases "
		echo " 3. alter database name "
		echo " 4. select database "
		echo " 5. drop database "
		echo " 6. Exit    "
		echo " _______________________________"
		echo "Enter Choice: "
		read ch

		case $ch in

			    1) createDatabase;;
			    2) viewDatabases ;;
			    3) alterDbName ;;
			    4) selectDatabase ;;
			    5) dropDatabase ;;
			    6) clear; exit;;
			    *) echo " Wrong Choice "
		esac
	done
