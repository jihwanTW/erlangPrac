%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 10월 2017 오후 1:53
%%%-------------------------------------------------------------------
-module(erlangPrac_http).
-author("Twinny-KJH").

%% API
-export([init/3,handle/2,terminate/3]).

init(_Type,Req,[]) ->
  {ok,Req,no_state}.

handle(Req,State)->
  {Api,Req1} = cowboy_req:binding(api,Req),
  {What,Req2} = cowboy_req:binding(what,Req1),
  {Opt,Req3} = cowboy_req:binding(opt,Req2),
  %% 데이터 로딩
  {ok,Data,Req4} = cowboy_req:body_qs(Req3),

  Reply = handle(Api,What,Opt,Data),

  {ok,Req5} = cowboy_req:reply(200,[
    {<<"content-type">>,<<"text/plain">>}
  ], Reply,Req4),
  {ok,Req5,State}.

%%handle(<<"login">>,_,_,Data)->
%%  Id = proplists:get_value(<<"id">>,Data),
%%  Password= proplists:get_value(<<"pw">>,Data),
%%  case dets:lookup(users_list,Id) of
%%    [{Id,Password}]->
%%      <<"{\"result\":\"ok\"}">>;
%%    _ ->
%%      <<"{\"result\":\"fail\"}">>
%%  end;
handle(<<"user">>,<<"register">>,_,Data) ->
  erlangPrac_user:user(user_register,Data);
handle(<<"user">>,<<"update">>,_,Data) ->
  erlangPrac_user:user(user_update,Data);

handle(<<"user">>,<<"dialog">>,<<"send">>,Data) ->
  erlangPrac_user:dialog(dialog_send,Data);
handle(<<"user">>,<<"dialog">>,<<"view">>,Data) ->
  erlangPrac_user:dialog(dialog_view,Data);

handle(<<"user">>,<<"friend">>,<<"request">>,Data) ->
  erlangPrac_user:friend(request,Data);
handle(<<"user">>,<<"friend">>,<<"answer">>,Data) ->
  erlangPrac_user:friend(answer,Data);
handle(<<"user">>,<<"friend">>,<<"view">>,Data) ->
  erlangPrac_user:friend(view,Data);
handle(<<"user">>,<<"friend">>,<<"view_request">>,Data) ->
  erlangPrac_user:friend(view_request,Data);
handle(_,_,_,_)->
  <<"{\"result\":\"error\"}">>.




terminate(_Reason,_Req,_State)->ok.