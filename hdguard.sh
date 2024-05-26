#!/bin/bash
declare -i free_space limit
limit=$1
disk_name=$(lsblk | grep disk | head -n1 | cut -d " " -f1)

disk_space_check() {
    while : ; do
        clear
        free_space=100-$(df --output=pcent /home/$USER | tr -dc '0-9')
        [[ $free_space -ge $limit ]] || break
        echo "Nazwa dysku to $disk_name, nazwa partycji to /home/$USER, wolne jest $free_space"%" miejsca na partycji."
        free_space=100-$(df --output=pcent /home/$USER | tr -dc '0-9')
        echo "Odświeżone dane zostaną wyświetlone za minute."
        sleep 60
    done
}

user_input_check() {
    if [ $limit -lt 10  ] || [ $limit -gt 100 ]; then
        echo "Wartość graniczna powinna być większa od 10 oraz mniejsza 100." 
        echo "Proszę uruchomić skrypt ponownie podając poprawną wartość."
        exit 0
    fi
}

limit_exceeded() {
    declare -i choice
    while : ; do 
        echo "Ilosc miejsca na dysku jest za mała."
        echo "Wybierz 1, aby dokonać czyszczenia partycji."
        echo "Wybierz 2, aby zignorować ostrzeżenie."
        read choice
        [[ $choice != 1 ]] || break
        if [ $choice == 2 ]; then
            clear
            sleep 60
        else
            echo "Niepoprawny wybór, należy wybrać cyfrę 1 lub 2. Proszę poczekać 3 sekundy, a następnie wybrać ponownie."
            sleep 3
            clear
        fi
    done
}

deleting_files() {
    files=$(find /home/$USER -not -path '*/.*' -type f -writable -size +10k -exec du -sk {} \; | sort -rnk1) 
    declare -i choice
    while : ; do
        echo "Do usuniecia wytypowane następujące pliki, obok podana jest wielkość w kB oraz kolejność po posortowaniu: "
        files_list=$(echo "$files" | tail -n 5 | nl)
        files_list_to_delete=$(echo "$files" | tail -n 5 | nl | grep -o '/home/.*')
        echo "$files_list"
        echo "Wybierz 1 jeśli chcesz usunąć pliki, wybierz 2 jeśli chcesz je spakować i przenieść do wybranego katalogu."
        read choice
        [[ $choice == 1] || [$choice == 2 ]] || break
        echo "Bledne dane. Prosze dokonac wyboru jeszcze raz za 3 sekundy."
        sleep 3
        clear
    done
    if [ $choice == 1 ]; then
        rm $(echo "$files_list_to_delete")
    else
        hour=$(date +"%H:%M")
        day=$(date +"%d":"%m":"%Y")
        echo "Podaj pełną ścieżkę katalogu, do którego należy zarchiwizować pliki:"
        # echo "$files_list_to_delete"
        read katalog
        if [ -d "$katalog" ]; then
            tar -zcvf "$katalog"/hdguard_"$day"_"$hour".tar.gz $(echo "$files_list_to_delete") 
        else 
            mkdir $katalog
            tar -zcvf "$katalog"/hdguard_"$day"_"$hour".tar.gz $(echo "$files_list_to_delete") 
        fi
    fi
}

main () {
    user_input_check
    disk_space_check
    limit_exceeded
    deleting_files
    free_space=100-$(df --output=pcent /home/$USER | tr -dc '0-9')
    if [ $free_space -ge $limit ]; then
        echo "Osiągnięto założony limit, wracanie do monitorowania zajętości dysku."
        sleep 10
        main
    else    
        echo "Limit nie został osiągnięty, potrzebne będzie usunięcie kolejnych plików."
        sleep 10
        main
    fi
}

main