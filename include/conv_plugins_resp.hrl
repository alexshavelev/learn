%% Resp
-include_lib("eu/include/conveyor_h.hrl").

-define(FAIL_RESP(ErrDesc),
  {<<"ok">>, [ [
    {<<"type">>, <<"data">> },
    {<<"res_data">>, [{<<"plugin_statements_res">>, ErrDesc}]},
    {<<"proc">>, <<"fail">> }
  ] ]}).

-define(OK_RESP(ResData),
  {<<"ok">>, [ [
    {<<"type">>, <<"data">> },
    {<<"res_data">>, ResData},
    {<<"proc">>, <<"ok">> }
  ] ]}).


-define(UnknownErrorConvResp(Module, ErrCode, ErrType, ErrText, Reason),
  #conveyor_api_response_event{
    unique_ref = <<"">>,
    obj_id = "",
    state = <<"ok">>,
    data = [
      {<<"plugin">>, eu_types:to_binary(Module)},
      {<<"__",  (eu_types:to_binary(Module))/binary, "_result">>, <<"error">>},
      {<<(eu_types:to_binary(Module))/binary,"_error_type">>, ErrType},
      {<<(eu_types:to_binary(Module))/binary,"_error_code">>, ErrCode},
      {<<(eu_types:to_binary(Module))/binary,"_error_reason">>, Reason},
      {<<(eu_types:to_binary(Module))/binary,"_error_text">>, ErrText}

%%         {<<"error_stacktrace">>, unicode:characters_to_binary((term_to_binary(erlang:get_stacktrace())))}
    ]
  }).


-define(UnknownErrorConvResp(Module, ErrorDescription),
    #conveyor_api_response_event{
      unique_ref = <<"">>,
      obj_id = "",
      state = <<"ok">>,
      data = [
        {<<"plugin">>, eu_types:to_binary(Module)},
        {<<"__",  (eu_types:to_binary(Module))/binary, "_result">>, <<"error">>},
        {<<"error_description">>, ErrorDescription}
%%         {<<"error_stacktrace">>, unicode:characters_to_binary((term_to_binary(erlang:get_stacktrace())))}
      ]
    }).