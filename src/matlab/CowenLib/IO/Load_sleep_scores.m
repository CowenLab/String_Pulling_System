function [tstamp,HMS,Event] = Load_sleep_scores(fname)
  [ss_timestamps ss_HMS ss_events] = textread(fname,'%n%q%q','delimiter',',');

  a =strcmp(ss_events,'S1Start');
  times(1,1) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'S1End');
  times(1,2) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'M1Start');
  times(2,1) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'M1End');
  times(2,2) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'S2Start');
  times(3,1) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'S2End');
  times(3,2) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'M2Start');
  times(4,1) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'M2End');
  times(4,2) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'S3Start');
  times(5,1) = ss_timestamps(find(a==1));
  a =strcmp(ss_events,'S3End');
  times(5,2) = ss_timestamps(find(a==1));