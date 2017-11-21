%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 10월 2017 오후 12:44
%%%-------------------------------------------------------------------
-module(check_input_data).
-author("Twinny-KJH").

%% API
-export([check_input/2]).

%% 유저 정보관련
%% 유저 가입 데이터 존재여부 체크
check_input({<<"user">>,<<"register">>,_},Data)->
  check_inputData([<<"name">>,<<"email">>,<<"nickname">>],Data);
check_input({<<"user">>,<<"withdrawal">>,_},Data)->
  check_inputDataAndSession([<<"session">>],Data);
%% 유저 로그인 데이터 존재여부 체크
check_input({<<"user">>,<<"login">>,_},Data)->
  check_inputData([<<"user_id">>],Data);
%% 유저 정보 보기 체크
check_input({<<"user">>,<<"info">>,_},Data)->
  check_inputDataAndSession([<<"target_idx">>],Data);
%% 유저 정보변경 데이터 존재여부 체크
check_input({<<"user">>,<<"update">>,_},Data)->
  check_inputDataAndSession([<<"email">>,<<"nickname">>,<<"session">>],Data);
%% 유저 로그아웃 데이터 존재여부 체크
check_input({<<"user">>,<<"logout">>,_},Data)->
  check_inputDataAndSession([<<"session">>],Data);
%% 유저 방 초대
check_input({<<"user">>,<<"room">>,<<"invite">>},Data)->
  check_inputDataAndSession([<<"session">>,<<"target_idx">>],Data);
%% 유저 방 떠남
check_input({<<"user">>,<<"room">>,<<"leave">>},Data)->
  check_inputDataAndSession([<<"session">>,<<"room_idx">>],Data);

%% 대화 관련
%% 대화조회 데이터 존재여부 체크
check_input({<<"user">>,<<"dialog">>,<<"view">>},Data)->
  check_inputDataAndSession([<<"room_idx">>,<<"read_idx">>,<<"session">>],Data);
%% 대화보내기 데이터 존재여부 체크
check_input({<<"user">>,<<"dialog">>,<<"send">>},Data)->
  check_inputDataAndSession([<<"dialog">>,<<"session">>],Data);

%% 친구관련
%% 친구추가 데이터 존재여부 체크
check_input({<<"user">>,<<"friend">>,<<"add">>},Data)->
  check_inputDataAndSession([<<"target_id">>,<<"session">>],Data);
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
  check_inputDataAndSession([<<"target_idx">>,<<"favorites_idx">>,<<"session">>],Data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% share part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 스케쥴 추가
check_input({<<"user">>,<<"schedule">>,<<"add">>},Data)->
  check_inputDataAndSession([<<"start_timestamp">>,<<"end_timestamp">>,<<"subject">>,<<"content">>,<<"alarm">>],Data);
%% 스케쥴 목록 보기
check_input({<<"user">>,<<"schedule">>,<<"list">>},Data)->
  check_inputDataAndSession([],Data);
%% 일정 수정 / 알람 추가,수정,삭제
check_input({<<"user">>,<<"schedule">>,<<"fixed">>},Data)->
  check_inputDataAndSession([<<"shcedule_idx">>],Data);
%% 일정 삭제
check_input({<<"user">>,<<"schedule">>,<<"remove">>},Data)->
  check_inputDataAndSession([<<"shcedule_idx">>],Data);
%% 일정공유 개인 대상
check_input({<<"user">>,<<"schedule">>,<<"share_personal">>},Data)->
  check_inputDataAndSession([<<"schedule_idx">>,<<"target_idx">>],Data);
%% 일정공유 방유저들 대상
check_input({<<"user">>,<<"schedule">>,<<"share_room">>},Data)->
  check_inputDataAndSession([<<"schedule_idx">>,<<"room_idx">>],Data);
%% 일정 공유 제거 ( 공유한사람이 해당공유자 제거 )
check_input({<<"user">>,<<"schedule">>,<<"share_remove">>},Data)->
  check_inputDataAndSession([<<"shcedule_idx">>,<<"target_idx">>],Data);
%% 일정 공유 끊기 ( 공유된사람이 해당공유 제거 )
check_input({<<"user">>,<<"schedule">>,<<"share_hang_up">>},Data)->
  check_inputDataAndSession([<<"schedule_idx">>],Data);
%% 일정 공유 리스트 ( 공유된 유저들 목록 - 마스터 포함 . 마스터는 제거 가능 )
check_input({<<"user">>,<<"schedule">>,<<"share_list">>},Data)->
  check_inputDataAndSession([<<"schedule_idx">>],Data)
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
      case Lookup_result = erlangPrac_session:lookup(Session) of
        {ok,undefined}->
          {error,jsx:encode([{<<"result">>,<<"not exsist session">>}])};
        _->
          Lookup_result
      end;
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
      {ok,undefined};
    _->
      {error,jsx:encode([{<<"result">>,<<"Not enough data">>}])}
  end.