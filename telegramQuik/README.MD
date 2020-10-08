Решение для отправки сообщений из терминала Квик в Телеграм (telegram bot api)

В решении используется библиотека Telegram.Bot https://github.com/TelegramBots/Telegram.Bot 

Консольная программа SendTelegramMsg.exe, выполняющая функцию Named Pipe Server и Telegram Bot.
Файл settings.ini должен быть расположен рядом с SendTelegramMsg.exe.
Библиотека luaPipe.dll - библиотека передачи данных (Named Pipe) в консольную программу (сервер).
Тестовый скрипт luaPipeTest.lua

В свои скрипты необходимо подключить библиотеку luaPipe.dll, обеспечить запуск SendTelegramMsg.exe.

Чтобы собрать SendTelegramMsg необходимо установить в проект пакет Telegram.Bot
В файле settings.ini необходимо заполнить токен, полученный при регистрации бота в телеграме.
ID Чата можно получить также через телеграм или можно отправить сообщение в созданном чате бота и сервер примет его и зарегестрируется на него.
При этом будет показан ID Чата, который можно вписать в настройки.

Ссылка на собранные библиотеки https://yadi.sk/d/QLT64ucTaLrjTQ
https://youtu.be/14c4nQiDdfU
