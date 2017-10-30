%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 10월 2017 오후 4:10
%%%-------------------------------------------------------------------
-module(erlangPrac_query).
-author("Twinny-KJH").

%% API
-export([query/2,query/3,query/4]).

%% Name,Email,Nickname,Room_idx,User_idx,Read_idx

%% query/2
%% 친구목록 조회
query(QueryType,User_idx) when QueryType =:= friend_view->
  emysql:prepare(friend_view,<<"SELECT * FROM user join friend_list on user.idx = friend_list.user_idx or user.idx = friend_list.friend_idx WHERE (friend_list.user_idx=? or friend_list.friend_idx = ?) and friend_list.state='yes' and user.idx != ?">>),
  emysql:execute(chatting_db,friend_view,[User_idx,User_idx,User_idx]);
%% 친구 요청 목록 조회
query(QueryType,User_idx) when QueryType =:= friend_request_view->
  emysql:prepare(friend_request_view,<<"SELECT user.* FROM user join friend_list on user.idx = friend_list.friend_idx WHERE friend_list.friend_idx=? and state='wait'">>),
  emysql:execute(chatting_db,friend_request_view,[User_idx]);
query(QueryType,_)->
  {500,jsx:encode([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])}
.

%% query/3
%% 방에 유저가 존재하는지 조회
query(QueryType,Room_idx,User_idx) when QueryType =:= check_room->
  emysql:prepare(check_room,<<"SELECT * FROM room_user WHERE room_idx= ? and user_idx = ?">>),
  emysql:execute(chatting_db,check_room,[Room_idx,User_idx]);
%% 닉네임과 이메일 중복 조회
query(QueryType,Nickname,Email) when QueryType =:= check_duplicate->
  emysql:prepare(check_user,<<"SELECT * FROM user WHERE email=? or nickname=? ">>),
  emysql:execute(chatting_db,check_user,[Email,Nickname]);
%% 친구 요청
query(QueryType,User_idx,Target_idx) when QueryType =:= friend_request->
  emysql:prepare(friend_request,<<"INSERT INTO friend_list (user_idx,friend_idx) values (?, ?) ">>),
  emysql:execute(chatting_db,friend_request,[User_idx,Target_idx]);
%% 친구 즐겨찾기 추가
query(QueryType,User_idx,Target_idx) when QueryType =:= friend_add_favorites->
  emysql:prepare(friend_request,<<"UPDATE friend_list SET favorites = ? WHERE user_idx=? and friend_idx=?">>),
  emysql:execute(chatting_db,friend_request,[<<"yes">>,User_idx,Target_idx]);
%% 친구 즐겨찾기 삭제
query(QueryType,User_idx,Target_idx) when QueryType =:= friend_remove_favorites->
  emysql:prepare(friend_request,<<"UPDATE friend_list SET favorites = ? WHERE user_idx=? and friend_idx=?">>),
  emysql:execute(chatting_db,friend_request,[<<"no">>,User_idx,Target_idx]);
query(QueryType,_,_)->
  {500,jsx:encode([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])}
.

