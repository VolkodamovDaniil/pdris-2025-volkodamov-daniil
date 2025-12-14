Собираем наше приложение с помощью `docker-compose up` и проверяем через `docker-compose ps`.

![first-compose](images/first-compose.png)

Запускаем скрипт отправки в registry:

![registry](images/registry.png)

Убеждаемся, что всё загрузилось, на https://hub.docker.com:

![hub](images/hub.png)

Также проверим работоспособность `docker pull`:

![pull](images/pull.png)

Теперь соберём приложение с образом из registry:

![second-compose](images/second-compose.png)

И убедимся, что оно работает:

![api](images/api.png)