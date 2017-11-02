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
  {ok, [{Data,_}],Req4} = cowboy_req:body_qs(Req3),

  {HttpStateCode,Reply}= handle(Api,What,Opt,jsx:decode(Data)),

  {ok,Req5} = cowboy_req:reply(HttpStateCode,[
    {<<"content-type">>,<<"text/plain">>}
  ], Reply,Req4),
  {ok,Req5,State}.

%% 유저 가입
handle(<<"user">>,<<"register">>,_,Data) ->
  Result = check_input(user_register,Data, erlangPrac_user:user_register(Data)),
  append_http_code(Result);
%% 유저 로그인
handle(<<"user">>,<<"login">>,_,Data) ->
  Result = check_input(user_login,Data, erlangPrac_user:user_login(Data)),
  append_http_code(Result);
%% 유저 정보 업데이트
handle(<<"user">>,<<"update">>,_,Data) ->
  Function = fun(_Data) -> erlangPrac_user:user_update(_Data) end,
  Result = check_session(user_update,Function,Data),
  append_http_code(Result);
%% 유저 로그아웃
handle(<<"user">>,<<"logout">>,_,Data) ->
  Function = fun(_Data) -> erlangPrac_user:user_logout(_Data) end,
  Result = check_session(user_logout,Function,Data),
  append_http_code(Result);

%% 유저 대화관련 함수
handle(<<"user">>,<<"dialog">>,<<"send">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:dialog_send(_Data) end,
  Result = check_session(dialog_send,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"dialog">>,<<"view">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:dialog_view(_Data) end,
  Result = check_session(dialog_view,Function,Data),
  append_http_code(Result);

%% 친구 관련 함수
handle(<<"user">>,<<"friend">>,<<"add">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_add(_Data) end,
  Result = check_session(friend_add,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"remove">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_remove(_Data) end,
  Result = check_session(friend_remove,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"view">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_view(_Data) end,
  Result = check_session(friend_view,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"suggest_view">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_suggest_view(_Data) end,
  Result = check_session(friend_suggest_view,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"name_update">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_name_update(_Data) end,
  Result = check_session(friend_name_update,Function,Data),
  append_http_code(Result);

handle(<<"user">>,<<"friend">>,<<"add_favorites">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_add_favorites(_Data) end,
  Result = check_session(friend_add_favorites,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"remove_favorites">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_remove_favorites(_Data) end,
  Result = check_session(friend_remove_favorites,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"favorites_name_update">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:friend_favorites_name_update(_Data) end,
  Result = check_session(friend_favorites_name_update,Function,Data),
  append_http_code(Result);
handle(<<"user">>,<<"friend">>,<<"favorites_move">>,Data) ->
  Function = fun(_Data) -> erlangPrac_user:favorite_move(_Data) end,
  Result = check_session(favorite_move,Function,Data),
  append_http_code(Result);
handle(_,_,_,_)->
  {404,jsx:encode([{<<"result">>,<<"undefined url">>}])}.


%% 세션키를 필요로하는 경우에 체크함수
check_input(RequestAtom,Data)->
  InputResult = erlangPrac_check_input:check_input(RequestAtom,Data),
  case InputResult of
    true->
          true;
    _->
      InputResult
  end
  .
%% 세션키를 필요로하지않는 경우의 체크함수
check_input(RequestAtom,Data,Function)->
  InputResult = erlangPrac_check_input:check_input(RequestAtom,Data),
  case InputResult of
    true->
      Function;
    _->
      InputResult
  end
.

%% http state 코드를 붙이는 함수
append_http_code(Result)->
  % tuple 값이 들어오면, 해당부분은 상태코드가 포함된 에러값이 리턴된것이므로, 그대로 반환.
  {State,JSON} = Result,
  case State of
    error->{400,JSON};
    ok->{200,JSON};
    _->{500,jsx:encode([{"result","state is not return"}])}
  end
  .

%% 세션값이 유효한지를 체크하는 함수
check_session(QueryType,Function,Data)->
  CheckResult =  check_input(QueryType,Data),
  case CheckResult of
    true ->
      Session = proplists:get_value(<<"session">>,Data),
      io:format("~p ~n",[Session]),
      Result = emysql_util:as_json(erlangPrac_query:query(check_session,Session)),
      case Result of
        [] ->
          {error,jsx:encode([{<<"result">>,<<"Invalid session">>}])};
        _->
          [SessionData] = Result,
          Function({SessionData,Data})
      end;
      _->
        CheckResult
  end.

terminate(_Reason,_Req,_State)->ok.