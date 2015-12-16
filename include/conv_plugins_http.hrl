%% Http
-define(CONT_TYPE_XML, "text/xml").
-define(CONT_TYPE_JSON, "application/json").
-define(CONT_TYPE_XWWW, "application/x-www-form-urlencoded").

%% httpc POST headers
-define(DEF_HEADERS,
  [
    {"content-encoding", "utf-8"},
    {"connection", "close"}
  ]).


-define(XML_HEADERS, [{<<"content-type">>, <<"application/xml">>},
  {<<"content-encoding">>, <<"utf-8">>}]).
-define(JSON_HEADERS, [{<<"content-type">>, <<"application/json">>},
  {<<"content-encoding">>, <<"utf-8">>}]).

-define(SEND_HTTP_RESPONSE(Req2, Body, State),
  cowboy_http_helper:send_http_response(Req2, Body, State)
).
-define(SEND_JSON_HTTP_RESPONSE(Req2, Body, State), ?SEND_HTTP_RESPONSE(Req2, jsx:encode(Body), State)).

-define(SEND_ERROR_HTTP_RESPONSE(Code, Reason, Req2, State),
  cowboy_http_helper:send_error_http_response(Code, Reason, Req2, State)
).

-record(resp_helper_ext_plugins, {http_code = 200, headers = [], resp = <<>>, cow_req}).
