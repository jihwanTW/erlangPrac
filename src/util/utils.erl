%%%-------------------------------------------------------------------
%%% @author Twinny-KJH
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 11월 2017 오후 2:22
%%%-------------------------------------------------------------------
-module(utils).
-author("Twinny-KJH").

%% API
-export([generate_random_int/0]).



generate_random_int()->
  <<A:32,B:32,C:32>> = crypto:rand_bytes(12),
  random:seed(A,B,C),
  random:uniform(2100000000)
.