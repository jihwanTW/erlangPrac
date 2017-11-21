%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 11월 2017 오후 1:25
%%%-------------------------------------------------------------------
-module(schedule_api).
-author("Twinny-KJH").

%% API
-export([schedule_add/1, schedule_fixed/1, schedule_share_for_personal/1, schedule_share_for_room/1, schedule_share_remove/1, schedule_hang_up/1, schedule_share_list/1, schedule_remove/1, schedule_list/1]).


%% 일정추가
%% return : Schedule_idx
schedule_add({User_idx,Data})->
  io:format("clear hits ~n"),
  Start_timestamp = proplists:get_value(<<"start_timestamp">>,Data),
  End_timestamp = proplists:get_value(<<"end_timestamp">>,Data),
  Subject = proplists:get_value(<<"subject">>,Data),
  Content = proplists:get_value(<<"content">>,Data),
  Alarm = proplists:get_value(<<"alarm">>,Data),
  Schedule_idx = utils:generate_random_int(),
  erlangPrac_mysql_query:query(schedule_add,[Schedule_idx,User_idx,Start_timestamp,End_timestamp, Subject,Content,Alarm]),
  {ok,jsx:encode([{<<"schedule_idx">>,Schedule_idx}])}
.

%% 스케쥴 목록보기
%% Period_unit : 이번달 / 이번주
%% range : 본인이등록한일정-schedule_self /  공유된일정-schedule_shared / 모두-schedule_all
schedule_list({User_idx,Data})->
  Period_unit = proplists:get_value(<<"period_unit">>,Data),
  Range = proplists:get_value(<<"range">>,Data),
  Range_atom = list_to_atom(binary_to_list(Range)),
  {ok,jsx:encode(emysql_util:as_json(erlangPrac_mysql_query:query(schedule_list,[Range_atom,User_idx,Period_unit])))}
.

%% 일정 수정 / 알람 추가,수정,삭제
%% 수정된 데이터와, schedule_idx 만 들어오면됨.
schedule_fixed({User_idx,Data})->
  Schedule_idx = proplists:get_value(<<"schedule_idx">>,Data),
  pass
.
%% 일정 삭제
%% schedule_idx 만 들어오면됨.
schedule_remove({User_idx,Data})->
  Schedule_idx = proplists:get_value(<<"schedule_idx">>,Data),
  pass
.
%% 일정공유 개인 대상
%% schedule_idx 와 target_idx 들어오면됨
schedule_share_for_personal({User_idx,Data})->
  pass
.
%% 일정공유 방유저들 대상
%% schedule_idx 와 room_idx 들어오면됨
schedule_share_for_room({User_idx,Data})->
  pass
.
%% 일정 공유 제거 ( 공유한사람이 해당공유자 제거 )
%% schedule_idx와 target_idx 가 들어오면됨.
schedule_share_remove({User_idx,Data})->
  pass
.
%% 일정 공유 끊기 ( 공유된사람이 해당공유 제거 )
%% schedule_idx 만 들어오면됨
schedule_hang_up({User_idx,Data})->
  pass
.
%% schedule_idx 만 들어오면됨.
%% 일정 공유 리스트 ( 공유된 유저들 목록 - 마스터 포함 . 마스터는 제거 가능 )
schedule_share_list({User_idx,Data})->
  pass
.
