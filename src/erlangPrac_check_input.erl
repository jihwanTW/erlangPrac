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
check_input({<<"user">>,<<"register">>,_},Data)->
  check_inputData([<<"name">>,<<"email">>,<<"nickname">>],Data);
%% 유저 로그인 데이터 존재여부 체크
check_input({<<"user">>,<<"login">>,_},Data)->
  check_inputData([<<"user_id">>],Data);
%% 유저 정보변경 데이터 존재여부 체크
check_input({<<"user">>,<<"update">>,_},Data)->
  check_inputDataAndSession([<<"email">>,<<"nickname">>,<<"session">>],Data);
%% 유저 로그아웃 데이터 존재여부 체크
check_input({<<"user">>,<<"logout">>,_},Data)->
  check_inputDataAndSession([<<"session">>],Data);

%% 대화 관련
%% 대화조회 데이터 존재여부 체크
check_input({<<"user">>,<<"dialog">>,<<"view">>},Data)->
  check_inputDataAndSession([<<"room_idx">>,<<"read_idx">>,<<"session">>],Data);
%% 대화보내기 데이터 존재여부 체크
check_input({<<"user">>,<<"dialog">>,<<"send">>},Data)->
  check_inputDataAndSession([<<"room_idx">>,<<"dialog">>,<<"session">>],Data);

%% 친구관련
%% 친구추가 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"add">>},Data)->
  check_inputDataAndSession([<<"target_idx">>,<<"session">>],Data);
%% 친구삭제 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"remove">>},Data)->
  check_inputDataAndSession([<<"target_idx">>,<<"session">>],Data);
%% 친구목록보기 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"view">>},Data)->
  check_inputDataAndSession([<<"session">>],Data);
%% 친구요청목록보기 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"suggest_view">>},Data)->
  check_inputDataAndSession([<<"session">>],Data);
%% 친구이름 업데이트 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"name_update">>},Data)->
  check_inputDataAndSession([<<"target_idx">>,<<"change_name">>,<<"session">>],Data);
%% 즐겨찾기에 추가 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"add_favorites">>},Data)->
  check_inputDataAndSession([<<"favorites_idx">>,<<"target_idx">>,<<"session">>],Data);
%% 즐겨찾기에서 제거 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"remove_favorites">>},Data)->
  check_inputDataAndSession([<<"target_idx">>,<<"session">>],Data);
%% 즐겨찾기 이름변경 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"favorites_name_update">>},Data)->
  check_inputDataAndSession([<<"favorites_name">>,<<"favorites_idx">>,<<"session">>],Data);
%% 즐겨찾기 유저 옮기기 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"favorites_move">>},Data)->
  check_inputDataAndSession([<<"target_idx">>,<<"favorites_idx">>,<<"session">>],Data)
.


check_inputDataAndSession(NeedList,Data)->
  CheckDef = fun(NeedParam) ->
    proplists:is_defined(NeedParam,Data) == false
    end,
  Result = lists:filter(CheckDef, NeedList),
  case Result of
    []->
      % session key check
      Session = proplists:get_value(<<"session">>,Data),
      erlangPrac_session:lookup(Session);
    _->
      {error,jsx:encode([{<<"result">>,<<"Not enough data">>}])}
  end.


check_inputData(NeedList,Data)->
  CheckDef = fun(NeedParam) ->
    proplists:is_defined(NeedParam,Data) == false
             end,
  Result = lists:filter(CheckDef, NeedList),
  case Result of
    []->
      % session key check
      {ok,'_'};
    _->
      {error,jsx:encode([{<<"result">>,<<"Not enough data">>}])}
  end.