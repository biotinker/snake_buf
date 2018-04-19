#!/bin/perl

use strict;
use warnings;
use 5.010;
no warnings 'experimental';
use Data::Dumper;
use Term::ReadKey ;

my $FB = "/dev/fb0";
my $FBC = "/tmp/fb0";

my $XRES = $ARGV[0];
my $YRES = $ARGV[1];
my $BLOCK_SIZE = 20;

my $WIDTH = int($XRES/$BLOCK_SIZE);
my $HEIGHT = int($YRES/$BLOCK_SIZE);


my @snake_pos = ([2,0],[1,0],[0,0]);
my $occupied = { "2,0" => 1 ,"1,0" => 1,"0,0" => 1};

my @block_pos;

sub new_block{
	@block_pos = (int(rand($HEIGHT)), int(rand($WIDTH)));
}

sub end{
	update(1);
	update(1);
	update(1);
	update(0);
	update(0);
	update(0);
	update(1);
	update(1);
	update(1);
	update(0);
	update(0);
	update(0);
	ReadMode 0;
	exit(0);
}

sub write_rgb {
	my $r = shift;
	my $g = shift;
	my $b = shift;
	my $a = 0;
	
	return((pack("C", $b).pack("C", $g).pack("C", $r).pack("C", $a)) x $BLOCK_SIZE);
	
}

sub move{
	my $y = shift;
	my $x = shift;
	my $newy = $snake_pos[0]->[0] + $y;
	if($newy >= $HEIGHT){
		$newy = 0;
	}
	if($newy < 0){
		$newy = $HEIGHT - 1;
	}
	my $newx = $snake_pos[0]->[1] + $x;
	if($newx >= $WIDTH){
		$newx = 0;
	}
	if($newx < 0){
		$newx = $WIDTH - 1;
	}
	my @newHead = ($newy, $newx);
	my $coord = "$newy,$newx";
	if($occupied->{$coord}){
		end();
	}else{
		$occupied->{$coord} = 1;
	}
	unshift @snake_pos, \@newHead;
	if($newy == $block_pos[0] && $newx == $block_pos[1]){
		new_block();
	}else{
		my $old = pop @snake_pos;
		$occupied->{"$old->[0],$old->[1]"} = 0;
	}
}

sub update{
	my $invert = shift;
	my @r = (255,0,0);
	my @g = (0,255,0);
	my @b = (0,0,255);
	if($invert){
		@r = (0,127,127);
		@g = (127,0,127);
		@b = (127,127,0);
	}
	open my $fh, ">:raw", $FBC or die $!;
	foreach my $y (0..($HEIGHT - 1)){
		my $dispLine;
		foreach my $x (0..($WIDTH - 1)){
			my $in = 0;
			my $coord = "$y,$x";
			if($occupied->{$coord}){
				$in = 1;
			}
			if($in){
				$dispLine.=write_rgb(@r);
			}elsif($y == $block_pos[0] && $x == $block_pos[1]){
				$dispLine.=write_rgb(@b);
			}else{
				$dispLine.=write_rgb(@g);
			}
		}
		print $fh ($dispLine x ($BLOCK_SIZE));
	}
	close $fh;
	my $retval = system("cp -f $FBC $FB");
	if($retval){
		ReadMode 0;
		die("Cannot copy temp file $FBC over $FB\n");
	}
}
ReadMode 4;
my $key = "d";
my $lastkey = "d";
new_block();

sub valid{
	my $last = shift;
	my $key = shift;
	my $isValid = 1;
	
	if(not defined($key)){
		$isValid = 0;
	}else{
		given($key){
			when($_ eq "w" && $last eq "s")	{$isValid = 0}
			when($_ eq "a" && $last eq "d")	{$isValid = 0}
			when($_ eq "s" && $last eq "w")	{$isValid = 0}
			when($_ eq "d" && $last eq "a")	{$isValid = 0}
		}
	}
	return $isValid;
}

do{
	given($key){
		when($_ eq "w")	{move(-1,0)}
		when($_ eq "a")	{move(0,-1)}
		when($_ eq "s")	{move(1,0)}
		when($_ eq "d")	{move(0,1)}
		default{ReadMode 0;exit(0);}
	}
	update(0);
	$key = ReadKey(-1);
	
	if(not valid($lastkey, $key)){
		$key = $lastkey;
	}else{
		$lastkey = $key;
	}
}while(1);