%% query/4
%% 기존에 대화가 존재할경우, 읽음 카운트만 조회 .
%% 대화 조회 및 읽음 카운트 감소
query(QueryType,Room_idx,User_idx,Read_idx) when QueryType =:= view_dialog->
  %% 읽음 카운트 감소하기 위해 현재까지 읽은 대화 idx를 가져온다.
  emysql:prepare(view_read_dialog_idx,<<"SELECT dialog_idx FROM read_dialog_idx WHERE room_idx=? and user_idx = ?">>),
  Result =emysql_util:as_json(emysql:execute(chatting_db,view_read_dialog_idx,[Room_idx,User_idx])),

  %% 읽음 카운트에서 이후의 대화에 대해 카운트를 감소하기 위해, 가장 높은값의 idx를 가져온다.
  emysql:prepare(update_read_idx,<<"SELECT idx FROM dialog WHERE room_idx=? order by idx desc limit 0,1">>),
  [H2|_] = emysql_util:as_json(emysql:execute(chatting_db,update_read_idx,[Room_idx])),
  LastDialogIdx = proplists:get_value(<<"idx">>,H2),
  case Result of
  []->
    %% Result가 비어있는 List라면, 읽음카운트 DB에 값을 새로 추가.
    emysql:prepare(insert_dialog_read,<<"INSERT INTO read_dialog_idx (room_idx,user_idx,dialog_idx) values (?, ?, ?)">>),
    emysql:execute(chatting_db,insert_dialog_read,[Room_idx,User_idx,LastDialogIdx]);
  _->
    %% Result가 비어있는 LIST가 아니라면, 카운트 감소된부분 갱신
    [H|_] = Result,
    emysql:prepare(update_dialog_read,<<"UPDATE dialog SET unread_user_num=unread_user_num-1 WHERE idx > ? and room_idx = ?">>),
    emysql:execute(chatting_db,update_dialog_read,[proplists:get_value(<<"dialog_idx">>,H),Room_idx]),

    %% 현재까지 카운트 감소된부분 갱신
    emysql:prepare(update_dialog_read,<<"UPDATE read_dialog_idx SET dialog_idx = ?  WHERE room_idx =  ? and user_idx = ?">>),
    emysql:execute(chatting_db,update_dialog_read,[LastDialogIdx,Room_idx,User_idx])
  end,

  %% 대화 조회 결과값 전송
  emysql:prepare(view_dialog,<<"SELECT * FROM dialog WHERE room_idx=? and idx > ? limit 0,50">>),
  emysql:execute(chatting_db,view_dialog,[Room_idx,Read_idx]);
%% 대화 전송 및 읽음 카운트 설정
query(QueryType,User_idx,Room_idx,Dialog) when QueryType =:= send_dialog->
  %% 대화방에 있는 유저수 조회
  emysql:prepare(check_user,<<"SELECT count(*) as cnt FROM room_user WHERE room_idx=? ">>),
  Result = emysql:execute(chatting_db,check_user,[Room_idx]),
  [H|_] = emysql_util:as_json(Result),
  Cnt = proplists:get_value(<<"cnt">>,H),
  %% 대화내용 DB에 삽입
  emysql:prepare(insert_dialog,<<"INSERT INTO dialog (room_idx,user_idx,user_dialog,date_time,unread_user_num) values(?, ?, ?,now(),?)">>),
  emysql:execute(chatting_db,insert_dialog,[Room_idx,User_idx,Dialog,Cnt]);
%% 회원가입
query(QueryType,Name,Email,Nickname) when QueryType =:= register_user->
  emysql:prepare(register_user,<<"INSERT INTO user (name,email,nickname,date_time,unread_user_num) values(?, ?, ?, now())">>),
  emysql:execute(chatting_db,register_user,[Name,Email,Nickname]);
%% 유저정보 업데이트
query(QueryType,Email,Nickname,User_idx) when QueryType =:= update_user->
  emysql:prepare(update_user,<<"UPDATE user SET email=?, nickname=? WHERE idx=?">>),
  emysql:execute(chatting_db,update_user,[Email,Nickname,User_idx]);
%% 친구 이름변경
query(QueryType, User_idx, Target_idx, Change_Name) when QueryType =:= friend_name_update->
  emysql:prepare(update_user,<<"UPDATE friend_list SET name=? WHERE user_idx = ? and friend_idx = ?">>),
  emysql:execute(chatting_db,update_user,[Change_Name,User_idx, Target_idx]);
%% 친구 즐겨찾기 이름변경
query(QueryType, User_idx, Target_idx, Change_Name) when QueryType =:= friend_favorites_name_update->
  emysql:prepare(update_user,<<"UPDATE friend_list SET favorites_name=? WHERE user_idx = ? and friend_idx = ?">>),
  emysql:execute(chatting_db,update_user,[Change_Name,User_idx, Target_idx]);
%% 친구 요청 응답
query(QueryType,User_idx,Target_idx,Answer) when QueryType =:= friend_answer->
  emysql:prepare(update_user,<<"UPDATE friend_list SET state=? WHERE user_idx=? and friend_idx = ?">>),
  emysql:execute(chatting_db,update_user,[Answer,User_idx,Target_idx]);
query(QueryType,_,_,_)->
  {500,jsx:encode([{<<"result">>,<<"query type error">>},{<<"type">>},{QueryType}])}
.
