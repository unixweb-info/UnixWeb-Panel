# UnixWeb Panel

Добро пожаловать в проект UnixWeb Panel! Этот сценарий Bash предоставляет комплексную панель управления для управления вашим стеком LEMP, который включает Linux, Nginx, MySQL (MariaDB) и PHP. Панель UnixWeb позволяет вам эффективно управлять серверной средой и контролировать ее, упрощая выполнение различных административных задач.

![UnixWeb Panel](https://github.com/unixweb-info/UnixWeb-Panel/blob/main/UnixWebPanel.jpg)

Этот скрипт предназначен для автоматизации управления сервером с упором на информационную безопасность. На данный момент ряд запланированных функций еще не реализован, но ожидается внедрение следующих возможностей:

- Настройка профилей SELinux для повышения безопасности и контроля доступа.
- Реализация ModSecurity как модуля для Nginx для обнаружения и предотвращения атак на веб-приложения.
— Настройка Fail2ban для автоматического реагирования на подозрительную активность.

Кроме того, планируется интегрировать следующие меры безопасности и управления:

- Установка и настройка фаервола (например, iptables) для фильтрации сетевого трафика.
- Регулярные проверки безопасности и аудит системы для выявления потенциальных уязвимостей.
- Настройка системы резервного копирования данных и механизмов восстановления для обеспечения надежности данных.
- Реализация мониторинга журналов системы и приложений для оперативного реагирования на инциденты.

## Поддерживаемые операционные системы

Сценарий UnixWeb Panel поддерживает следующие операционные системы:
- **Поток CentOS 9**
- **AlmaLinux 9.x (Seafoam Ocelot)**
- **Rocky Linux 9.x (Синий Оникс)**

Перед использованием сценария убедитесь, что на вашем сервере установлена ​​одна из этих поддерживаемых операционных систем.

## Поддерживаемая CMS

- WordPress
- 1С-Битрикс
- Джумла
- Революция MODX
- ОпенКарт
- Друпал
- Движок DataLife
- Webasyst CMS (Магазин-скрипт)
- UMI.CMS
- cs.cart

## Поддерживаемые версии PHP

- PHP-7.4
- PHP-8.0
- PHP-8.1
- PHP-8.2
- PHP-8.3

## Поддерживаемые версии MariaDB

- МарияДБ-10.4
- МарияДБ-10.5
- МарияДБ-10.6
- МарияДБ-10.10
- МарияДБ-10.11
- МарияДБ-11.0
- МарияДБ-11.1
- МарияДБ-11.2
- МарияДБ-11.4

## Функции

### Управление услугами
- **Управление MariaDB**: проверяет, установлена ​​ли и работает ли MariaDB. Если нет, он устанавливает и запускает службу.
- **Управление Nginx**: добавляет в вашу систему официальный репозиторий Nginx.

### Управление репозиторием
- **Репозиторий Nginx**: добавляет в вашу систему как стабильные, так и основные репозитории Nginx.
- **Репозиторий EPEL**: проверяет наличие репозитория EPEL, устанавливает его, если он отсутствует, и обновляет систему.

### Конфигурация брандмауэра
- **Установка Iptables**: устанавливает iptables-services, если они еще не установлены.
- **Настройка правил по умолчанию**: настраивает правила iptables по умолчанию для защиты вашего сервера, включая разрешение трафика на портах 22 (SSH), 80 (HTTP) и 443 (HTTPS).

### Управление SELinux
- **Проверка состояния SELinux**: проверяет, находится ли SELinux в принудительном режиме, и при необходимости переводит его в разрешающий режим.

## Предварительные условия

- Скрипт должен быть запущен от имени пользователя root.

## Использование

Чтобы использовать этот скрипт, выполните следующие действия:

1. **Убедитесь, что вы являетесь пользователем root**: для выполнения сценария требуются права root.
2. **Запустить сценарий**: выполнить сценарий с терминала.

**Установите панель UnixWeb**
``` баш
wget https://raw.githubusercontent.com/unixweb-info/UnixWeb-Panel/main/UnixWebPanelDemo.sh && chmod +x ./UnixWebPanelDemo.sh && sudo ./UnixWebPanelDemo.sh --install
```

**Использование панели UnixWeb**
``` баш
sudo ./UnixWebPanelDemo.sh
```

### Подробные шаги

1. **Проверка совместимости ОС**: сценарий проверяет, поддерживается ли ваша операционная система, сверяясь со списком поддерживаемых версий ОС.
2. **Управление MariaDB**: проверяет, установлена ​​ли MariaDB. Если нет, он устанавливает MariaDB и обеспечивает работу службы.
3. **Добавить репозиторий Nginx**. Скрипт добавляет официальный репозиторий Nginx, предоставляя опции как для стабильной, так и для основной версии.
4. **Добавить репозиторий EPEL**. Он проверяет, включен ли репозиторий EPEL, и устанавливает его, если нет, после чего следует обновление системы.
5. **Конфигурация брандмауэра**: сценарий устанавливает iptables-services, отключает firewalld и настраивает правила iptables по умолчанию для защиты вашего сервера.
6. **Конфигурация SELinux**: проверяет текущий режим SELinux и устанавливает для него разрешительный режим, если он находится в принудительном режиме.

## Функции

### error_exit
Отображает сообщение об ошибке и завершает сценарий.

### check_os
Проверяет, поддерживается ли текущая операционная система.

### display_header
Отображает приветственный заголовок с информацией о проекте.

### display_header_warning
Отображает заголовок с предупреждающим сообщением.

### check_and_run_mariadb
Проверяет, установлена ​​ли и работает ли MariaDB, если нет, устанавливает ее.

### add_nginx_repo
Добавляет официальный репозиторий Nginx.

### add_epel_repo
Добавляет репозиторий EPEL, если его еще нет.

### create_default_rules
Создает и применяет правила iptables по умолчанию.

### install_iptables
Устанавливает iptables-services и настраивает iptables.

### check_and_run_iptables
Проверяет, установлен ли и запущен ли iptables-services, если нет, устанавливает его.

### check_selinux_status
Проверяет текущий статус SELinux и устанавливает его в разрешительный режим, если он находится в принудительном режиме.

Здесь описаны не все функции; тот, кто хочет понять код, поймет его. Скрипт довольно простой.

## Контакт

Для получения дополнительной информации или вопросов по скрипту вы можете связаться со мной по следующим контактам:

- **Telegram**: [UnixWebAdmin_info](https://t.me/UnixWebAdmin_info)
- **WhatsApp**: +995 593-245-168
- **Веб-сайт**: [UnixWeb.info](https://UnixWeb.info)

Готов оказать поддержку и консультацию по настройке и использованию скрипта для вашего сервера.

## Лицензия

Этот проект распространяется по лицензии GNU General Public License v3.0.

---

Автор Крячко Алексей © 2024. Приятного использования панели управления LEMP!
