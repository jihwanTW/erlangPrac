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
  check([<<"email">>,<<"nickname">>,<<"session">>],Data);
%% 유저 로그인 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= user_login->
  check([<<"user_id">>],Data);
%% 유저 로그아웃 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= user_logout->
  check([<<"session">>],Data);

%% 대화 관련
%% 대화조회 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= dialog_view->
  check([<<"room_idx">>,<<"read_idx">>,<<"session">>],Data);
%% 대화보내기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= dialog_send->
  check([<<"room_idx">>,<<"dialog">>,<<"session">>],Data);

%% 친구관련
%% 친구추가 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_add->
  check([<<"target_idx">>,<<"session">>],Data);
%% 친구삭제 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_remove->
  check([<<"target_idx">>,<<"session">>],Data);
%% 친구목록보기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_view->
  check([<<"session">>],Data);
%% 친구요청목록보기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_suggest_view->
  check([<<"session">>],Data);
%% 친구이름 업데이트 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_name_update->
  check([<<"target_idx">>,<<"change_name">>,<<"session">>],Data);
%% 즐겨찾기에 추가 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_add_favorites->
  check([<<"favorites_idx">>,<<"target_idx">>,<<"session">>],Data);
%% 즐겨찾기에서 제거 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_remove_favorites->
  check([<<"target_idx">>,<<"session">>],Data);
%% 즐겨찾기 이름변경 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= friend_favorites_name_update->
  check([<<"favorites_name">>,<<"favorites_idx">>,<<"session">>],Data);
%% 즐겨찾기 유저 옮기기 데이터 존재여부 체크
check_input(QueryType,Data) when QueryType =:= favorites_move->
  check([<<"target_idx">>,<<"favorites_idx">>,<<"session">>],Data)
.


check(NeedList,Data)->
  CheckDef = fun(NeedParam) ->
    proplists:is_defined(NeedParam,Data) == false
    end,
  Result = lists:filter(CheckDef, NeedList),
  case Result of
    []->true;
    _->
      {error,jsx:encode([{<<"result">>,<<"Not enough data">>}])}
  end.

