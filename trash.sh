# trash.sh - A safer alternative to rm
# Copyright (C) 2025 [Jesper Aadalen]
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/bin/bash

# Flyttar filer till ~/.TRASH istället för att radera dem permanent

TRASH_DIR=~/.TRASH
SCRIPT_NAME=$(basename "$0")

# Funktion för att visa hjälptext
show_help() {
    cat <<EOF
Användning: trash.sh [ALTERNATIV] [FIL/KATALOG...]

En säkrare version av rm. Flyttar filer till ~/.TRASH istället för att radera dem permanent.

Alternativ:
  --help         Visa denna hjälptext
  --list         Lista papperskorgens innehåll
  --size         Rapportera papperskorgens storlek
  --empty        Töm papperskorgen
  --recover FIL  Återställ en tidigare kastad fil till aktuell arbetskatalog

Exempel:
  trash.sh minfil.txt                  Flytta minfil.txt till papperskorgen
  trash.sh --recover minfil.txt        Återställ minfil.txt från papperskorgen
  trash.sh --list                      Visa papperskorgens innehåll
  trash.sh --size                      Visa papperskorgens storlek
  trash.sh --empty                     Töm papperskorgen
EOF
}

# Funktion för att skapa ~/.TRASH om den inte finns
create_trash_dir() {
    if [ ! -d "$TRASH_DIR" ]; then
        mkdir -p "$TRASH_DIR"
        echo "Created ~/.TRASH folder"
    fi
}

# Funktion för att generera ett unikt filnamn vid namnkonflikter, d.v.s. lägg till _ och en uppräknad siffra
generate_unique_name() {
    local original_path="$1"
    local target_dir="$2"
    local base_name
    base_name=$(basename "$original_path")
    local destination="$target_dir/$base_name"
    local counter=1

    while [ -e "$destination" ]; do
        destination="$target_dir/${base_name}_$counter"
        ((counter++))
    done
    basename "$destination"
}

