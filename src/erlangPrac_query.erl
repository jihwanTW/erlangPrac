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
-export([query/2]).


query(QueryType,Data) when is_atom(QueryType)->
  case QueryType of
    check_room->
      %% 방에 유저가 존재하는지여부 조회
      User_idx = proplists:get_value(<<"user_idx">>,Data),
      Room_idx = proplists:get_value(<<"room_idx">>,Data),
      emysql:prepare(check_room,<<"SELECT * FROM room_user WHERE room_idx= ? and user_idx = ?">>),
      emysql:execute(chatting_db,check_room,[Room_idx,User_idx]);

    insert_dialog->
      %% 대화 전송
      User_idx = proplists:get_value(<<"user_idx">>,Data),
      Room_idx = proplists:get_value(<<"room_idx">>,Data),
      Dialog = proplists:get_value(<<"dialog">>,Data),
      emysql:prepare(insert_dialog,<<"INSERT INTO dialog (room_idx,user_idx,user_dialog,date_time) values(?, ?, ?,now())">>),
      emysql:execute(chatting_db,insert_dialog,[User_idx,Room_idx,Dialog]);

    view_dialog->
      %% 대화 조회
      Room_idx = proplists:get_value(<<"room_idx">>,Data),
      Read_idx = proplists:get_value(<<"read_idx">>,Data),
      emysql:prepare(view_dialog,<<"SELECT * FROM dialog WHERE room_idx=? and idx > ?">>),
      emysql:execute(chatting_db,view_dialog,[Room_idx,Read_idx]);

    check_duplicate->
      %% 중복조회
      Nickname=proplists:get_value(<<"nickname">>,Data),
      Email=proplists:get_value(<<"email">>,Data),
      emysql:prepare(check_user,<<"SELECT * FROM user WHERE nickname=? or email=? ">>),
      emysql:execute(chatting_db,check_user,[Nickname,Email]);

    register_user->
      %% 회원가입
      Name=proplists:get_value(<<"name">>,Data),
      Email=proplists:get_value(<<"email">>,Data),
      Nickname=proplists:get_value(<<"nickname">>,Data),
      emysql:prepare(register_user,<<"INSERT INTO user (name,email,nickname,date_time) values(?, ?, ?, now())">>),
      emysql:execute(chatting_db,register_user,[Name,Email,Nickname]);

    update_user->
      %% 유저정보 업데이트
      Idx = proplists:get_value(<<"idx">>,Data),
      Email = proplists:get_value(<<"email">>,Data),
      Nickname = proplists:get_value(<<"nickname">>,Data),
      emysql:prepare(update_user,<<"UPDATE user SET email=?, nickname=? WHERE idx=?">>),
      emysql:execute(chatting_db,update_user,[Email,Nickname,Idx])
  end.
