#!/usr/local/bin/fish

switch $argv[1]
case toggle
	mpc toggle
case next
	mpc next
case prev
	mpc prev
end
