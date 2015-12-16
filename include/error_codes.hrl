%%%-------------------------------------------------------------------
%%% @author protoj
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. июл 2014 10:57
%%%-------------------------------------------------------------------
-author("protoj").

-define(UNKNOWN_TYPE, <<"unknown">>).
-define(BUSSINES_SERVICE, <<"service_business">>).
-define(CONNECTION_TECHNICAL, <<"connection_technical">>).
-define(CLIENT, <<"client">>).
-define(SERVICE_TECHICAL, <<"service_technical">>).
-define(Err_codes(Code),
          case Code of

%%             Reserved codes from 0 -> 1000
            0 -> {<<"success">>, <<"OK. Success response from a plugin">>};

%%             1000 - 1999   Client codes
            1000 -> {?CLIENT, <<"Клиентская ошибка. Не переданы обязательные параметра запроса"/utf8>>};
            1100 -> {?CLIENT, <<"Клиентская ошибка. Не корректный адресс плагина (или такого плагина не существует)"/utf8>>};

%%             2000 - 3000   ServiceTechnical codes
            2000 -> {?SERVICE_TECHICAL, <<"Техническая ошибка сервиса. Сервис не доступен (cannot_connect)"/utf8>>};
            2001 -> {?SERVICE_TECHICAL, <<"Техническая ошибка сервиса. Ошибка обработки запроса сервисом (HTTP eq 500)"/utf8>>};
            2002 -> {?SERVICE_TECHICAL, <<"Техническая ошибка сервиса. Ошибка авторизации и досутпа к сервису (HTTP eq 401)"/utf8>>};

%%             3000 - 4000   ServiceBussiness codes
            3000 -> {?BUSSINES_SERVICE, <<"Бизнес ошибка сервиса. Некоректные данные запроса (неправильные форматы, типы данных)"/utf8>>};
            3001 -> {?BUSSINES_SERVICE, <<"Бизнес ошибка сервиса. Сервис вернул неожиданный результат (Либо не задокуметированный)"/utf8>>};
            3003 -> {?BUSSINES_SERVICE, <<"Бизнес ошибка сервиса. Сервис вернул Не успешный результат"/utf8>>};
            3004 -> {?BUSSINES_SERVICE, <<"Бизнес ошибка сервиса. Ответная сигнатура Не валидна"/utf8>>};

%%             4000 - 5000   ConnectionTechnical codes
            4000 -> {?CONNECTION_TECHNICAL, <<"Техническая ошибка связи. Таймаут запроса к сервису (возможные проблемы соединения, либо неустойчивая работоспособность сервиса)"/utf8>>};
            4001 -> {?CONNECTION_TECHNICAL, <<"Техническая ошибка связи. Невозможно установить соединение с хостом сервиса"/utf8>>};
            C ->
              {?UNKNOWN_TYPE, <<(eu_types:to_binary(C))/binary, " неизвестный код ошибки "/utf8>>}
          end










).