# Funktion för att räkna mappar och filer rekursivt
count_items() {
    local dir="$1"
    local folder_count=0
    local file_count=0
    
    # Räkna alla "topp"mappar
    local top_folders
    top_folders=$(find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
    folder_count=$((folder_count + top_folders))
    
    # Räkna alla undermappar
    local sub_folders
    sub_folders=$(find "$dir" -mindepth 2 -type d | wc -l)
    folder_count=$((folder_count + sub_folders))
    
    # Räkna alla filer
    local all_files
    all_files=$(find "$dir" -type f | wc -l)
    file_count=$((file_count + all_files))
    
    echo "$folder_count $file_count"
}

# Funktion för att flytta mappar och filer till papperskorgen
# Säkerställer också att man inte slänger sig själv, d.v.s. "./trash.sh trash.sh" eller vad man nu döper sin papperskorfsfil till
trash_files() {
    create_trash_dir
    if [ "$#" -eq 0 ]; then
        echo "Error: No files or directories specified"
        echo "Try trash.sh --help"
        exit 1
    fi

    local FOLDER_COUNT=0
    local FILE_COUNT=0

    echo "Moved to trash:"
    echo "────────────────────────────────────────"

    for file in "$@"; do
        if [ "$file" = "$SCRIPT_NAME" ]; then
            echo "Error: Cannot move $SCRIPT_NAME to trash."
            continue
        fi
        if [ -e "$file" ]; then
            # Genererar ett unikt namn genom att lägga till _löpnummer efter fil eller mappnamn
            local unique_name
            unique_name=$(generate_unique_name "$file" "$TRASH_DIR")
            
            # Flyttar den namnändrade filen till papperskorgen
            mv "$file" "$TRASH_DIR/$unique_name" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error moving $file"
                continue
            fi

            local icon="📄"
            if [ -d "$TRASH_DIR/$unique_name" ]; then
                icon="📁"
                ((FOLDER_COUNT++))
                sub_folders=$(find "$TRASH_DIR/$unique_name" -mindepth 1 -type d | wc -l)
                sub_files=$(find "$TRASH_DIR/$unique_name" -type f | wc -l)
                ((FOLDER_COUNT += sub_folders))
                ((FILE_COUNT += sub_files))
            else
                ((FILE_COUNT++))
            fi

            # Visar orginalnamnet och vad den döps om till
            if [ "$unique_name" != "$(basename "$file")" ]; then
                echo " $icon $file already exists, name changed to $unique_name"
            else
                echo " $icon $file"
            fi
        else
            echo "File not found: $file"
        fi
    done

    echo "────────────────────────────────────────"
    echo "Total trashed: $FOLDER_COUNT folder(s), $FILE_COUNT file(s)"
    echo "────────────────────────────────────────"
}

# Funktion för att lista papperskorgens innehåll 
list_trash() {
    if [ ! -d "$TRASH_DIR" ] || [ -z "$(ls -A "$TRASH_DIR")" ]; then
        echo "Trash is empty"
    else
        echo "Trash contents:"
        echo "────────────────────────────────────────"
        display_directory "$TRASH_DIR" ""
        echo "────────────────────────────────────────"
    fi
}

# Hjälpfunktion för att visa katalogstruktur. Skapade denna för att kunna använda den på flera sätt. Annars hade den legat i list_trash()
display_directory() {
    local dir="$1"
    local prefix="$2"
    local items=()
 
    # Samla alla objekt i en array för sortering
    while IFS= read -r -d '' item; do
        items+=("$item")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 | sort -z)
 
    # Processa varje objekt
    local count=${#items[@]}
    local i=0
  
    for item in "${items[@]}"; do
        i=$((i+1))
        local name
        name=$(basename "$item")
        local is_last
        is_last=$([[ $i -eq $count ]] && echo 1 || echo 0)
      
        # Lägg till ikoner baserat på fil/katalogtyp
        local icon=""
        if [ -d "$item" ]; then
            icon="📁 "
        else
            icon="📄 "
        fi
        
        # Addera lite visuell trädstyling av filstrukturen för att se tydligare var allt ligger i förhållande till varandra
        if [[ $is_last -eq 1 ]]; then
            echo "${prefix}└── ${icon}${name}"
            local new_prefix="${prefix}    "
        else
            echo "${prefix}├── ${icon}${name}"
            local new_prefix="${prefix}│   "
        fi
      
        # Rekursiv anrop för kataloger
        if [ -d "$item" ]; then
            display_directory "$item" "$new_prefix"
        fi
    done
}

# Funktion för att skriva ut storlek på papperskorgen, både disk usage och faktisk storlek. Skriver dock bara ut den faktiska storleken.
report_size() {
    if [ ! -d "$TRASH_DIR" ] || [ -z "$(ls -A "$TRASH_DIR")" ]; then
        echo "Trash is empty"
    else
        # Beräknar disk usage
        local DISK_USAGE
        DISK_USAGE=$(find "$TRASH_DIR" -mindepth 1 | xargs du -ch 2>/dev/null | tail -1 | awk '{print $1}')
        
        # Beräknar den faktisk storleken på innehållet
        local SIZE_BYTES
        SIZE_BYTES=$(find "$TRASH_DIR" -type f -ls | awk '{sum += $7} END {print sum}')
        
        # Formatering av faktisk storlek
        local ACTUAL_SIZE
        if [ -z "$SIZE_BYTES" ] || [ "$SIZE_BYTES" -eq 0 ]; then
            ACTUAL_SIZE="0B"
        elif [ "$SIZE_BYTES" -lt 1024 ]; then
            ACTUAL_SIZE="${SIZE_BYTES}B"
        elif [ "$SIZE_BYTES" -lt 1048576 ]; then
            ACTUAL_SIZE="$(echo "scale=1; $SIZE_BYTES/1024" | bc)K"
        elif [ "$SIZE_BYTES" -lt 1073741824 ]; then
            ACTUAL_SIZE="$(echo "scale=1; $SIZE_BYTES/1048576" | bc)M"
        else
            ACTUAL_SIZE="$(echo "scale=1; $SIZE_BYTES/1073741824" | bc)G"
        fi
        
        # Visar storlek av innehållet i papperskorgen.
        echo "Current amount of trash: $ACTUAL_SIZE"
		echo "────────────────────────────────────────"
    fi
}

# Funktion för att tömma papperskorgen
empty_trash() {
    if [ ! -d "$TRASH_DIR" ] || [ -z "$(ls -A "$TRASH_DIR")" ]; then
        echo "Trash is already empty"
    else
        # Räknar ihop allt som ska slängas
        local counts
        counts=$(count_items "$TRASH_DIR")
        local folder_count
        local file_count
        read -r folder_count file_count <<< "$counts"
        
        # Visar vad papperskorgen innehåller
        echo "Trash contains:"
        echo "────────────────────────────────────────"
        display_directory "$TRASH_DIR" ""
        echo "────────────────────────────────────────"
        
        # Frågar för säkerhets skull om användaren verkligen vill tömma paperskorgen
        read -r -p "Are you sure you want to permanently delete $folder_count folder(s) and $file_count file(s)? (Y/N): " confirm
        case "$confirm" in
            [Yy]*)
                rm -rf "${TRASH_DIR:?}"/*
                echo "────────────────────────────────────────"
                echo "Total deleted: $folder_count folder(s), $file_count file(s)"
                echo "────────────────────────────────────────"
                echo "Trash emptied"
                ;;
            *)
                echo "Operation cancelled"
                ;;
        esac
    fi
}


# Funktion för att återställa en fil från papperskorgen
recover_trash() {
    local FOLDER_COUNT=0
    local FILE_COUNT=0
    
    echo "Recovered from trash:"
    echo "────────────────────────────────────────"

    if [ "$1" == "--all" ]; then
        # Dold funktionalitet för den late, tar tillbaka allt innehåll ur papperskorgen. Byter namn på filerna om det råkar finnas filer med samma namn.
        # generate_unique_name() används precis som för trash_file() för detta.
        for item in "$TRASH_DIR"/*; do
            if [ -e "$item" ]; then
                local basename_item
                basename_item=$(basename "$item")
                local unique_name
                unique_name=$(generate_unique_name "$item" "$(pwd)")
                
                mv "$item" "./$unique_name"
                
                local icon="📄"
                if [ -d "./$unique_name" ]; then
                    icon="📁"
                    ((FOLDER_COUNT++))
                    sub_folders=$(find "./$unique_name" -mindepth 1 -type d | wc -l)
                    sub_files=$(find "./$unique_name" -type f | wc -l)
                    ((FOLDER_COUNT += sub_folders))
                    ((FILE_COUNT += sub_files))
                else
                    ((FILE_COUNT++))
                fi
                
                if [ "$unique_name" != "$basename_item" ]; then
                    echo " $icon $basename_item already exists, name changed to $unique_name"
                else
                    echo " $icon $basename_item"
                fi
            fi
        done
    else
        for ITEM in "$@"; do
            local ITEM_PATH
            ITEM_PATH=$(find "$TRASH_DIR" -name "$ITEM" 2>/dev/null | head -1)

            if [ -z "$ITEM_PATH" ]; then
                echo "Error: $ITEM not found in trash"
                continue
            fi

            # Kontroll om filen eller mappen existerar, byter i så fall namn här med. lägger till _löpnummer i slutet på mappen/filnamnet.
            local unique_name
            unique_name=$(generate_unique_name "$ITEM_PATH" "$(pwd)")
            
            mv "$ITEM_PATH" "./$unique_name"
            
            local icon="📄"
            if [ -d "./$unique_name" ]; then
                icon="📁"
                ((FOLDER_COUNT++))
                sub_folders=$(find "./$unique_name" -mindepth 1 -type d | wc -l)
                sub_files=$(find "./$unique_name" -type f | wc -l)
                ((FOLDER_COUNT += sub_folders))
                ((FILE_COUNT += sub_files))
            else
                ((FILE_COUNT++))
            fi
            
            if [ "$unique_name" != "$ITEM" ]; then
                echo " $icon $ITEM already exists, name changed to $unique_name"
            else
                echo " $icon $ITEM"
            fi
        done
    fi
    
    echo "────────────────────────────────────────"
    echo "Total recovered: $FOLDER_COUNT folder(s), $FILE_COUNT file(s)"
    echo "────────────────────────────────────────"
}

# Huvudprogrammet
if [ "$#" -eq 0 ]; then
    show_help
    exit 0
fi

case "$1" in
    --help)
        show_help
        ;;
    --list)
        list_trash
        ;;
    --size)
        report_size
        ;;
    --empty)
        empty_trash
        ;;
    --recover)
        shift
        recover_trash "$@"
        ;;
    --*|-*) 
        echo "Unknown option: $1"
        echo "Try trash.sh --help"
        exit 1
        ;;
    *)
        trash_files "$@"
        ;;
esac

exit 0
