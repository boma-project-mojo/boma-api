for file in /Volumes/Samsung_T5/boom_videos/*
do
  ffmpeg -i $file -c copy "${file%%.*}".mp4
  # ffmpeg -i $file -strict experimental 
  # ffmpeg -i $file -cpu-used -5 -deadline realtime "${file%%.*}".mp4
done