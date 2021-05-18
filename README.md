# YadProxy

## Что это?

Своего рода API, делающий запросы в Yandex.Disk и выставляющий наружу листинг публично доступных файлов.

## Зачем это нужно?

В моём случае Yandex.Disk хранит файлы пакетов для Slackware. Пакетов мало, поэтому бесплатного тарифа вполне
достаточно.

## Как это работает?

При загрузке файлов на диск сохраняется список урлов, по которым эти файлы будут доступны через веб-часть.

## Как это запустить?

Для запуска понадобятся:

* Аккаунт @yandex.ru, через который это всё будет работать
* uwsgi версии 2.0.15 или новее с поддержкой psgi
* perl-5.18 или новее (вплоть до 5.32.x)
* пакеты perl-App-cpanminus и perl-local-lib

Предполагается, что придётся подтянуть модули из CPAN-а с помощью [cpanm][4]. Для этого есть скрипт **bootstrap.sh**

Как только всё вышеописанное в арсенале появится, можно переходить к [регистрации][1] приложения. Для работы понадобятся
все привилегии в разделе **Яндекс.Диск REST API**. Полученные ID и Пароль надо вписать в **data/config.json**, пример
конфига **data/sample_config.json**. Также надо убедиться, что параметр "Код подтверждения" либо отсутствует в конфиге,
либо закоментирован.

Как только дело сделано, можно переходить к получению access_token. Для чего запускаем **bin/yad_get_token.pl**
переходим по ссылке, разрешаем приложению доступы и полученный "Код подтверждения" копи-пастим в конфиг.

Запускаем **bin/yad_get_token.pl** повторно, чтобы он внёс в локальную базку все необходимые данные. После этого
приложениями можно пользоваться.

Веб-часть я запускаю как [PSGI][2]-приложение, через [UWSGI][3].
```
/usr/bin/uwsgi --yaml /var/lib/yadproxy/yadproxy.yaml
```

## Статус пректа

RC. Пока он *не готов*, хотя в принципе работает. Формально, он выйдет в релиз, как только закончатся пункты из файла
TODO. :)

Ясное дело, что для серьёзного prodution-а это приложение не годится, во всяком случае в таком виде, как оно есть.
Как минимум необходимо организовать кэширование. Соответственно, корректно выдавать expires со стороны приложения,
чтобы, например, nginx мог без проблем кэшировать контент через proxy_cache.

## Завендоренные библиотеки

1. [Yandex::OAuth][5]
2. [Yandex::Disk][6]

[1]: https://oauth.yandex.ru/
[2]: https://uwsgi-docs.readthedocs.io/en/latest/Perl.html
[3]: https://github.com/unbit/uwsgi
[4]: https://github.com/miyagawa/cpanminus
[5]: https://metacpan.org/pod/Yandex::OAuth
[6]: https://metacpan.org/pod/Yandex::Disk