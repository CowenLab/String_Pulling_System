"""
DeepLabCut video analysis
Gia Jordan 2020

Run in Anaconda GPU Environment
C:\Program Files\DeepLabCut-master\conda-environments
Also Run in directory where video is located

"""
#activate dlc-windowsGPU
import cv2
import numpy as np
import deeplabcut as dlc
import os

os.chdir(r'G:\DATA\LID_Ketamine_SingleUnit_R56\330\03')
cwd=os.getcwd()

[parent,session]=os.path.split(cwd)
[parent,rat]=os.path.split(parent)

#Update Config variable to path of DLC config file
config=r'G:\GitHub\Behavior_Quantification\Code\Video Processing\DeepLabCut\config.yaml'#this shouldn't change unless you make a new network or move this one
os.rename(session+'.mp4',session+'_org.mp4')
INvideo=session+'_org.mp4'
Label_video=False

input=cv2.VideoCapture(INvideo)
fps=int(input.get(cv2.CAP_PROP_FPS))
fwidth=int(input.get(cv2.CAP_PROP_FRAME_WIDTH))
fheight=int(input.get(cv2.CAP_PROP_FRAME_HEIGHT))
length=int(input.get(cv2.CAP_PROP_FRAME_COUNT))
print(length)
count=1

codec=cv2.VideoWriter.fourcc(*'XVID')
OUTvideo=session+'.mp4'
ortVideo=session+'_Ort.mp4'
video_writer=cv2.VideoWriter(OUTvideo,codec,fps,(fheight,fwidth))


capture=cv2.VideoCapture(INvideo)

while count <= length:
    _, img = capture.read()
    img_rot=cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
    #video_writer.write(img_rot)
    img_ort=np.flipud(img_rot)
    video_writer.write(img_ort)
    if count % 1000==0:
        print(count)
    count += 1
    del img
    del img_rot

video_writer.release()





dlc.analyze_videos(config,[OUTvideo],save_as_csv=True,gputouse=0)
dlc.filterpredictions(config,[OUTvideo],filtertype='arima',p_bound=.01,ARdegree=3,MAdegree=1)

if Label_video==True:
    dlc.create_labeled_video(config,[OUTvideo],trailpoints=7,save_frames=False,filtered=True)
    
    
    
