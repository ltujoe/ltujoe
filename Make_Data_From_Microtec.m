function Make_Data_From_Microtec(fd)
% pwd: sökväg till katalogen där du har filerna
% ex: fd = '/Volumes/CT-Wood/CT-WOOD/AIKIDO/Tree001/Log01';
global d;

pwd1 = cd;
cd(fd);
d = dir('*.tiff');

for i = 1:size(d,1)
   if d(i,1).bytes > 4096
        disp(d(i,1).name)
        C = strsplit(d(i,1).name,'.tiff');
        f = fullfile(pwd,d(i,1).name);
        cd(pwd1);
        I = loadtiff3d(f);

        %[I1, c] = find_vol(I,300);
        [I1, ~] = find_vol2(I,200);
        MatrixToSingleTiffs(I1,C{1},pwd);
        
   end
   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [I1, c] = find_vol(I,th)
tic
BW = int16(zeros(size(I)));
BW(I>th) = 1;
se = strel('disk',5);

for k = 1:size(I,3)
    lBlob = bwareafilt(logical(BW(:,:,k)),1); %Biggest blob
    BW(:,:,k) = BW(:,:,k) & (lBlob); % Erase smallest from the original
    BW(:,:,k) = imfill(BW(:,:,k),'holes');
    BW(:,:,k) = imdilate(BW(:,:,k),se);
end
s = regionprops3(logical(BW),'VoxelList','Volume');
% Sort volume in descend order: Biggest volume first. 
n = find(max(s.Volume)==s.Volume);
d1 = cell2mat(s.VoxelList(n,:));

jmax = max(d1(:,1));
jmin = min(d1(:,1));
imax = max(d1(:,2));
imin = min(d1(:,2));
kmax = max(d1(:,3));
kmin = min(d1(:,3));
c = [imin,imax,jmin,jmax,kmin,kmax];
I1 = zeros(size(imin:imax,2),size(jmin:jmax,2),size(kmin:kmax,2));
I1(:,:,:) = int16(BW(imin:imax,jmin:jmax,kmin:kmax)).*I(imin:imax,jmin:jmax,kmin:kmax);

toc
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [I1, c] = find_vol2(I,th)
tic
n = 10;
s = floor(size(I,3)/n);
m = matfile('tmp.mat');
m.BW = int16(zeros(size(I,1),size(I,2),size(I,3)));
m.I = I(:,:,:);
st1(1,1) = 1;
for i = 1:n-1
    st1(1,i+1) = s*i+1;
    st2(1,i) = s*i;
end

st2(1,n) = size(I,3);

for i = 1:n
    i
    clear BW Itmp;
    Itmp(:,:,:) = m.I(:,:,st1(i):st2(i));
  
    BW = int16(zeros(size(Itmp)));
    BW(Itmp>th) = 1;
    se = strel('disk',5);

    for k = 1:size(Itmp,3)
        lBlob = bwareafilt(logical(BW(:,:,k)),1); %Biggest blob
        BW(:,:,k) = BW(:,:,k) & (lBlob); % Erase smallest from the original
        BW(:,:,k) = imfill(BW(:,:,k),'holes');
        BW(:,:,k) = imdilate(BW(:,:,k),se);
    end
  
    m.BW(:,:,st1(i):st2(i)) = BW(:,:,:);
    %volumeViewer(m.BW)
    s = regionprops3(logical(BW),'VoxelList','Volume');
    % Sort volume in descend order: Biggest volume first.
    n = find(max(s.Volume)==s.Volume);
    d1 = cell2mat(s.VoxelList(n,:));

    jmax = max(d1(:,1));
    jmin = min(d1(:,1));
    imax = max(d1(:,2));
    imin = min(d1(:,2));
    kmax = max(d1(:,3));
    kmin = min(d1(:,3));
    c(i,1) = imin;
    c(i,2) = imax;
    c(i,3) = jmin;
    c(i,4) = jmax;
    c(i,5) = kmin;
    c(i,6) = kmax;
end
imin = min(c(:,1));
imax = max(c(:,2));
jmin = min(c(:,3));
jmax = max(c(:,4));
I1(:,:,:) = int16(m.BW(imin:imax,jmin:jmax,:)).*m.I(imin:imax,jmin:jmax,:);
delete('tmp.mat')
toc
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MatrixToSingleTiffs(I,ScanName,f)



    
    sy = size(I,2);
    sx = size(I,1);
    sz = size(I,3);
  
   
    

    


    targetDir = fullfile(f,strcat('Tiff',ScanName));
     
    if ~exist(targetDir, 'dir')
        mkdir(targetDir)
    end
    k = 0;
    for i = 1:sz

        s = [ScanName,'%05d.tiff'];
        
        newFileName = sprintf(s,i+k);
       
        f = fullfile(targetDir,newFileName);

        t = Tiff(f,'w');

        setTag(t,'Photometric',Tiff.Photometric.MinIsBlack);
        setTag(t,'Compression',Tiff.Compression.None);
        setTag(t,'BitsPerSample',16);
        setTag(t,'SamplesPerPixel',1);
        setTag(t,'SampleFormat',Tiff.SampleFormat.Int);
        setTag(t,'ImageLength',sx);
        setTag(t,'ImageWidth',sy);
        setTag(t,'PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
        
        write(t,int16(I(:,:,i)));
       
     
        close(t);
    end
    
    close(t) 
end
end