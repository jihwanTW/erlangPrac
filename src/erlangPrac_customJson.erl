%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 11월 2017 오후 3:32
%%%-------------------------------------------------------------------
-module(erlangPrac_customJson).
-author("Twinny-KJH").

%% API
-export([redis2json/1]).

redis2json([])->
  undefined;
redis2json(List)->
  redis2json(List,[])
.


redis2json([],Result)->
  Result;
redis2json([Key,Value|T],Result)->
  Result2 = Result++[{Key,Value}],
  redis2json(T,Result2)
  .