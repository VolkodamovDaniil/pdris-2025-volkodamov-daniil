По классике проверяем `docker-compose ps`:

![ps](images/ps.png)

Заходим в контейнер и настраиваем ssh:

![ssh1](images/ssh1.png)

![ssh2](images/ssh2.png)

Проверяем подключение:

![ping](images/ping.png)

Также возникала необходимость ввести команду `chmod 755 /home/admin/ansible`, иначе не читался `ansible.cfg`.

Наконец, запуск плейбука `ansible-playbook playbooks/main.yml -i inventory.ini` и результат:

![playbook](images/playbook.png)

Также проверим корректность работы nginx и приложения напрямую:

![host](images/host.png)

![server](images/server.png)