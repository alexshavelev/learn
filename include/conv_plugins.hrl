-include("conv_plugins_http.hrl").
-include("conv_plugins_resp.hrl").
-include("error_codes.hrl").
-include("business_p48.hrl").

%% LAGER MACROS    
-define(LOG_DEBUG(Format, Args),
    lager:debug(Format, Args)).

-define(LOG_INFO(Format, Args),
    lager:info(Format, Args)).

-define(LOG_WARNING(Format, Args),
    lager:warning(Format, Args)).
			      
-define(LOG_ERROR(Format, Args),
    lager:error(Format, Args)).

-define(LOG_CRITICAL(Format, Args),
    lager:critical(Format, Args)).

%% XML
-define(XML_SHEMA, <<"http://www.w3.org/2001/XMLSchema-instance">>).
-define(XML_ROOTHEADER, <<"<?xml version=\"1.0\" encoding=\"utf-8\"?>">>).

%% Tables
-define(RATES, rates_ets).
-define(THREE_D_SECURE_RESULTS, '3ds_results').
-define(PROMIN_SID, promin_sid_ets).
-define(RABBIT_CONN, rabbitmq_conn_ets).
-define(conv_plugins, conv_plugins).

-define(ThrowSimpleException(Reason), throw({error, Reason})).
-define(ThrowSimpleException(Code, Reason), throw({error,eu_types:to_integer(Code), Reason})).


-define(undef, undefined).
-define(IsUndefOrEmpty(Value), Value =:= <<>> orelse  Value =:= [] orelse Value =:= ?undef).
-define(IsNOTUndefOrEmpty(V), false =:= (?IsUndefOrEmpty(V))).
-define(wrapp_succes_response(Module, RespData), [
  { <<"__", (eu_types:to_binary(Module))/binary, "_result">>,<<"ok">>} | RespData ]).

-define(ExcludedForReponseLoggingModules, [
  plugins_getWfPurseTwo,
  plugins_getWfPurseInfo,
  plugins_getWfPurseCardInfo,
  plugins_getPurseContract

]).
-define(IsInExcludedForPrinting(Handler), lists:member(Handler, ?ExcludedForReponseLoggingModules)).
-define(preetify_log_response(PluginHandler, ConveyorTerm),
  begin
    case ?IsInExcludedForPrinting(PluginHandler) of
      true -> ?LOG_INFO("Response from plugin ~p with data ~p", [PluginHandler, ConveyorTerm]);
      _ ->
        case catch jsx:encode(ConveyorTerm) of
          RespJSON when is_binary(RespJSON) ->
            ?LOG_INFO("Response from a conv_plugins SERVER ~n~n~n~ts~n~n~n", [jsx:prettify(RespJSON)]);
          _ ->
            ?LOG_INFO("Response from a conv_plugins SERVER ~n~n~n~p~n~n~n", [ConveyorTerm])
        end
    end
  end).

-define(ContentTypeTextXML, "text/xml;chartset=UTF-8").
-define(CXP_HEADERS(Body, Sid), [
  {"Accept", "*/*"},
  {"Accept-Encoding", "gzip,deflate,sdch"},
  {"Connection", "keep-alive"},
  {"Content-Length", byte_size(Body)},
  {"Content-Type", "text/xml;chartset=UTF-8"},
  {"sid", binary_to_list(Sid)}
]).

-record(conv_conf, {id, login, secret_req, url}).