#!/bin/bash

channel_logo() {
    echo -e "\n\nПідпишись на найкращий канал про ноди — @NodeUA [💸]"
}

download_node() {
  if [ -d "$HOME/.titanedge" ]; then
    echo "Папка .titanedge вже існує. Видаліть ноду та встановіть заново. Вихід..."
    return 0
  fi

  sudo apt install lsof -y

  ports=(1234 55702 48710)

  for port in "${ports[@]}"; do
    if [[ $(lsof -i :"$port" | wc -l) -gt 0 ]]; then
      echo "Помилка: Порт $port зайнятий. Програма не зможе виконатись."
      exit 1
    fi
  done

  echo -e "Всі порти вільні! Починається встановлення...\n"

  echo 'Починаю встановлення...'

  cd $HOME

  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install nano git gnupg lsb-release apt-transport-https jq screen ca-certificates curl -y

  if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
  else
    echo "Docker вже встановлений. Пропускаємо."
  fi

  if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  else
    echo "Docker-Compose вже встановлений. Пропускаємо."
  fi

  echo 'Усі необхідні залежності встановлені. Запустіть ноду за допомогою пункту 2.'
}

launch_node() {
  docker ps -a --filter "ancestor=nezha123/titan-edge" --format "{{.ID}}" | while read container_id; do
    docker stop "$container_id"
    docker rm "$container_id"
  done

  while true; do
    echo -en "Введіть ваш HASH: "
    read HASH
    if [ ! -z "$HASH" ]; then
        break
    fi
    echo 'HASH не може бути порожнім.'
  done

  docker run --network=host -d -v ~/.titanedge:$HOME/.titanedge nezha123/titan-edge
  sleep 10

  docker run --rm -it -v ~/.titanedge:$HOME/.titanedge nezha123/titan-edge bind --hash=$HASH https://api-test1.container1.titannet.io/api/v2/device/binding

  echo -e "Ноду запущено."
}

delete_node() {
  echo "Зупиняємо та видаляємо контейнер..."
  docker ps -a --filter "ancestor=nezha123/titan-edge" --format "{{.ID}}" | while read container_id; do
    docker stop "$container_id"
    docker rm "$container_id"
  done

  echo "Видаляємо директорію ~/.titanedge"
  rm -rf ~/.titanedge

  echo "Ноду повністю видалено."
}

main_menu() {
  channel_logo
  echo -e "\nМеню:"
  echo "1. Встановити ноду"
  echo "2. Запустити ноду"
  echo "3. Видалити ноду"
  echo "4. Вийти"

  read -p "Оберіть пункт меню: " choice
  case $choice in
    1) download_node ;;
    2) launch_node ;;
    3) delete_node ;;
    4) exit 0 ;;
    *) echo "Невірний вибір. Спробуйте ще раз." ; main_menu ;;
  esac
}

main_menu
