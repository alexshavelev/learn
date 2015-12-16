%%%-------------------------------------------------------------------
%%% @author user
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. июл 2014 14:40
%%%-------------------------------------------------------------------
-author("Vitali Kletsko <v.kletsko@gmail.com>").

%% Hosts
%% PB
-define(PB_ALFA_HOST, "http://alpha.wf.privatbank.ua:8147/").
-define(PB_BETA_HOST, "http://beta.wf.privatbank.ua:8196/").
-define(PB_PROD_HOST, "http://wf.privatbank.ua:8186/").
%% AB
-define(AB_ALFA_HOST, "http://alpha.wf.privatbank.ua:8157/").
-define(AB_BETA_HOST, "http://beta.wf.privatbank.ua:8142/").
-define(AB_PROD_HOST, "http://wf.privatbank.ua:8127/").
%% PL
-define(PL_ALFA_HOST, "http://alpha.wf.privatbank.ua:8148/").
-define(PL_BETA_HOST, "http://beta.wf.privatbank.ua:8155/").
-define(PL_PROD_HOST, "http://wf.privatbank.ua:8145/").
%% TG
-define(TG_ALFA_HOST, "http://alpha.wf.privatbank.ua:8138/").
-define(TG_BETA_HOST, "http://beta.wf.privatbank.ua:8144/").
-define(TG_PROD_HOST, "http://wf.privatbank.ua:8135/").
%% MP
-define(MP_ALFA_HOST, "http://alpha.wf.privatbank.ua:8126/").
-define(MP_BETA_HOST, "http://beta.wf.privatbank.ua:8117/").
-define(MP_PROD_HOST, "http://wf.privatbank.ua:8116/").
%% CM
-define(CM_ALFA_HOST, "http://alpha.wf.crimeabank.com:9147/").
-define(CM_BETA_HOST, "http://beta.crimeabank.com:9196/").
-define(CM_PROD_HOST, "http://wf.crimeabank.com:9186/").

-define(DETECT_HOST_BISINESS_P48(ReqBank, IsTest),
  case {ReqBank, IsTest} of
    %% PB
    {<<"PB">>, <<"alfa">>} -> ?PB_ALFA_HOST;
    {<<"PB">>, <<"beta">>} -> ?PB_BETA_HOST;
    {<<"PB">>, <<"false">>} -> ?PB_PROD_HOST;
    %% AB
    {<<"AB">>, <<"alfa">>} -> ?AB_ALFA_HOST;
    {<<"AB">>, <<"beta">>} -> ?AB_BETA_HOST;
    {<<"AB">>, <<"false">>} -> ?AB_PROD_HOST;
    %% PL
    {<<"PL">>, <<"alfa">>} -> ?PL_ALFA_HOST;
    {<<"PL">>, <<"beta">>} -> ?PL_BETA_HOST;
    {<<"PL">>, <<"false">>} -> ?PL_PROD_HOST;
    %% TG
    {<<"TG">>, <<"alfa">>} -> ?TG_ALFA_HOST;
    {<<"TG">>, <<"beta">>} -> ?TG_BETA_HOST;
    {<<"TG">>, <<"false">>} -> ?TG_PROD_HOST;
    %% MP
    {<<"MP">>, <<"alfa">>} -> ?MP_ALFA_HOST;
    {<<"MP">>, <<"beta">>} -> ?MP_BETA_HOST;
    {<<"MP">>, <<"false">>} -> ?MP_PROD_HOST;
    %% CM
    {<<"CM">>, <<"alfa">>} -> ?CM_ALFA_HOST;
    {<<"CM">>, <<"beta">>} -> ?CM_BETA_HOST;
    {<<"CM">>, <<"false">>} -> ?CM_PROD_HOST;

    _ -> throw({error, 1000, <<"lost param ReqBANK in request">>})
  end
).