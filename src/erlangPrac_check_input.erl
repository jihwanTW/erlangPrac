%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 10월 2017 오후 12:44
%%%-------------------------------------------------------------------
-module(erlangPrac_check_input).
-author("Twinny-KJH").

%% API
-export([check_input/2]).

%% 유저 정보관련
%% 유저 가입 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= user_register->
  check([<<"name">>,<<"email">>,<<"nickname">>],Data);
%% 유저 정보변경 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= user_update->
  check([<<"user_idx">>,<<"email">>,<<"nickname">>],Data);

%% 대화 관련
%% 대화조회 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= dialog_view->
  check([<<"user_idx">>,<<"room_idx">>,<<"read_idx">>],Data);
%% 대화보내기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= dialog_send->
  check([<<"user_idx">>,<<"room_idx">>,<<"dialog">>],Data);

%% 친구관련
%% 친구요청 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_request->
  check([<<"user_idx">>,<<"target_idx">>],Data);

%% 친구요청 응답 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_answer->
  check([<<"user_idx">>,<<"target_idx">>,<<"answer">>],Data);
%% 친구목록보기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_view->
  check([<<"user_idx">>],Data);
%% 친구요청목록보기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_request_view->
  check([<<"user_idx">>],Data)
.


check(NeedList,Data)->
  CheckDef = fun(NeedParam) ->
    proplists:is_defined(NeedParam,Data) == false
    end,
  Result = lists:filter(CheckDef, NeedList),
  if Result == [] ->
    true;
    true ->
      {400,jsx:encode([{<<"result">>,<<"Not enough data">>}])}
  end.

