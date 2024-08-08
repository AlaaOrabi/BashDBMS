#!/bin/bash

# Function to display the main menu
main_menu() {
    clear
    echo "Main Menu:"
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"
    read -p "Choose an option: " choice

    case $choice in
        1) create_database ;;
        2) list_databases ;;
        3) connect_to_database ;;
        4) drop_database ;;
        5) exit 0 ;;
        *) echo "Invalid option"; main_menu ;;
    esac
}

# Function to create a database
create_database() {
    read -p "Enter database name: " db_name
    mkdir -p "./$db_name"
    echo "Database '$db_name' created."
    sleep 10
    main_menu
}

# Function to list databases
list_databases() {
    echo "Databases:"
    ls -d */
    sleep 10
    main_menu
}

# Function to connect to a database
connect_to_database() {
    read -p "Enter database name: " db_name
    if [ -d "./$db_name" ]; then
        database_menu $db_name
    else
        echo "Database '$db_name' does not exist."
        main_menu
    fi
}

# Function to drop a database
drop_database() {
    read -p "Enter database name: " db_name
    rm -r "./$db_name"
    echo "Database '$db_name' dropped."
    sleep 3
    main_menu
}

# Function to display the database menu
database_menu() {
    local db_name=$1
    clear
    echo "Connected to Database: $db_name"
    echo "1. Create Table"
    echo "2. List Tables"
    echo "3. Drop Table"
    echo "4. Insert into Table"
    echo "5. Select From Table"
    echo "6. Delete From Table"
    echo "7. Update Table"
    echo "8. Disconnect"
    read -p "Choose an option: " choice

    case $choice in
        1) create_table $db_name ;;
        2) list_tables $db_name ;;
        3) drop_table $db_name ;;
        4) insert_into_table $db_name ;;
        5) select_from_table $db_name ;;
        6) delete_from_table $db_name ;;
        7) update_table $db_name ;;
        8) main_menu ;;
        *) echo "Invalid option"; database_menu $db_name ;;
    esac
}

# Function to create a table
create_table() {
    local db_name=$1
    read -p "Enter table name: " table_name
    read -p "Enter columns (name:type,name:type): " columns
    read -p "Enter primary key column: " primary_key

    echo "$columns" > "./$db_name/$table_name.meta"
    echo "PRIMARY_KEY:$primary_key" >> "./$db_name/$table_name.meta"
    touch "./$db_name/$table_name.data"
    echo "Table '$table_name' created with columns '$columns'."
    sleep 3
    database_menu $db_name
}

# Function to list tables
list_tables() {
    local db_name=$1
    echo "Tables:"
    ls "./$db_name" | grep -v ".meta"
    sleep 3
    database_menu $db_name
}

# Function to drop a table
drop_table() {
    local db_name=$1
    read -p "Enter table name: " table_name
    rm "./$db_name/$table_name.meta" "./$db_name/$table_name.data"
    echo "Table '$table_name' dropped."
    database_menu $db_name
}

# Function to insert into a table
insert_into_table() {
    local db_name=$1
    read -p "Enter table name: " table_name

    if [ ! -f "./$db_name/$table_name.meta" ]; then
        echo "Table '$table_name' does not exist."
        database_menu $db_name
        return
    fi

    columns=$(head -n 1 "./$db_name/$table_name.meta")
    primary_key=$(tail -n 1 "./$db_name/$table_name.meta" | cut -d':' -f2)
    IFS=',' read -ra col_arr <<< "$columns"
    row=""

    for col in "${col_arr[@]}"; do
        IFS=':' read -ra col_parts <<< "$col"
        read -p "Enter value for ${col_parts[0]} (${col_parts[1]}): " value

        if [ "${col_parts[0]}" == "$primary_key" ]; then
            if awk -F'|' -v pk="$value" '$1 == pk' "./$db_name/$table_name.data" | grep -q .; then
                echo "Error: Duplicate value for primary key."
                insert_into_table $db_name
                return
            fi
        fi

        row="$row$value|"
    done

    echo "${row%?}" >> "./$db_name/$table_name.data"
    echo "Row inserted into '$table_name'."
    database_menu $db_name
}

# Function to select from a table
select_from_table() {
    local db_name=$1
    read -p "Enter table name: " table_name

    if [ ! -f "./$db_name/$table_name.meta" ]; then
        echo "Table '$table_name' does not exist."
        database_menu $db_name
        return
    fi

    echo "Table: $table_name"
    awk -F'|' '{
        for (i=1; i<=NF; i++) {
            printf "%-15s", $i
        }
        printf "\n"
    }' "./$db_name/$table_name.data"
    sleep 10
    database_menu $db_name
}

# Function to delete from a table
delete_from_table() {
    local db_name=$1
    read -p "Enter table name: " table_name

    if [ ! -f "./$db_name/$table_name.meta" ]; then
        echo "Table '$table_name' does not exist."
        database_menu $db_name
        return
    fi

    read -p "Enter primary key value to delete: " pk_value
    awk -F'|' -v pk="$pk_value" '$1 != pk' "./$db_name/$table_name.data" > temp.data && mv temp.data "./$db_name/$table_name.data"
    echo "Row with primary key '$pk_value' deleted from '$table_name'."
    database_menu $db_name
}

# Function to update a table
update_table() {
    local db_name=$1
    read -p "Enter table name: " table_name

    if [ ! -f "./$db_name/$table_name.meta" ]; then
        echo "Table '$table_name' does not exist."
        database_menu $db_name
        return
    fi

    read -p "Enter primary key value to update: " pk_value
    columns=$(head -n 1 "./$db_name/$table_name.meta")
    IFS=',' read -ra col_arr <<< "$columns"
    row=""

    for col in "${col_arr[@]}"; do
        IFS=':' read -ra col_parts <<< "$col"
        read -p "Enter new value for ${col_parts[0]} (${col_parts[1]}): " value
        row="$row$value|"
    done

    awk -F'|' -v pk="$pk_value" '$1 != pk' "./$db_name/$table_name.data" > temp.data
    echo "${row%?}" >> temp.data
    mv temp.data "./$db_name/$table_name.data"
    echo "Row with primary key '$pk_value' updated in '$table_name'."
    database_menu $db_name
}

main_menu
